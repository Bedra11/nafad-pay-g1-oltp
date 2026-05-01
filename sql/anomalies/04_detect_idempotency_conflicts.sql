-- Detect duplicated idempotency keys with different payloads
SELECT
    idempotency_key,
    COUNT(*) AS duplicate_count,
    COUNT(DISTINCT amount) AS distinct_amounts,
    COUNT(DISTINCT status) AS distinct_statuses,
    COUNT(DISTINCT source_account_id) AS distinct_source_accounts,
    COUNT(DISTINCT destination_account_id) AS distinct_destination_accounts
FROM staging.transactions
WHERE idempotency_key IS NOT NULL
  AND idempotency_key <> ''
GROUP BY idempotency_key
HAVING COUNT(*) > 1
   AND (
        COUNT(DISTINCT amount) > 1
        OR COUNT(DISTINCT status) > 1
        OR COUNT(DISTINCT source_account_id) > 1
        OR COUNT(DISTINCT destination_account_id) > 1
   );