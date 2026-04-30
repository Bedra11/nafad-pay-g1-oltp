CREATE TABLE IF NOT EXISTS core.transactions (
    id BIGINT PRIMARY KEY,

    reference TEXT NOT NULL UNIQUE,
    idempotency_key TEXT NOT NULL UNIQUE,

    transaction_type TEXT NOT NULL
        REFERENCES reference.tx_types(code),

    amount NUMERIC(14,2) NOT NULL,
    fee NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(14,2),
    currency TEXT NOT NULL DEFAULT 'MRU',

    source_account_id BIGINT NOT NULL
        REFERENCES core.accounts(id),

    destination_account_id BIGINT
        REFERENCES core.accounts(id),

    merchant_id BIGINT,
    agency_id BIGINT,

    status TEXT NOT NULL,
    failure_reason TEXT,

    balance_before NUMERIC(14,2) NOT NULL,
    balance_after NUMERIC(14,2) NOT NULL,

    node_id TEXT,
    processing_node TEXT,
    sequence_number BIGINT,

    channel TEXT,
    device_type TEXT,
    ip_address TEXT,
    description TEXT,

    transaction_date DATE,
    transaction_time TIME,
    created_at TIMESTAMP,
    completed_at TIMESTAMP,

    CONSTRAINT chk_transactions_amount_positive CHECK (amount > 0),
    CONSTRAINT chk_transactions_fee_non_negative CHECK (fee >= 0),
    CONSTRAINT chk_transactions_balance_before_non_negative CHECK (balance_before >= 0),
    CONSTRAINT chk_transactions_balance_after_non_negative CHECK (balance_after >= 0),
    CONSTRAINT chk_transactions_currency CHECK (currency = 'MRU'),
    CONSTRAINT chk_transactions_status CHECK (status IN ('SUCCESS', 'FAILED', 'PENDING')),
    CONSTRAINT chk_transactions_failed_balance_unchanged
        CHECK (status <> 'FAILED' OR balance_after = balance_before),
    CONSTRAINT chk_transactions_completed_after_created
        CHECK (completed_at IS NULL OR created_at IS NULL OR completed_at >= created_at)
);