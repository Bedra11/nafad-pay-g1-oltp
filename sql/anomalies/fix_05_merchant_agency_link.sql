-- ============================================================
-- FIX 5 (v2) : Re-admit PAY/BIL/DEP/WIT transactions
-- Fixes vs v1:
--   a) staging.merchant_id is TEXT → cast to ::bigint for join
--   b) staging.amount is TEXT      → cast to ::numeric for > 0 check
--   c) core.wilayas does NOT exist → use u.wilaya_name from core.users
--      and m.wilaya_name from core.merchants directly
-- Run : docker exec -i nafadpay-postgres psql -U admin -d nafadpay < fix_05_merchant_agency_link.sql
-- ============================================================

-- ── DIAGNOSIS ────────────────────────────────────────────────────────────────

\echo '=== Diag 1 : How many core transactions have a merchant_id? ==='
SELECT
    COUNT(*)                  AS total_tx,
    COUNT(merchant_id)        AS with_merchant,
    COUNT(*) - COUNT(merchant_id) AS without_merchant,
    COUNT(agency_id)          AS with_agency
FROM core.transactions;

\echo '=== Diag 2 : Transaction types present in core ==='
SELECT transaction_type, COUNT(*) AS cnt
FROM core.transactions
GROUP BY transaction_type ORDER BY cnt DESC;

\echo '=== Diag 3 : Transaction types quarantined in staging ==='
SELECT transaction_type, COUNT(*) AS cnt
FROM staging.transactions
WHERE idempotency_key NOT IN (SELECT idempotency_key FROM core.transactions)
GROUP BY transaction_type ORDER BY cnt DESC;

\echo '=== Diag 4 : Sample merchant_ids in staging (TEXT column) ==='
SELECT DISTINCT merchant_id
FROM staging.transactions
WHERE merchant_id IS NOT NULL AND merchant_id <> ''
LIMIT 10;

\echo '=== Diag 5 : Are those merchant_ids matchable in core.merchants? ==='
-- merchant_id in staging is TEXT, core.merchants.id is bigint → explicit cast
SELECT
    s.merchant_id,
    m.id   AS found_in_core,
    m.name AS merchant_name
FROM (
    SELECT DISTINCT merchant_id
    FROM staging.transactions
    WHERE merchant_id IS NOT NULL AND merchant_id <> ''
    LIMIT 20
) s
LEFT JOIN core.merchants m ON m.id = s.merchant_id::bigint;

-- ── FIX : Re-admit non-TRF transactions with valid references ────────────────

\echo '=== Fix : Re-admitting PAY / BIL / DEP / WIT / AIR / SAL / REV ==='

INSERT INTO core.transactions (
    reference,
    idempotency_key,
    transaction_type,
    source_account_id,
    destination_account_id,
    merchant_id,
    agency_id,
    amount,
    fee,
    currency,
    status,
    balance_before,
    balance_after,
    node_id,
    processing_node,
    sequence_number,
    transaction_date,
    created_at,
    completed_at
)
SELECT
    s.reference,
    s.idempotency_key,
    s.transaction_type,
    sa.id                                          AS source_account_id,
    da.id                                          AS destination_account_id,
    NULLIF(s.merchant_id, '')::bigint              AS merchant_id,
    NULLIF(s.agency_id,   '')::bigint              AS agency_id,
    ABS(s.amount::numeric)                         AS amount,
    s.fee::numeric                                 AS fee,
    s.currency,
    s.status,
    s.balance_before::numeric                      AS balance_before,
    s.balance_after::numeric                       AS balance_after,
    s.node_id,
    s.processing_node,
    NULLIF(s.sequence_number, '')::integer         AS sequence_number,
    s.transaction_date::date,
    s.created_at::timestamptz,
    NULLIF(s.completed_at, '')::timestamptz
FROM staging.transactions s

-- Source account must exist in core
JOIN core.accounts sa ON sa.account_number = s.source_account_number

