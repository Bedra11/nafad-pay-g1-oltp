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
    'missing_core_reference',
    'Transaction references a parent record that does not exist in core tables',
    to_jsonb(t)
FROM staging.transactions t

LEFT JOIN core.accounts sa
    ON t.source_account_id ~ '^[0-9]+$'
   AND t.source_account_id::bigint = sa.id

LEFT JOIN core.accounts da
    ON t.destination_account_id ~ '^[0-9]+$'
   AND t.destination_account_id::bigint = da.id

LEFT JOIN core.merchants m
    ON t.merchant_id ~ '^[0-9]+$'
   AND t.merchant_id::bigint = m.id

LEFT JOIN core.agencies ag
    ON t.agency_id ~ '^[0-9]+$'
   AND t.agency_id::bigint = ag.id

WHERE
(
    (
        t.source_account_id IS NOT NULL
        AND t.source_account_id <> ''
        AND t.source_account_id ~ '^[0-9]+$'
        AND sa.id IS NULL
    )
    OR
    (
        t.destination_account_id IS NOT NULL
        AND t.destination_account_id <> ''
        AND t.destination_account_id ~ '^[0-9]+$'
        AND da.id IS NULL
    )
    OR
    (
        t.merchant_id IS NOT NULL
        AND t.merchant_id <> ''
        AND t.merchant_id ~ '^[0-9]+$'
        AND m.id IS NULL
    )
    OR
    (
        t.agency_id IS NOT NULL
        AND t.agency_id <> ''
        AND t.agency_id ~ '^[0-9]+$'
        AND ag.id IS NULL
    )
)

AND t.id NOT IN (
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