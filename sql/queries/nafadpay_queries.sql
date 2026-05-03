-- ============================================================
-- FILE     : nafadpay_queries.sql
-- PROJECT  : NAFAD PAY — G1 OLTP Pipeline
-- MEMBER   : Member 4 — Queries & Performance & AWS
-- CREATED  : 2026-05-02
-- UPDATED  : 2026-05-03
--
-- CHANGES (2026-05-03):
--   - Q5, Q6 : fixed wilaya reference — core.users has no wilaya_name column;
--              added JOIN reference.wilayas and use w.name instead
--   - \set user_id : updated from 1 (non-existent in core) to 4719 (verified)
--   - \set ref_val : updated to a reference verified to exist in core.transactions
--   - Q9, Q10, Q17 : added explanatory comment — 0 rows is correct behavior
--
-- DESCRIPTION:
--   20 analytical SQL queries covering:
--     Section 1 : Transaction history      (Q1–Q4)
--     Section 2 : Account summary          (Q5–Q8)
--     Section 3 : Merchant analysis        (Q9–Q12)
--     Section 4 : Daily/weekly reporting   (Q13–Q16)
--     Section 5 : Agency analysis          (Q17)
--     Section 6 : Data quality checks      (Q18–Q20)
--
-- USAGE:
--   docker exec -i nafadpay-postgres psql -U admin -d nafadpay \
--     < sql/queries/nafadpay_queries.sql
--
-- NOTE:
--   Variables are set with \set below — change values as needed.
--   To get valid test IDs: SELECT id, full_name FROM core.users LIMIT 10;
-- ============================================================

-- ── demo parameters ───────────────────────────────────────────────────────────
-- FIX: user_id was 1, which does not exist in core.users.
--      Verified user_id=4719 has transactions in core.transactions.
\set user_id       4719
\set start_date    '2024-01-01'
\set end_date      '2024-12-31'
-- FIX: ref_val 'TX20241212196762' did not exist in core.transactions.
--      Replaced with a reference verified to exist.
\set ref_val       'TX20241224350064'


-- ============================================================
-- SECTION 1 — TRANSACTION HISTORY
-- ============================================================

-- ------------------------------------------------------------
-- Q1 : Full transaction history for a given user
-- ------------------------------------------------------------
\echo '=== Q1 : Full transaction history ==='
SELECT
    t.id,
    t.reference,
    t.transaction_type,
    t.amount,
    t.fee,
    t.currency,
    t.status,
    t.balance_before,
    t.balance_after,
    t.transaction_date,
    t.created_at,
    sa.account_number  AS source_account,
    da.account_number  AS destination_account
FROM core.transactions t
JOIN      core.accounts sa ON t.source_account_id      = sa.id
LEFT JOIN core.accounts da ON t.destination_account_id = da.id
WHERE sa.user_id = :user_id
ORDER BY t.created_at DESC;


-- ------------------------------------------------------------
-- Q2 : Transaction history filtered by date range
-- ------------------------------------------------------------
\echo '=== Q2 : Transactions by date range ==='
SELECT
    t.id,
    t.reference,
    t.transaction_type,
    t.amount,
    t.status,
    t.transaction_date,
    t.created_at
FROM core.transactions t
JOIN core.accounts sa ON t.source_account_id = sa.id
WHERE sa.user_id         = :user_id
  AND t.transaction_date BETWEEN :'start_date' AND :'end_date'
ORDER BY t.transaction_date DESC;


-- ------------------------------------------------------------
-- Q3 : Failed transactions for a given user
-- ------------------------------------------------------------
\echo '=== Q3 : Failed transactions ==='
SELECT
    t.id,
    t.reference,
    t.status,
    t.failure_reason,
    t.amount,
    t.transaction_date
FROM core.transactions t
JOIN core.accounts sa ON t.source_account_id = sa.id
WHERE sa.user_id = :user_id
  AND t.status   = 'FAILED'
ORDER BY t.created_at DESC;


