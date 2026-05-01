-- ============================================================
-- staging.merchants
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.merchants;

CREATE TABLE staging.merchants (
    id                  TEXT,
    code                TEXT,
    mcc                 TEXT,
    name                TEXT,
    category_code       TEXT,
    category_label      TEXT,
    owner_first_name    TEXT,
    owner_last_name     TEXT,
    owner_full_name     TEXT,
    owner_gender        TEXT,
    owner_ethnicity     TEXT,
    phone               TEXT,
    email               TEXT,
    wilaya_id           TEXT,
    wilaya_name         TEXT,
    moughataa_id        TEXT,
    moughataa_name      TEXT,
    address             TEXT,
    latitude            TEXT,
    longitude           TEXT,
    commission_rate     TEXT,
    avg_transaction_min TEXT,
    avg_transaction_max TEXT,
    status              TEXT,
    registration_date   TEXT,
    created_at          TEXT,
    loaded_at           TIMESTAMPTZ DEFAULT now()
);
