-- ============================================================
-- staging.accounts
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.accounts;

CREATE TABLE staging.accounts (
    id                  TEXT,
    user_id             TEXT,
    account_number      TEXT,
    account_type        TEXT,
    account_type_label  TEXT,
    currency            TEXT,
    balance             TEXT,
    available_balance   TEXT,
    daily_limit         TEXT,
    monthly_limit       TEXT,
    status              TEXT,
    is_primary          TEXT,
    opened_date         TEXT,
    last_activity       TEXT,
    created_at          TEXT,
    updated_at          TEXT,
    loaded_at           TIMESTAMPTZ DEFAULT now()
);