-- ------------------------------------------------------------
-- Q4 : Search transaction by exact reference number
-- ------------------------------------------------------------
\echo '=== Q4 : Lookup by reference ==='
SELECT
    t.*,
    sa.account_number AS source_account,
    u.full_name       AS source_user,
    da.account_number AS destination_account
FROM core.transactions t
JOIN      core.accounts sa ON t.source_account_id      = sa.id
JOIN      core.users    u  ON sa.user_id               = u.id
LEFT JOIN core.accounts da ON t.destination_account_id = da.id
WHERE t.reference = :'ref_val';


-- ============================================================
-- SECTION 2 — ACCOUNT SUMMARY
-- ============================================================

-- ------------------------------------------------------------
-- Q5 : Full account summary for a user
--
-- FIX: original query referenced u.wilaya_name which does not exist
-- on core.users. core.users stores only wilaya_id (FK to reference.wilayas).
-- wilaya_name is a descriptive field kept only in staging and in
-- reference.wilayas — this is by design (strict core, no redundant fields).
-- Added JOIN reference.wilayas w and use w.name instead.
-- ------------------------------------------------------------
\echo '=== Q5 : Account summary for user ==='
SELECT
    a.id,
    a.account_number,
    a.account_type,
    a.balance,
    a.available_balance,
    a.currency,
    a.daily_limit,
    a.monthly_limit,
    a.status,
    a.is_primary,
    a.opened_date,
    a.last_activity,
    u.full_name,
    u.phone,
    w.name AS wilaya
FROM core.accounts a
JOIN core.users        u ON a.user_id    = u.id
LEFT JOIN reference.wilayas w ON w.id   = u.wilaya_id
WHERE a.user_id = :user_id;


-- ------------------------------------------------------------
-- Q6 : Top 20 accounts by balance (richest accounts)
--
-- FIX: same wilaya_name issue as Q5.
-- Added JOIN reference.wilayas w and use w.name instead.
-- ------------------------------------------------------------
\echo '=== Q6 : Top 20 accounts by balance ==='
SELECT
    a.account_number,
    a.account_type,
    a.balance,
    a.currency,
    u.full_name,
    w.name AS wilaya
FROM core.accounts a
JOIN core.users        u ON a.user_id  = u.id
LEFT JOIN reference.wilayas w ON w.id = u.wilaya_id
WHERE a.status = 'ACTIVE'
ORDER BY a.balance DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q7 : Data integrity — accounts where balance < 10% of available_balance
-- ------------------------------------------------------------
\echo '=== Q7 : Low-balance risk accounts ==='
SELECT
    id,
    account_number,
    balance,
    available_balance,
    user_id
FROM core.accounts
WHERE available_balance > 0
  AND balance < 0.10 * available_balance
ORDER BY balance / available_balance;


-- ------------------------------------------------------------
-- Q8 : Monthly spending per account (SUCCESS only)
-- ------------------------------------------------------------
\echo '=== Q8 : Monthly spend per account ==='
SELECT
    a.account_number,
    DATE_TRUNC('month', t.transaction_date) AS month,
    COUNT(*)                                AS tx_count,
    SUM(t.amount)                           AS total_spent,
    AVG(t.amount)                           AS avg_amount
FROM core.transactions t
JOIN core.accounts a ON t.source_account_id = a.id
WHERE t.status = 'SUCCESS'
GROUP BY a.account_number, DATE_TRUNC('month', t.transaction_date)
ORDER BY a.account_number, month DESC;


-- ============================================================
-- SECTION 3 — MERCHANT ANALYSIS
-- ============================================================

-- ------------------------------------------------------------
-- Q9 : Top 20 merchants by transaction volume
--
-- NOTE: Returns 0 rows on this dataset. All 66 core transactions
-- are type TRF (account-to-account transfer). PAY and merchant-linked
-- transactions were entirely routed to quarantine (missing merchant
-- references) or anomalies (idempotency conflicts) by the pipeline.
-- This is correct strict-core behavior, not a query bug.
-- Query is valid and will return data on a production dataset.
-- ------------------------------------------------------------
\echo '=== Q9 : Top merchants by volume ==='
SELECT
    m.code,
    m.name,
    c.label  AS category,
    w.name   AS wilaya,
    COUNT(t.id)   AS tx_count,
    SUM(t.amount) AS total_volume,
    AVG(t.amount) AS avg_amount
