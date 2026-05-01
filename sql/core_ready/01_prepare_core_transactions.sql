CREATE SCHEMA IF NOT EXISTS core_ready;

DROP TABLE IF EXISTS core_ready.transactions;

CREATE TABLE core_ready.transactions AS
SELECT t.*
FROM staging.transactions t
WHERE t.id NOT IN (
    SELECT staging_transaction_id
    FROM anomalies.transaction_anomalies
)
AND t.id NOT IN (
    SELECT staging_transaction_id
    FROM anomalies.idempotency_conflicts
)
AND t.id NOT IN (
    SELECT staging_transaction_id
    FROM quarantine.quarantine_transactions
);