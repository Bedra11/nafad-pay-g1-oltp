-- Detect failed transactions that changed balance
SELECT
    id,
    reference,
    idempotency_key,
    'invalid_failed_balance' AS anomaly_type,
    'FAILED transaction changed balance' AS anomaly_details
FROM staging.transactions
WHERE status = 'FAILED'
  AND balance_before IS NOT NULL
  AND balance_after IS NOT NULL
  AND balance_after <> balance_before;

-- Detect non-positive amounts
SELECT
    id,
    reference,
    idempotency_key,
    'invalid_amount' AS anomaly_type,
    'Amount must be greater than zero' AS anomaly_details
FROM staging.transactions
WHERE amount IS NOT NULL
  AND amount::numeric <= 0;

-- Detect negative resulting balances
SELECT
    id,
    reference,
    idempotency_key,
    'negative_balance' AS anomaly_type,
    'Balance after transaction is negative' AS anomaly_details
FROM staging.transactions
WHERE balance_after IS NOT NULL
  AND balance_after::numeric < 0;