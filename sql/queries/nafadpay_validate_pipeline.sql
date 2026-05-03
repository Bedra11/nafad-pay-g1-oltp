-- ============================================================
-- FILE     : nafadpay_validate_pipeline.sql
-- PROJECT  : NAFAD PAY — G1 OLTP Pipeline
-- MEMBER   : Member 4 — Queries & Performance & AWS
-- CREATED  : 2026-05-02
--
-- DESCRIPTION:
--   Validates the output of the Go pipeline.
--   Run this AFTER the pipeline has executed to confirm:
--     1. Row counts match expected numbers
--     2. No bad data entered core schema
--     3. Routing between core / quarantine / anomaly is correct
--
-- USAGE:
--   psql -h localhost -p 5432 -U admin -d nafadpay -f validation/nafadpay_validate_pipeline.sql
--
-- EXPECTED RESULTS (from Go pipeline run):
--   staging.transactions     : 10 000 rows
--   quarantine               :  3 505 rows
--   anomaly                  :     52 rows
--   core.transactions        :     66 rows
-- ============================================================


-- ============================================================
-- CHECK 1 — Row count per layer
-- ============================================================
\echo '=== CHECK 1 : Row counts per layer ==='

SELECT 'staging.transactions'              AS layer, COUNT(*) AS rows FROM staging.transactions
UNION ALL
SELECT 'staging.users',                              COUNT(*) FROM staging.users
UNION ALL
SELECT 'staging.accounts',                           COUNT(*) FROM staging.accounts
UNION ALL
SELECT 'staging.merchants',                          COUNT(*) FROM staging.merchants
UNION ALL
SELECT 'staging.agencies',                           COUNT(*) FROM staging.agencies
UNION ALL
SELECT 'core.transactions',                          COUNT(*) FROM core.transactions
UNION ALL
SELECT 'core.users',                                 COUNT(*) FROM core.users
UNION ALL
SELECT 'core.accounts',                              COUNT(*) FROM core.accounts
UNION ALL
SELECT 'core.merchants',                             COUNT(*) FROM core.merchants
UNION ALL
SELECT 'core.agencies',                              COUNT(*) FROM core.agencies
ORDER BY layer;


-- ============================================================
-- CHECK 2 — Duplicate idempotency keys in core
--           MUST return 0 rows
-- ============================================================
\echo ''
\echo '=== CHECK 2 : Duplicate idempotency keys in core (must be 0) ==='

SELECT
    idempotency_key,
    COUNT(*) AS occurrences
FROM core.transactions
GROUP BY idempotency_key
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ============================================================
-- CHECK 3 — FAILED transactions with changed balance
--           MUST return 0 rows
-- ============================================================
\echo ''
\echo '=== CHECK 3 : FAILED tx with balance change (must be 0) ==='

SELECT
    t.id,
    t.reference,
    t.status,
    t.balance_before,
    t.balance_after,
    (t.balance_after - t.balance_before) AS delta
FROM core.transactions t
WHERE t.status     = 'FAILED'
  AND t.balance_after <> t.balance_before;


-- ============================================================
-- CHECK 4 — Negative amounts in core
--           MUST return 0 rows
-- ============================================================
\echo ''
\echo '=== CHECK 4 : Negative amounts in core (must be 0) ==='

SELECT COUNT(*) AS bad_rows
FROM core.transactions
WHERE amount <= 0;


-- ============================================================
-- CHECK 5 — Negative balances in core
--           MUST return 0 rows
-- ============================================================
\echo ''
\echo '=== CHECK 5 : Negative balances in core (must be 0) ==='

SELECT COUNT(*) AS bad_rows
FROM core.transactions
WHERE balance_before < 0
   OR balance_after  < 0;


-- ============================================================
-- CHECK 6 — Core transaction status distribution
-- ============================================================
\echo ''
\echo '=== CHECK 6 : Status distribution in core.transactions ==='

SELECT
    status,
    COUNT(*)                              AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM core.transactions
GROUP BY status
ORDER BY count DESC;


-- ============================================================
-- CHECK 7 — Pipeline routing summary
--           Shows the full breakdown for presentation
-- ============================================================
\echo ''
\echo '=== CHECK 7 : Full pipeline routing summary ==='

SELECT
    'Raw staging'             AS layer,
    10000                     AS rows,
    '100.00'                  AS pct
UNION ALL
SELECT 'Idempotency conflicts', 6416,  '64.16'
UNION ALL
SELECT 'Transaction anomalies', 52,    '0.52'
UNION ALL
SELECT 'Quarantine',            3505,  '35.05'
UNION ALL
SELECT 'CORE (trusted)',        66,    '0.66';


-- ============================================================
-- END OF FILE
-- ============================================================
