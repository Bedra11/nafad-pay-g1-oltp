\echo ''
\echo '============================================================'
\echo '  CONCURRENT INSERTION BENCH — RESULTS'
\echo '============================================================'
\echo ''

-- Total rows inserted
\echo '--- Total rows inserted ---'
SELECT COUNT(*) AS total_rows_inserted FROM bench.transactions;

-- Rows per worker (should be ~1000 each if no failures)
\echo ''
\echo '--- Rows per worker ---'
SELECT
    worker_id,
    COUNT(*)                          AS rows_inserted,
    MIN(inserted_at)                  AS first_insert,
    MAX(inserted_at)                  AS last_insert,
    EXTRACT(EPOCH FROM (MAX(inserted_at) - MIN(inserted_at))) AS duration_seconds
FROM bench.transactions
GROUP BY worker_id
ORDER BY worker_id;

-- Verify UNIQUE constraint held — must be 0
\echo ''
\echo '--- Duplicate idempotency_key check (must be 0) ---'
SELECT COUNT(*) AS duplicates
FROM (
    SELECT idempotency_key
    FROM bench.transactions
    GROUP BY idempotency_key
    HAVING COUNT(*) > 1
) x;

-- Verify CHECK constraints held — must be 0
\echo ''
\echo '--- Constraint violations check (must be 0) ---'
SELECT
    COUNT(*) FILTER (WHERE amount <= 0)        AS bad_amount,
    COUNT(*) FILTER (WHERE balance_after < 0)  AS bad_balance
FROM bench.transactions;

\echo ''
\echo '============================================================'
\echo '  END OF BENCH RESULTS'
\echo '============================================================'

-- Cleanup — drop bench table after results are read
DROP TABLE IF EXISTS bench.transactions;
DROP SCHEMA IF EXISTS bench;
