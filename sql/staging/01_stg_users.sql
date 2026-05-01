-- ============================================================
-- staging.users
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.users;

CREATE TABLE staging.users (
    id                  TEXT,
    nni                 TEXT,
    first_name          TEXT,
    last_name           TEXT,
    full_name           TEXT,
    gender              TEXT,
    birth_date          TEXT,
    ethnicity           TEXT,
    phone               TEXT,
    email               TEXT,
    wilaya_id           TEXT,
    wilaya_name         TEXT,
    moughataa_id        TEXT,
    moughataa_name      TEXT,
    profile_type        TEXT,
    kyc_level           TEXT,
    status              TEXT,
    device_type         TEXT,
    registration_date   TEXT,
    last_login          TEXT,
    created_at          TEXT,
    updated_at          TEXT,
    loaded_at           TIMESTAMPTZ DEFAULT now()
);
