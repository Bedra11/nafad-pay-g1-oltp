WITH conflict_keys AS (
    SELECT
        idempotency_key
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
       )
)
INSERT INTO anomalies.idempotency_conflicts (
    conflict_group_id,
    idempotency_key,
    staging_transaction_id,
    transaction_reference,
    amount,
    status,
    raw_payload
)
SELECT
    'idem_' || t.idempotency_key,
    t.idempotency_key,
    t.id,
    t.reference,
    t.amount,
    t.status,
    to_jsonb(t)
FROM staging.transactions t
JOIN conflict_keys c
    ON t.idempotency_key = c.idempotency_key;