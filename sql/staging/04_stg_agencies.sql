-- ============================================================
-- staging.agencies
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.agencies;

CREATE TABLE staging.agencies (
    id              TEXT,
    code            TEXT,
    name            TEXT,
    wilaya_id       TEXT,
    wilaya_name     TEXT,
    moughataa_id    TEXT,
    moughataa_name  TEXT,
    address         TEXT,
    latitude        TEXT,
    longitude       TEXT,
    phone           TEXT,
    email           TEXT,
    opening_hours   TEXT,
    status          TEXT,
    tier            TEXT,
    float_balance   TEXT,
    max_float       TEXT,
    license_number  TEXT,
    license_expiry  TEXT,
    created_at      TEXT,
    loaded_at       TIMESTAMPTZ DEFAULT now()
);
