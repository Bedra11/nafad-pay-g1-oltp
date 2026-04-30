CREATE TABLE IF NOT EXISTS core.accounts (
    id BIGINT PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES core.users(id),

    account_number TEXT NOT NULL UNIQUE,

    balance NUMERIC(14,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'MRU',

    status TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT chk_accounts_balance_non_negative CHECK (balance >= 0),
    CONSTRAINT chk_accounts_currency CHECK (currency = 'MRU')
);