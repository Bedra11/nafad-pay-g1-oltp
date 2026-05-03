-- Create bench schema if needed
CREATE SCHEMA IF NOT EXISTS bench;

-- Drop and recreate clean bench table
DROP TABLE IF EXISTS bench.transactions CASCADE;

CREATE TABLE bench.transactions (
    id               BIGSERIAL PRIMARY KEY,
    reference        TEXT        NOT NULL UNIQUE,
    idempotency_key  TEXT        NOT NULL UNIQUE,
    worker_id        INTEGER     NOT NULL,
    amount           NUMERIC     NOT NULL CHECK (amount > 0),
    balance_before   NUMERIC     NOT NULL CHECK (balance_before >= 0),
    balance_after    NUMERIC     NOT NULL CHECK (balance_after  >= 0),
    status           TEXT        NOT NULL DEFAULT 'SUCCESS',
    inserted_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Confirm table is ready
SELECT 'bench.transactions ready' AS status, 0 AS row_count;
