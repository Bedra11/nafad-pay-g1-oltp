TRUNCATE TABLE core.transactions RESTART IDENTITY CASCADE;

INSERT INTO core.transactions (
    id,
    reference,
    idempotency_key,
    transaction_type,
    amount,
    fee,
    total_amount,
    currency,
    source_account_id,
    destination_account_id,
    merchant_id,
    agency_id,
    status,
    failure_reason,
    balance_before,
    balance_after,
    sequence_number,
    channel,
    device_type,
    ip_address,
    description,
    transaction_date,
    transaction_time,
    created_at,
    completed_at
)
SELECT
    NULLIF(t.id, '')::bigint,
    t.reference,
    t.idempotency_key,
    t.transaction_type,
    NULLIF(t.amount, '')::numeric(14,2),
    COALESCE(NULLIF(t.fee, '')::numeric(14,2), 0),
    NULLIF(t.total_amount, '')::numeric(14,2),
    COALESCE(NULLIF(t.currency, ''), 'MRU'),
    NULLIF(t.source_account_id, '')::bigint,
    NULLIF(t.destination_account_id, '')::bigint,
    NULLIF(t.merchant_id, '')::bigint,
    NULLIF(t.agency_id, '')::bigint,
    t.status,
    NULLIF(t.failure_reason, ''),
    NULLIF(t.balance_before, '')::numeric(14,2),
    NULLIF(t.balance_after, '')::numeric(14,2),
    NULLIF(t.sequence_number, '')::bigint,
    NULLIF(t.channel, ''),
    NULLIF(t.device_type, ''),
    NULLIF(t.ip_address, ''),
    NULLIF(t.description, ''),
    NULLIF(t.transaction_date, '')::date,
    NULLIF(t.transaction_time, '')::time,
    NULLIF(t.created_at, '')::timestamp,
    NULLIF(t.completed_at, '')::timestamp
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
)
ON CONFLICT (id) DO NOTHING;