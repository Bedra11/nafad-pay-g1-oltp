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
    staging_transaction_id::bigint,
    reference,
    idempotency_key,
    transaction_type,
    amount,
    COALESCE(fee, 0),
    total_amount,
    COALESCE(NULLIF(currency, ''), 'MRU'),
    source_account_id::bigint,
    destination_account_id::bigint,
    merchant_id::bigint,
    agency_id::bigint,
    status,
    NULLIF(failure_reason, ''),
    balance_before,
    balance_after,
    sequence_number,
    NULLIF(channel, ''),
    NULLIF(device_type, ''),
    NULLIF(ip_address, ''),
    NULLIF(description, ''),
    transaction_date,
    transaction_time,
    created_at,
    completed_at
FROM core_ready.transactions t
WHERE EXISTS (
    SELECT 1
    FROM core.accounts a
    WHERE a.id = t.source_account_id::bigint
)
AND (
    t.destination_account_id IS NULL
    OR EXISTS (
        SELECT 1
        FROM core.accounts a
        WHERE a.id = t.destination_account_id::bigint
    )
)
ON CONFLICT (id) DO NOTHING;