FROM core.merchants      m
JOIN core.transactions   t  ON t.merchant_id    = m.id
JOIN reference.categories c ON m.category_code  = c.code
JOIN reference.wilayas    w  ON m.wilaya_id      = w.id
WHERE t.status = 'SUCCESS'
GROUP BY m.code, m.name, c.label, w.name
ORDER BY total_volume DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q10 : Merchant performance grouped by category
--
-- NOTE: Returns 0 rows on this dataset — same reason as Q9.
-- All core transactions are TRF type with no merchant_id set.
-- Query is structurally correct and production-ready.
-- ------------------------------------------------------------
\echo '=== Q10 : Merchant performance by category ==='
SELECT
    c.label              AS category,
    COUNT(DISTINCT m.id) AS merchant_count,
    COUNT(t.id)          AS tx_count,
    SUM(t.amount)        AS total_volume,
    AVG(t.amount)        AS avg_tx_amount
FROM core.merchants       m
JOIN core.transactions    t  ON t.merchant_id   = m.id
JOIN reference.categories c  ON m.category_code = c.code
WHERE t.status = 'SUCCESS'
GROUP BY c.label
ORDER BY total_volume DESC;


-- ------------------------------------------------------------
-- Q11 : Merchant activity per wilaya (geographic breakdown)
-- ------------------------------------------------------------
\echo '=== Q11 : Merchant activity by wilaya ==='
SELECT
    w.name               AS wilaya,
    COUNT(DISTINCT m.id) AS merchant_count,
    COUNT(t.id)          AS total_transactions,
    SUM(t.amount)        AS total_volume
FROM core.merchants    m
JOIN reference.wilayas w  ON m.wilaya_id   = w.id
LEFT JOIN core.transactions t ON t.merchant_id = m.id AND t.status = 'SUCCESS'
GROUP BY w.name
ORDER BY total_volume DESC NULLS LAST;


-- ------------------------------------------------------------
-- Q12 : Inactive merchants — zero transactions
-- ------------------------------------------------------------
\echo '=== Q12 : Inactive merchants ==='
SELECT
    m.id,
    m.code,
    m.name,
    m.status,
    w.name AS wilaya
FROM core.merchants    m
LEFT JOIN core.transactions t ON t.merchant_id = m.id
JOIN reference.wilayas      w ON m.wilaya_id   = w.id
WHERE t.id IS NULL;


-- ============================================================
-- SECTION 4 — DAILY / WEEKLY REPORTING
-- ============================================================

-- ------------------------------------------------------------
-- Q13 : Daily transaction totals with status breakdown
-- ------------------------------------------------------------
\echo '=== Q13 : Daily totals with status breakdown ==='
SELECT
    t.transaction_date,
    COUNT(*)                                              AS total_tx,
    COUNT(*) FILTER (WHERE t.status = 'SUCCESS')         AS success_count,
    COUNT(*) FILTER (WHERE t.status = 'FAILED')          AS failed_count,
    COUNT(*) FILTER (WHERE t.status = 'PENDING')         AS pending_count,
    SUM(t.amount) FILTER (WHERE t.status = 'SUCCESS')    AS total_volume,
    AVG(t.amount) FILTER (WHERE t.status = 'SUCCESS')    AS avg_amount
FROM core.transactions t
GROUP BY t.transaction_date
ORDER BY t.transaction_date DESC;


-- ------------------------------------------------------------
-- Q14 : Daily totals per transaction type
-- ------------------------------------------------------------
\echo '=== Q14 : Daily totals by transaction type ==='
SELECT
    t.transaction_date,
    t.transaction_type AS tx_type,
    COUNT(*)           AS tx_count,
    SUM(t.amount)      AS volume
FROM core.transactions t
WHERE t.status = 'SUCCESS'
GROUP BY t.transaction_date, t.transaction_type
ORDER BY t.transaction_date DESC, volume DESC;


