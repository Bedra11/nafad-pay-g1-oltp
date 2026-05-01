CREATE SCHEMA IF NOT EXISTS quarantine;

CREATE TABLE IF NOT EXISTS quarantine.quarantine_transactions (
    quarantine_id BIGSERIAL PRIMARY KEY,
    staging_transaction_id TEXT,
    transaction_reference TEXT,
    idempotency_key TEXT,
    reject_reason TEXT NOT NULL,
    reject_details TEXT,
    raw_payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);