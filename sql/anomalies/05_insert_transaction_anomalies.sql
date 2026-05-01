INSERT INTO anomalies.transaction_anomalies (
    staging_transaction_id,
    transaction_reference,
    idempotency_key,
    anomaly_type,
    anomaly_details,
    raw_payload
)
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'invalid_failed_balance',
    'FAILED transaction changed balance',
    to_jsonb(t)
FROM staging.transactions t
WHERE t.status = 'FAILED'
  AND t.balance_before IS NOT NULL
  AND t.balance_after IS NOT NULL
  AND t.balance_after <> t.balance_before;

INSERT INTO anomalies.transaction_anomalies (
    staging_transaction_id,
    transaction_reference,
    idempotency_key,
    anomaly_type,
    anomaly_details,
    raw_payload
)
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'invalid_amount',
    'Amount must be greater than zero',
    to_jsonb(t)
FROM staging.transactions t
WHERE t.amount IS NOT NULL
  AND t.amount::numeric <= 0;

INSERT INTO anomalies.transaction_anomalies (
    staging_transaction_id,
    transaction_reference,
    idempotency_key,
    anomaly_type,
    anomaly_details,
    raw_payload
)
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'negative_balance',
    'Balance after transaction is negative',
    to_jsonb(t)
FROM staging.transactions t
WHERE t.balance_after IS NOT NULL
  AND t.balance_after::numeric < 0;