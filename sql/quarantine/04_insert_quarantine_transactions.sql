INSERT INTO quarantine.quarantine_transactions (
    staging_transaction_id,
    transaction_reference,
    idempotency_key,
    reject_reason,
    reject_details,
    raw_payload
)
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'missing_source_account',
    'Source account is missing or cannot be resolved',
    to_jsonb(t)
FROM staging.transactions t
LEFT JOIN staging.accounts a
    ON t.source_account_id = a.id
WHERE (
    t.source_account_id IS NULL
    OR t.source_account_id = ''
    OR a.id IS NULL
)
AND t.id NOT IN (
    SELECT staging_transaction_id
    FROM anomalies.transaction_anomalies
);

------------------------------------------------------------

INSERT INTO quarantine.quarantine_transactions (
    staging_transaction_id,
    transaction_reference,
    idempotency_key,
    reject_reason,
    reject_details,
    raw_payload
)
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'missing_destination_account',
    'Destination account is missing or cannot be resolved',
    to_jsonb(t)
FROM staging.transactions t
LEFT JOIN staging.accounts a
    ON t.destination_account_id = a.id
WHERE (
    t.destination_account_id IS NULL
    OR t.destination_account_id = ''
    OR a.id IS NULL
)
AND t.id NOT IN (
    SELECT staging_transaction_id
    FROM anomalies.transaction_anomalies
);

------------------------------------------------------------

INSERT INTO quarantine.quarantine_transactions (
    staging_transaction_id,
    transaction_reference,
    idempotency_key,
    reject_reason,
    reject_details,
    raw_payload
)
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'missing_merchant',
    'PAY transaction requires a merchant_id',
    to_jsonb(t)
FROM staging.transactions t
WHERE t.transaction_type = 'PAY'
  AND (t.merchant_id IS NULL OR t.merchant_id = '')
  AND t.id NOT IN (
    SELECT staging_transaction_id
    FROM anomalies.transaction_anomalies
);