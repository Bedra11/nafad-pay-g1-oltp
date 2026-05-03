-- ============================================================
-- FILE     : nafadpay_queries.sql
-- PROJECT  : NAFAD PAY — G1 OLTP Pipeline
-- MEMBER   : Member 4 — Queries & Performance & AWS
-- CREATED  : 2026-05-02
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
--   psql -h localhost -p 5432 -U admin -d nafadpay -f queries/nafadpay_queries.sql
--
-- NOTE:
--   Replace :user_id, :start_date, :end_date, :reference_value
--   with real values before running individual queries.
--   To get valid test IDs:
--     SELECT id, full_name FROM core.users LIMIT 10;
-- ============================================================


-- ============================================================
-- SECTION 1 — TRANSACTION HISTORY
-- ============================================================

-- ------------------------------------------------------------
-- Q1 : Full transaction history for a given user
-- ------------------------------------------------------------
SELECT
    t.id,
    t.reference,
    t.transaction_type,
    t.amount,
    t.fee,
    t.total_amount,
    t.currency,
    t.status,
    t.balance_before,
    t.balance_after,
    t.channel,
    t.device_type,
    t.transaction_date,
    t.transaction_time,
    t.created_at,
    t.completed_at,
    sa.account_number  AS source_account,
    da.account_number  AS destination_account
FROM core.transactions t
JOIN  core.accounts sa ON t.source_account_id      = sa.id
LEFT JOIN core.accounts da ON t.destination_account_id = da.id
WHERE sa.user_id = :user_id
ORDER BY t.created_at DESC;


-- ------------------------------------------------------------
-- Q2 : Transaction history filtered by date range
-- ------------------------------------------------------------
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
WHERE sa.user_id        = :user_id
  AND t.transaction_date BETWEEN :start_date AND :end_date
ORDER BY t.transaction_date DESC;


-- ------------------------------------------------------------
-- Q3 : Failed transactions for a given user
-- ------------------------------------------------------------
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
SELECT
    t.*,
    sa.account_number AS source_account,
    u.full_name       AS source_user,
    da.account_number AS destination_account
FROM core.transactions t
JOIN  core.accounts sa ON t.source_account_id      = sa.id
JOIN  core.users    u  ON sa.user_id               = u.id
LEFT JOIN core.accounts da ON t.destination_account_id = da.id
WHERE t.reference = :reference_value;


-- ============================================================
-- SECTION 2 — ACCOUNT SUMMARY
-- ============================================================

-- ------------------------------------------------------------
-- Q5 : Full account summary for a user
-- ------------------------------------------------------------
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
JOIN core.users       u ON a.user_id    = u.id
JOIN reference.wilayas w ON u.wilaya_id = w.id
WHERE a.user_id = :user_id;


-- ------------------------------------------------------------
-- Q6 : Top 20 accounts by balance (richest accounts)
-- ------------------------------------------------------------
SELECT
    a.account_number,
    a.account_type,
    a.balance,
    a.currency,
    u.full_name,
    w.name AS wilaya
FROM core.accounts a
JOIN core.users        u ON a.user_id    = u.id
JOIN reference.wilayas w ON u.wilaya_id  = w.id
WHERE a.status = 'ACTIVE'
ORDER BY a.balance DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q7 : Data integrity — accounts where available_balance > balance
--      (should return 0 rows in a clean dataset)
-- ------------------------------------------------------------
SELECT
    a.id,
    a.account_number,
    a.balance,
    a.available_balance,
    a.user_id
FROM core.accounts a
WHERE a.available_balance > a.balance;


-- ------------------------------------------------------------
-- Q8 : Monthly spending per account (SUCCESS only)
-- ------------------------------------------------------------
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
-- ------------------------------------------------------------
SELECT
    m.code,
    m.name,
    c.label  AS category,
    w.name   AS wilaya,
    COUNT(t.id)   AS tx_count,
    SUM(t.amount) AS total_volume,
    AVG(t.amount) AS avg_amount
FROM core.merchants     m
JOIN core.transactions  t  ON t.merchant_id      = m.id
JOIN reference.categories c ON m.category_code   = c.code
JOIN reference.wilayas   w  ON m.wilaya_id        = w.id
WHERE t.status = 'SUCCESS'
GROUP BY m.code, m.name, c.label, w.name
ORDER BY total_volume DESC
LIMIT 20;


