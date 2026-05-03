-- ============================================================
-- FIX 3 (v2) : nafadpay_queries.sql
-- Fixes applied vs v1:
--   a) \set variables work when piped via <
--   b) Q6: removed join on core.wilayas (does not exist);
--      wilaya_name is a column directly on core.users
-- Run : docker exec -i nafadpay-postgres psql -U admin -d nafadpay < fix_03_queries.sql
-- ============================================================

\set user_id 1
\set ref_val 'TX20241212196762'

-- ── Q1 : Transaction history for a user ──────────────────────────────────────
\echo '=== Q1 : Transaction history for user_id = 1 ==='
SELECT
    t.reference,
    t.transaction_type,
    t.amount,
    t.fee,
    t.status,
    t.transaction_date,
    t.created_at
FROM core.transactions t
JOIN core.accounts sa ON sa.id = t.source_account_id
WHERE sa.user_id = :user_id
ORDER BY t.created_at DESC
LIMIT 20;

-- ── Q2 : Account summary for a user ──────────────────────────────────────────
\echo '=== Q2 : Account summary for user_id = 1 ==='
SELECT
    a.account_number,
    a.account_type,
    a.balance,
    a.currency,
    a.status,
    a.available_balance
FROM core.accounts a
WHERE a.user_id = :user_id
ORDER BY a.account_type;

-- ── Q3 : Lookup transaction by reference ─────────────────────────────────────
\echo '=== Q3 : Lookup by reference ==='
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    t.transaction_type,
    t.amount,
    t.fee,
    t.status,
    t.balance_before,
    t.balance_after,
    t.transaction_date
FROM core.transactions t
WHERE t.reference = :'ref_val';

-- ── Q4 : Yearly transactions for a user (2024) ───────────────────────────────
\echo '=== Q4 : 2024 transactions for user_id = 1 ==='
SELECT
    t.reference,
    t.transaction_type,
    t.amount,
    t.status,
    t.transaction_date
FROM core.transactions t
JOIN core.accounts sa ON sa.id = t.source_account_id
WHERE sa.user_id = :user_id
  AND t.transaction_date >= '2024-01-01'
  AND t.transaction_date <= '2024-12-31'
ORDER BY t.transaction_date DESC;

-- ── Q5 : Monthly spend per account for a user ────────────────────────────────
\echo '=== Q5 : Monthly spend per account for user_id = 1 ==='
SELECT
    a.account_number,
    DATE_TRUNC('month', t.transaction_date) AS month,
    COUNT(*)                                 AS tx_count,
    SUM(t.amount)                            AS total_spent,
    AVG(t.amount)                            AS avg_amount
FROM core.transactions t
JOIN core.accounts a ON a.id = t.source_account_id
WHERE a.user_id = :user_id
  AND t.status  = 'SUCCESS'
GROUP BY a.account_number, DATE_TRUNC('month', t.transaction_date)
ORDER BY month DESC;

-- ── Q6 : Top 20 accounts by balance ──────────────────────────────────────────
-- core.wilayas does NOT exist — wilaya_name is a column on core.users
\echo '=== Q6 : Top 20 accounts by balance ==='
SELECT
    a.account_number,
    a.account_type,
    a.balance,
    a.currency,
    u.first_name || ' ' || u.last_name AS full_name,
    u.wilaya_name                       AS wilaya
FROM core.accounts a
JOIN core.users u ON u.id = a.user_id
ORDER BY a.balance DESC
LIMIT 20;

-- ── Q7 : Low-balance accounts (balance < 10 % of available_balance) ──────────
\echo '=== Q7 : Low-balance accounts (balance < 10% of available_balance) ==='
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