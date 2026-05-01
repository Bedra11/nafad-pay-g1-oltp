-- ============================================================
-- staging.reference_wilayas
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.reference_wilayas;

CREATE TABLE staging.reference_wilayas (
    id              TEXT,
    code            TEXT,
    name            TEXT,
    capital         TEXT,
    latitude        TEXT,
    longitude       TEXT,
    population      TEXT,
    economic_weight TEXT,
    loaded_at       TIMESTAMPTZ DEFAULT now()
);
