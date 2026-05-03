-- ============================================================
-- FILE     : nafadpay_indexes.sql
-- PROJECT  : NAFAD PAY — G1 OLTP Pipeline
-- MEMBER   : Member 4 — Queries & Performance & AWS
-- CREATED  : 2026-05-02
--
-- DESCRIPTION:
--   Performance indexes for core schema tables.
--   Each index is justified by a specific query pattern.
--   All use IF NOT EXISTS — safe to run multiple times.
--
-- USAGE:
--   psql -h localhost -p 5432 -U admin -d nafadpay -f indexes/nafadpay_indexes.sql
--
-- RUN AFTER:
--   Go pipeline has populated core.* tables.
-- ============================================================


-- ============================================================
-- CORE.TRANSACTIONS — highest query load table
-- ============================================================

-- Filter by source account (used by Q1, Q2, Q3, Q8)
CREATE INDEX IF NOT EXISTS idx_tx_source_account
    ON core.transactions(source_account_id);

-- Filter by destination account
CREATE INDEX IF NOT EXISTS idx_tx_destination_account
    ON core.transactions(destination_account_id);

-- Filter by merchant (used by Q9, Q10, Q12)
CREATE INDEX IF NOT EXISTS idx_tx_merchant
    ON core.transactions(merchant_id);

-- Filter by agency (used by Q17)
CREATE INDEX IF NOT EXISTS idx_tx_agency
    ON core.transactions(agency_id);

-- Filter by date (used by Q2, Q13, Q14, Q15, Q16)
CREATE INDEX IF NOT EXISTS idx_tx_date
    ON core.transactions(transaction_date);

-- Filter by status (used by Q3 and most reporting queries)
CREATE INDEX IF NOT EXISTS idx_tx_status
    ON core.transactions(status);

-- Composite: account + date — most frequent access pattern (Q2)
CREATE INDEX IF NOT EXISTS idx_tx_account_date
    ON core.transactions(source_account_id, transaction_date);

-- Composite: status + date — daily reporting (Q13)
CREATE INDEX IF NOT EXISTS idx_tx_status_date
    ON core.transactions(status, transaction_date);

-- Composite: merchant + status — merchant volume queries (Q9)
CREATE INDEX IF NOT EXISTS idx_tx_merchant_status
    ON core.transactions(merchant_id, status);


-- ============================================================
-- CORE.ACCOUNTS
-- ============================================================

-- Filter accounts by user (used by Q5, Q6, Q8)
CREATE INDEX IF NOT EXISTS idx_accounts_user
    ON core.accounts(user_id);

-- Filter by account status (used by Q6)
CREATE INDEX IF NOT EXISTS idx_accounts_status
    ON core.accounts(status);


-- ============================================================
-- CORE.USERS
-- ============================================================

-- Filter by wilaya (used by Q5, Q6, Q11)
CREATE INDEX IF NOT EXISTS idx_users_wilaya
    ON core.users(wilaya_id);

-- Note: nni already has a UNIQUE constraint (implicit index)


-- ============================================================
-- CORE.MERCHANTS
-- ============================================================

-- Filter by wilaya (used by Q11)
CREATE INDEX IF NOT EXISTS idx_merchants_wilaya
    ON core.merchants(wilaya_id);

-- Filter by category (used by Q10)
CREATE INDEX IF NOT EXISTS idx_merchants_category
    ON core.merchants(category_code);


-- ============================================================
-- CORE.AGENCIES
-- ============================================================

-- Filter by wilaya
CREATE INDEX IF NOT EXISTS idx_agencies_wilaya
    ON core.agencies(wilaya_id);


-- ============================================================
-- VERIFY — list all indexes created on core schema
-- ============================================================
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;


-- ============================================================
-- EXPLAIN ANALYZE — run these to prove index usage
-- Copy results as screenshots for presentation
-- ============================================================

-- Q1 check — expects: Index Scan on idx_accounts_user + idx_tx_source_account
EXPLAIN ANALYZE
SELECT t.id, t.reference, t.amount, t.status
FROM core.transactions t
JOIN core.accounts sa ON t.source_account_id = sa.id
WHERE sa.user_id = 1
ORDER BY t.created_at DESC;

-- Q13 check — expects: Index Scan on idx_tx_date
EXPLAIN ANALYZE
SELECT
    transaction_date,
    COUNT(*),
    SUM(amount)
FROM core.transactions
WHERE status = 'SUCCESS'
GROUP BY transaction_date
ORDER BY transaction_date DESC;

-- Q9 check — expects: Index Scan on idx_tx_merchant_status
EXPLAIN ANALYZE
SELECT
    m.name,
    COUNT(t.id),
    SUM(t.amount)
FROM core.merchants m
JOIN core.transactions t ON t.merchant_id = m.id
WHERE t.status = 'SUCCESS'
GROUP BY m.name
ORDER BY SUM(t.amount) DESC
LIMIT 20;

-- Q2 — compte + date range
EXPLAIN ANALYZE
SELECT t.id, t.amount FROM core.transactions t
JOIN core.accounts sa ON t.source_account_id = sa.id
WHERE sa.user_id = 1
  AND t.transaction_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Q8 — dépenses mensuelles
EXPLAIN ANALYZE
SELECT a.account_number, DATE_TRUNC('month', t.transaction_date), SUM(t.amount)
FROM core.transactions t
JOIN core.accounts a ON t.source_account_id = a.id
WHERE t.status = 'SUCCESS'
GROUP BY a.account_number, DATE_TRUNC('month', t.transaction_date);

-- ============================================================
-- TABLE + INDEX SIZE MONITORING
-- Run this to show storage impact in presentation
-- ============================================================
SELECT
    relname                                              AS table_name,
    pg_size_pretty(pg_total_relation_size(relid))        AS total_size,
    pg_size_pretty(pg_relation_size(relid))              AS table_size,
    pg_size_pretty(pg_indexes_size(relid))               AS index_size
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname = 'core'
ORDER BY pg_total_relation_size(relid) DESC;


-- ============================================================
-- END OF FILE
-- ============================================================
