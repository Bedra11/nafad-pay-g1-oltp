-- ============================================================
-- 01_validation_routing_checks.sql
-- Verification tests for Member 3: validation / quarantine / anomalies
-- ============================================================

-- 1. Global row counts
SELECT
    (SELECT COUNT(*) FROM staging.transactions) AS staging_transactions,
    (SELECT COUNT(*) FROM anomalies.transaction_anomalies) AS transaction_anomalies,
    (SELECT COUNT(*) FROM anomalies.idempotency_conflicts) AS idempotency_conflicts,
    (SELECT COUNT(*) FROM quarantine.quarantine_transactions) AS quarantine_transactions;

-- 2. Anomaly types distribution
SELECT anomaly_type, COUNT(*) AS total
FROM anomalies.transaction_anomalies
GROUP BY anomaly_type
ORDER BY anomaly_type;

-- 3. Quarantine reasons distribution
SELECT reject_reason, COUNT(*) AS total
FROM quarantine.quarantine_transactions
GROUP BY reject_reason
ORDER BY reject_reason;

-- 4. Check no overlap between transaction_anomalies and quarantine
SELECT COUNT(*) AS overlap_transaction_anomalies_quarantine
FROM anomalies.transaction_anomalies a
JOIN quarantine.quarantine_transactions q
ON a.staging_transaction_id = q.staging_transaction_id;

-- 5. Check no overlap between idempotency_conflicts and quarantine
SELECT COUNT(*) AS overlap_idempotency_conflicts_quarantine
FROM anomalies.idempotency_conflicts i
JOIN quarantine.quarantine_transactions q
ON i.staging_transaction_id = q.staging_transaction_id;

-- 6. Check duplicate rows in quarantine
SELECT staging_transaction_id, COUNT(*) AS duplicate_count
FROM quarantine.quarantine_transactions
GROUP BY staging_transaction_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 7. Check duplicate rows in transaction_anomalies
SELECT staging_transaction_id, COUNT(*) AS duplicate_count
FROM anomalies.transaction_anomalies
GROUP BY staging_transaction_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 8. Check invalid amounts are classified as anomalies
SELECT COUNT(*) AS invalid_amounts_not_classified
FROM staging.transactions t
LEFT JOIN anomalies.transaction_anomalies a
ON t.id = a.staging_transaction_id
AND a.anomaly_type = 'invalid_amount'
WHERE t.amount::numeric <= 0
AND a.staging_transaction_id IS NULL;

-- 9. Check FAILED transactions with changed balance are classified as anomalies
SELECT COUNT(*) AS failed_balance_violations_not_classified
FROM staging.transactions t
LEFT JOIN anomalies.transaction_anomalies a
ON t.id = a.staging_transaction_id
AND a.anomaly_type = 'invalid_failed_balance'
WHERE t.status = 'FAILED'
AND t.balance_before IS NOT NULL
AND t.balance_after IS NOT NULL
AND t.balance_after <> t.balance_before
AND a.staging_transaction_id IS NULL;

-- 10. Check negative balances are classified as anomalies
SELECT COUNT(*) AS negative_balances_not_classified
FROM staging.transactions t
LEFT JOIN anomalies.transaction_anomalies a
ON t.id = a.staging_transaction_id
AND a.anomaly_type = 'negative_balance'
WHERE t.balance_after::numeric < 0
AND a.staging_transaction_id IS NULL;

-- 11. Check source account missing rows are classified as quarantine unless already anomalous
SELECT COUNT(*) AS missing_source_accounts_not_quarantined
FROM staging.transactions t
LEFT JOIN staging.accounts a
ON t.source_account_id = a.id
LEFT JOIN quarantine.quarantine_transactions q
ON t.id = q.staging_transaction_id
AND q.reject_reason = 'missing_source_account'
WHERE (
    t.source_account_id IS NULL
    OR t.source_account_id = ''
    OR a.id IS NULL
)
AND t.id NOT IN (
    SELECT staging_transaction_id FROM anomalies.transaction_anomalies
)
AND t.id NOT IN (
    SELECT staging_transaction_id FROM anomalies.idempotency_conflicts
)
AND q.staging_transaction_id IS NULL;

-- 12. Check destination account missing rows are classified as quarantine unless already anomalous
SELECT COUNT(*) AS missing_destination_accounts_not_quarantined
FROM staging.transactions t
LEFT JOIN staging.accounts a
ON t.destination_account_id = a.id
LEFT JOIN quarantine.quarantine_transactions q
ON t.id = q.staging_transaction_id
AND q.reject_reason = 'missing_destination_account'
WHERE (
    t.destination_account_id IS NULL
    OR t.destination_account_id = ''
    OR a.id IS NULL
)
AND t.id NOT IN (
    SELECT staging_transaction_id FROM anomalies.transaction_anomalies
)
AND t.id NOT IN (
    SELECT staging_transaction_id FROM anomalies.idempotency_conflicts
)
AND q.staging_transaction_id IS NULL;

-- 13. Sample invalid amount rows and their anomaly classification
SELECT t.id, t.amount, a.anomaly_type
FROM staging.transactions t
JOIN anomalies.transaction_anomalies a
ON t.id = a.staging_transaction_id
WHERE t.amount::numeric <= 0
ORDER BY t.id
LIMIT 10;