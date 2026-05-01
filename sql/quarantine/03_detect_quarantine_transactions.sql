-- Detect missing or unresolved source accounts
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'missing_source_account' AS reject_reason,
    'Source account is missing or cannot be resolved' AS reject_details
FROM staging.transactions t
LEFT JOIN staging.accounts a
    ON t.source_account_id = a.id
WHERE t.source_account_id IS NULL
   OR t.source_account_id = ''
   OR a.id IS NULL;

-- Detect missing or unresolved destination accounts
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'missing_destination_account' AS reject_reason,
    'Destination account is missing or cannot be resolved' AS reject_details
FROM staging.transactions t
LEFT JOIN staging.accounts a
    ON t.destination_account_id = a.id
WHERE t.destination_account_id IS NULL
   OR t.destination_account_id = ''
   OR a.id IS NULL;

-- Detect PAY transactions without merchant
SELECT
    t.id,
    t.reference,
    t.idempotency_key,
    'missing_merchant' AS reject_reason,
    'PAY transaction requires a merchant_id' AS reject_details
FROM staging.transactions t
WHERE t.transaction_type = 'PAY'
  AND (t.merchant_id IS NULL OR t.merchant_id = '');