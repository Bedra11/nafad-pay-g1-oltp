CREATE TABLE IF NOT EXISTS core.agencies (
    id BIGINT PRIMARY KEY,

    code TEXT NOT NULL UNIQUE,
    name TEXT,

    wilaya_id INTEGER NOT NULL
        REFERENCES reference.wilayas(id),

    float_balance NUMERIC(14,2),
    tier TEXT,
    license_number TEXT,

    status TEXT,

    created_at TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT chk_agencies_float_balance_non_negative
        CHECK (float_balance IS NULL OR float_balance >= 0)
);