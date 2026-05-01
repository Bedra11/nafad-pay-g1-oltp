-- ============================================================
-- 00_staging_smoke_test.sql
-- Basic verification for staging bootstrap
-- ============================================================

-- 1. Row counts
SELECT 'staging.users' AS table_name, COUNT(*) AS actual_rows, 1000 AS expected_rows
FROM staging.users
UNION ALL
SELECT 'staging.accounts', COUNT(*), 1099
FROM staging.accounts
UNION ALL
SELECT 'staging.merchants', COUNT(*), 100
FROM staging.merchants
UNION ALL
SELECT 'staging.agencies', COUNT(*), 50
FROM staging.agencies
UNION ALL
SELECT 'staging.transactions', COUNT(*), 10000
FROM staging.transactions
UNION ALL
SELECT 'staging.reference_wilayas', COUNT(*), 15
FROM staging.reference_wilayas
UNION ALL
SELECT 'staging.reference_tx_types', COUNT(*), 8
FROM staging.reference_tx_types
UNION ALL
SELECT 'staging.reference_categories', COUNT(*), 13
FROM staging.reference_categories
ORDER BY table_name;

-- 2. quick null sanity checks on row presence
SELECT
    (SELECT COUNT(*) FROM staging.users) > 0 AS users_loaded,
    (SELECT COUNT(*) FROM staging.accounts) > 0 AS accounts_loaded,
    (SELECT COUNT(*) FROM staging.merchants) > 0 AS merchants_loaded,
    (SELECT COUNT(*) FROM staging.agencies) > 0 AS agencies_loaded,
    (SELECT COUNT(*) FROM staging.transactions) > 0 AS transactions_loaded;

-- 3. check that staging preserves duplicates / anomalies

SELECT 'duplicate_phone_users' AS check_name, COUNT(*) AS rows_involved
FROM (
    SELECT phone
    FROM staging.users
    WHERE phone IS NOT NULL AND phone <> ''
    GROUP BY phone
    HAVING COUNT(*) > 1
) d;

SELECT 'duplicate_idempotency_keys' AS check_name, COUNT(*) AS duplicate_keys
FROM (
    SELECT idempotency_key
    FROM staging.transactions
    WHERE idempotency_key IS NOT NULL AND idempotency_key <> ''
    GROUP BY idempotency_key
    HAVING COUNT(*) > 1
) d;