-- ------------------------------------------------------------
-- Q10 : Merchant performance grouped by category
-- ------------------------------------------------------------
SELECT
    c.label              AS category,
    COUNT(DISTINCT m.id) AS merchant_count,
    COUNT(t.id)          AS tx_count,
    SUM(t.amount)        AS total_volume,
    AVG(t.amount)        AS avg_tx_amount
FROM core.merchants      m
JOIN core.transactions   t  ON t.merchant_id    = m.id
JOIN reference.categories c  ON m.category_code = c.code
WHERE t.status = 'SUCCESS'
GROUP BY c.label
ORDER BY total_volume DESC;


-- ------------------------------------------------------------
-- Q11 : Merchant activity per wilaya (geographic breakdown)
-- ------------------------------------------------------------
SELECT
    w.name               AS wilaya,
    COUNT(DISTINCT m.id) AS merchant_count,
    COUNT(t.id)          AS total_transactions,
    SUM(t.amount)        AS total_volume
FROM core.merchants      m
JOIN reference.wilayas   w  ON m.wilaya_id = w.id
LEFT JOIN core.transactions t ON t.merchant_id = m.id AND t.status = 'SUCCESS'
GROUP BY w.name
ORDER BY total_volume DESC NULLS LAST;


-- ------------------------------------------------------------
-- Q12 : Inactive merchants — zero transactions
-- ------------------------------------------------------------
SELECT
    m.id,
    m.code,
    m.name,
    m.status,
    w.name AS wilaya
FROM core.merchants    m
LEFT JOIN core.transactions t ON t.merchant_id = m.id
JOIN reference.wilayas  w ON m.wilaya_id = w.id
WHERE t.id IS NULL;


-- ============================================================
-- SECTION 4 — DAILY / WEEKLY REPORTING
-- ============================================================

-- ------------------------------------------------------------
-- Q13 : Daily transaction totals with status breakdown
-- ------------------------------------------------------------
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
SELECT
    t.transaction_date,
    tt.label     AS tx_type,
    COUNT(*)      AS tx_count,
    SUM(t.amount) AS volume
FROM core.transactions  t
JOIN reference.tx_types tt ON t.transaction_type = tt.code
WHERE t.status = 'SUCCESS'
GROUP BY t.transaction_date, tt.label
ORDER BY t.transaction_date DESC, volume DESC;


-- ------------------------------------------------------------
-- Q15 : Weekly summary
-- ------------------------------------------------------------
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
-- ------------------------------------------------------------
SELECT
    ag.code,
    ag.name,
    ag.tier,
    w.name        AS wilaya,
    COUNT(t.id)   AS tx_count,
    SUM(t.amount) AS total_volume,
    ag.float_balance
FROM core.agencies      ag
JOIN core.transactions  t  ON t.agency_id   = ag.id
JOIN reference.wilayas  w  ON ag.wilaya_id  = w.id
WHERE t.status = 'SUCCESS'
GROUP BY ag.code, ag.name, ag.tier, w.name, ag.float_balance
ORDER BY total_volume DESC;


-- ============================================================
-- SECTION 6 — DATA QUALITY & ANOMALY CHECKS
-- ============================================================

-- ------------------------------------------------------------
-- Q18 : Balance math inconsistencies in SUCCESS transactions
--        Expected: balance_after = balance_before - amount - fee
--        Tolerance: > 1 MRU to allow rounding differences
--        Target result: 0 rows (clean data)
-- ------------------------------------------------------------
SELECT
    t.id,
    t.reference,
    t.amount,
    t.fee,
    t.balance_before,
    t.balance_after,
    (t.balance_before - t.amount - t.fee) AS expected_balance_after,
    ABS(t.balance_after - (t.balance_before - t.amount - t.fee)) AS discrepancy
FROM core.transactions t
WHERE t.status = 'SUCCESS'
  AND ABS(t.balance_after - (t.balance_before - t.amount - t.fee)) > 1
ORDER BY discrepancy DESC;


-- ------------------------------------------------------------
-- Q19 : Duplicate idempotency_key detection
--        Target result: 0 rows (deduplication was done by Go pipeline)
-- ------------------------------------------------------------
SELECT
    idempotency_key,
    COUNT(*) AS occurrences
FROM core.transactions
GROUP BY idempotency_key
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- ------------------------------------------------------------
-- Q20 : FAILED transactions where balance changed
--        A failed transaction must NEVER modify balance
--        Target result: 0 rows
-- ------------------------------------------------------------
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
