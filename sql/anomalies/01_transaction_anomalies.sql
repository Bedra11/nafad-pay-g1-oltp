CREATE SCHEMA IF NOT EXISTS anomalies;

CREATE TABLE IF NOT EXISTS anomalies.transaction_anomalies (
    anomaly_id BIGSERIAL PRIMARY KEY,
    staging_transaction_id TEXT,
    transaction_reference TEXT,
    idempotency_key TEXT,
    anomaly_type TEXT NOT NULL,
    anomaly_details TEXT,
    raw_payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);