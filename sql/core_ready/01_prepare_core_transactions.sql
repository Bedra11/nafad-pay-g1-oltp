CREATE SCHEMA IF NOT EXISTS core_ready;

DROP TABLE IF EXISTS core_ready.transactions;

CREATE TABLE core_ready.transactions AS
SELECT
    t.id AS staging_transaction_id,
    t.reference,
    t.idempotency_key,
    t.transaction_type,
    t.transaction_type_label,
    t.amount::numeric(18,2) AS amount,
    t.fee::numeric(18,2) AS fee,
    t.total_amount::numeric(18,2) AS total_amount,
    t.currency,
    t.source_account_id,
    t.destination_account_id,
    t.merchant_id,
    t.agency_id,
    t.status,
    t.failure_reason,
    t.balance_before::numeric(18,2) AS balance_before,
    t.balance_after::numeric(18,2) AS balance_after,
    t.sequence_number::bigint AS sequence_number,
    t.channel,
    t.device_type,
    t.ip_address,
    t.description,
    t.transaction_date::date AS transaction_date,
    t.transaction_time::time AS transaction_time,
    t.created_at::timestamp AS created_at,
    t.completed_at::timestamp AS completed_at
FROM staging.transactions t
WHERE NOT EXISTS (
    SELECT 1
    FROM anomalies.transaction_anomalies a
    WHERE a.staging_transaction_id = t.id
)
AND NOT EXISTS (
    SELECT 1
    FROM anomalies.idempotency_conflicts i
    WHERE i.staging_transaction_id = t.id
)
AND NOT EXISTS (
    SELECT 1
    FROM quarantine.quarantine_transactions q
    WHERE q.staging_transaction_id = t.id
);