-- Destination account: optional (NULL for PAY/BIL)
LEFT JOIN core.accounts da
       ON da.account_number = s.destination_account_number
      AND s.destination_account_number IS NOT NULL
      AND s.destination_account_number <> ''

-- Merchant must exist in core when referenced
LEFT JOIN core.merchants m
       ON m.id = NULLIF(s.merchant_id, '')::bigint

-- Agency must exist in core when referenced
LEFT JOIN core.agencies ag
       ON ag.id = NULLIF(s.agency_id, '')::bigint

WHERE
    -- Exclude TRF (already in core)
    s.transaction_type <> 'TRF'

    -- Not already loaded
    AND s.idempotency_key NOT IN (SELECT idempotency_key FROM core.transactions)

    -- No idempotency duplicate within staging itself
    AND s.idempotency_key IN (
        SELECT idempotency_key
        FROM staging.transactions
        GROUP BY idempotency_key
        HAVING COUNT(*) = 1
    )

    -- No balance anomaly (FAILED must not change balance)
    AND NOT (
        s.status = 'FAILED'
        AND s.balance_before::numeric <> s.balance_after::numeric
    )

    -- Valid amounts (amount is TEXT, can be negative in CSV — use ABS)
    AND s.amount <> ''
    AND ABS(s.amount::numeric) > 0
    AND s.fee::numeric >= 0

    -- When merchant_id is filled, it must exist in core
    AND (
        s.merchant_id = ''
        OR m.id IS NOT NULL
    )

    -- When agency_id is filled, it must exist in core
    AND (
        s.agency_id = ''
        OR ag.id IS NOT NULL
    )

ON CONFLICT (idempotency_key) DO NOTHING;

-- ── VERIFICATION ─────────────────────────────────────────────────────────────

\echo '=== After fix : transaction type breakdown in core ==='
SELECT transaction_type, COUNT(*) AS cnt, SUM(amount) AS volume
FROM core.transactions
GROUP BY transaction_type
ORDER BY cnt DESC;

\echo '=== After fix : top merchants by volume ==='
SELECT
    m.name,
    m.category_code,
    COUNT(t.id)   AS tx_count,
    SUM(t.amount) AS total_volume
FROM core.merchants m
JOIN core.transactions t ON t.merchant_id = m.id AND t.status = 'SUCCESS'
GROUP BY m.id, m.name, m.category_code
ORDER BY total_volume DESC
LIMIT 10;

\echo '=== After fix : merchant performance by category ==='
SELECT
    m.category_code         AS category,
    COUNT(DISTINCT m.id)    AS merchant_count,
    COUNT(t.id)             AS tx_count,
    COALESCE(SUM(t.amount), 0) AS total_volume,
    ROUND(AVG(t.amount), 2)    AS avg_tx_amount
FROM core.merchants m
LEFT JOIN core.transactions t ON t.merchant_id = m.id AND t.status = 'SUCCESS'
GROUP BY m.category_code
ORDER BY total_volume DESC;

-- No core.wilayas — use wilaya_name stored on core.merchants directly
\echo '=== After fix : merchant activity by wilaya ==='
SELECT
    m.wilaya_name           AS wilaya,
    COUNT(DISTINCT m.id)    AS merchant_count,
    COUNT(t.id)             AS total_transactions,
    COALESCE(SUM(t.amount), 0) AS total_volume
FROM core.merchants m
LEFT JOIN core.transactions t ON t.merchant_id = m.id AND t.status = 'SUCCESS'
GROUP BY m.wilaya_name
ORDER BY total_volume DESC;

\echo '=== After fix : agency activity by wilaya ==='
SELECT
    ag.wilaya_name          AS wilaya,
    COUNT(DISTINCT ag.id)   AS agency_count,
    COUNT(t.id)             AS total_transactions,
    COALESCE(SUM(t.amount), 0) AS total_volume
FROM core.agencies ag
LEFT JOIN core.transactions t ON t.agency_id = ag.id AND t.status = 'SUCCESS'
GROUP BY ag.wilaya_name
ORDER BY total_volume DESC;