-- ------------------------------------------------------------
-- Q15 : Weekly summary
-- ------------------------------------------------------------
\echo '=== Q15 : Weekly summary ==='
SELECT
    DATE_TRUNC('week', t.transaction_date) AS week_start,
    COUNT(*)                               AS total_tx,
    SUM(t.amount)                          AS total_volume,
    COUNT(DISTINCT t.source_account_id)    AS active_accounts
FROM core.transactions t
WHERE t.status = 'SUCCESS'
GROUP BY DATE_TRUNC('week', t.transaction_date)
ORDER BY week_start DESC;


-- ------------------------------------------------------------
-- Q16 : Hourly distribution — peak hours analysis
-- ------------------------------------------------------------
\echo '=== Q16 : Hourly distribution ==='
SELECT
    EXTRACT(HOUR FROM t.transaction_time) AS hour_of_day,
    COUNT(*)                              AS tx_count,
    SUM(t.amount)                         AS volume
FROM core.transactions t
WHERE t.status = 'SUCCESS'
GROUP BY EXTRACT(HOUR FROM t.transaction_time)
ORDER BY hour_of_day;


-- ============================================================
-- SECTION 5 — AGENCY ANALYSIS
-- ============================================================

-- ------------------------------------------------------------
-- Q17 : Agency transaction volume vs float balance
--
-- NOTE: Returns 0 rows on this dataset. All 66 core transactions
-- are type TRF with agency_id = NULL. Agency-linked transactions
-- were routed to quarantine or anomalies by the pipeline.
-- Query is structurally correct and production-ready.
-- ------------------------------------------------------------
\echo '=== Q17 : Agency performance ==='
SELECT
    ag.code,
    ag.name,
    ag.tier,
    w.name        AS wilaya,
    COUNT(t.id)   AS tx_count,
    SUM(t.amount) AS total_volume,
    ag.float_balance
FROM core.agencies     ag
JOIN core.transactions t  ON t.agency_id   = ag.id
JOIN reference.wilayas w  ON ag.wilaya_id  = w.id
WHERE t.status = 'SUCCESS'
GROUP BY ag.code, ag.name, ag.tier, w.name, ag.float_balance
ORDER BY total_volume DESC;


-- ============================================================
-- SECTION 6 — DATA QUALITY & ANOMALY CHECKS
-- ============================================================

-- ------------------------------------------------------------
-- Q18 : Balance math inconsistencies in SUCCESS transactions
--       Target: 0 rows
-- ------------------------------------------------------------
\echo '=== Q18 : Balance math check (must be 0 rows) ==='
SELECT
    t.id,
    t.reference,
    t.amount,
    t.fee,
    t.balance_before,
    t.balance_after,
    (t.balance_before - t.amount - t.fee)                          AS expected_balance_after,
    ABS(t.balance_after - (t.balance_before - t.amount - t.fee))  AS discrepancy
FROM core.transactions t
WHERE t.status = 'SUCCESS'
  AND ABS(t.balance_after - (t.balance_before - t.amount - t.fee)) > 1
ORDER BY discrepancy DESC;


-- ------------------------------------------------------------
-- Q19 : Duplicate idempotency_key detection
--       Target: 0 rows
-- ------------------------------------------------------------
\echo '=== Q19 : Duplicate idempotency keys (must be 0 rows) ==='
SELECT
    idempotency_key,
    COUNT(*) AS occurrences
FROM core.transactions
GROUP BY idempotency_key
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ------------------------------------------------------------
-- Q20 : FAILED transactions where balance changed
--       Target: 0 rows
-- ------------------------------------------------------------
\echo '=== Q20 : FAILED tx with balance change (must be 0 rows) ==='
SELECT
    t.id,
    t.reference,
    t.status,
    t.balance_before,
    t.balance_after,
    (t.balance_after - t.balance_before) AS balance_delta
FROM core.transactions t
WHERE t.status = 'FAILED'
  AND t.balance_after <> t.balance_before
ORDER BY ABS(t.balance_after - t.balance_before) DESC;


-- ============================================================
-- END OF FILE
-- ============================================================