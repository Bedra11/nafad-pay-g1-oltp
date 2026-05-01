CREATE TABLE IF NOT EXISTS core.accounts (
    id BIGINT PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES core.users(id),

    account_number TEXT NOT NULL UNIQUE,

    account_type TEXT NOT NULL,

    balance NUMERIC(14,2) NOT NULL,
    available_balance NUMERIC(14,2) NOT NULL,

    currency TEXT NOT NULL DEFAULT 'MRU',

    daily_limit NUMERIC(14,2) NOT NULL,
    monthly_limit NUMERIC(14,2) NOT NULL,

    status TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL,

    opened_date DATE,
    last_activity TIMESTAMP,

    created_at TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT chk_accounts_balance_non_negative CHECK (balance >= 0),
    CONSTRAINT chk_accounts_available_balance_non_negative CHECK (available_balance >= 0),
    CONSTRAINT chk_accounts_daily_limit_non_negative CHECK (daily_limit >= 0),
    CONSTRAINT chk_accounts_monthly_limit_non_negative CHECK (monthly_limit >= 0),
    CONSTRAINT chk_accounts_currency CHECK (currency = 'MRU')
);