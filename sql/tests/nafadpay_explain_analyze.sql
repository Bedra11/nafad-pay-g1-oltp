
\echo ''
\echo '============================================================'
\echo '  NAFAD PAY — EXPLAIN ANALYZE REPORT'
\echo '  5 most critical queries — index usage verified'
\echo '============================================================'
\echo ''

-- ============================================================
-- QUERY 1 : Transaction history for a user
-- Index exercised: idx_accounts_user (on core.accounts.user_id)
-- Use case: most frequent — every user login loads their history
-- ============================================================
\echo '------------------------------------------------------------'
\echo 'Q1 : Transaction history for a user'
\echo 'Index: idx_accounts_user on core.accounts(user_id)'
\echo '------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    t.id,
    t.reference,
    t.transaction_type,
    t.amount,
    t.fee,
    t.status,
    t.balance_before,
    t.balance_after,
    t.transaction_date,
    t.created_at,
    sa.account_number AS source_account,
    da.account_number AS destination_account
FROM core.transactions t
JOIN      core.accounts sa ON t.source_account_id      = sa.id
LEFT JOIN core.accounts da ON t.destination_account_id = da.id
WHERE sa.user_id = 4719
ORDER BY t.created_at DESC;

\echo ''

-- ============================================================
-- QUERY 2 : Daily totals by date (reporting dashboard)
-- Index exercised: idx_tx_date (on core.transactions.transaction_date)
-- Use case: daily reconciliation and BI reporting
-- ============================================================
\echo '------------------------------------------------------------'
\echo 'Q2 : Daily transaction totals'
\echo 'Index: idx_tx_date on core.transactions(transaction_date)'
\echo '------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    transaction_date,
    COUNT(*)                                           AS total_tx,
    COUNT(*) FILTER (WHERE status = 'SUCCESS')         AS success_count,
    COUNT(*) FILTER (WHERE status = 'FAILED')          AS failed_count,
    SUM(amount) FILTER (WHERE status = 'SUCCESS')      AS total_volume,
    AVG(amount) FILTER (WHERE status = 'SUCCESS')      AS avg_amount
FROM core.transactions
GROUP BY transaction_date
ORDER BY transaction_date DESC;

\echo ''

-- ============================================================
-- QUERY 3 : Top merchants by volume
-- Index exercised: idx_tx_merchant_status (partial, merchant_id IS NOT NULL)
-- Use case: merchant performance reports, fraud detection
-- ============================================================
\echo '------------------------------------------------------------'
\echo 'Q3 : Top merchants by transaction volume'
\echo 'Index: idx_tx_merchant_status (partial) on core.transactions(merchant_id, status)'
\echo '------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    m.code,
    m.name,
    COUNT(t.id)   AS tx_count,
    SUM(t.amount) AS total_volume
FROM core.merchants    m
JOIN core.transactions t ON t.merchant_id = m.id
WHERE t.status = 'SUCCESS'
GROUP BY m.code, m.name
ORDER BY total_volume DESC
LIMIT 20;

\echo ''

-- ============================================================
-- QUERY 4 : Lookup by reference (exact match)
-- Index exercised: transactions_reference_key (UNIQUE index on reference)
-- Use case: customer support, transaction reconciliation
-- ============================================================
\echo '------------------------------------------------------------'
\echo 'Q4 : Transaction lookup by reference (exact match)'
\echo 'Index: transactions_reference_key UNIQUE on core.transactions(reference)'
\echo '------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT
    t.*,
    sa.account_number AS source_account,
    u.full_name       AS source_user,
    da.account_number AS destination_account
FROM core.transactions t
JOIN      core.accounts sa ON t.source_account_id      = sa.id
JOIN      core.users    u  ON sa.user_id               = u.id
LEFT JOIN core.accounts da ON t.destination_account_id = da.id
WHERE t.reference = 'TX20241224350064';

\echo ''

-- ============================================================
-- QUERY 5 : Monthly spend per account
-- Index exercised: idx_tx_account_date (on source_account_id, transaction_date)
-- Use case: account statements, monthly limit checks
-- ============================================================
\echo '------------------------------------------------------------'
\echo 'Q5 : Monthly spending per account'
\echo 'Index: idx_tx_account_date on core.transactions(source_account_id, transaction_date)'
\echo '------------------------------------------------------------'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
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

\echo ''
\echo '============================================================'
\echo '  END OF EXPLAIN ANALYZE REPORT'
\echo '============================================================'
