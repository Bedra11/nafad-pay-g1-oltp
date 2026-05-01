CREATE TABLE IF NOT EXISTS anomalies.idempotency_conflicts (
    conflict_id BIGSERIAL PRIMARY KEY,
    conflict_group_id TEXT NOT NULL,
    idempotency_key TEXT NOT NULL,
    staging_transaction_id TEXT,
    transaction_reference TEXT,
    amount TEXT,
    status TEXT,
    raw_payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);