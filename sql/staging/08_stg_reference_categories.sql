-- ============================================================
-- staging.reference_categories
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.reference_categories;

CREATE TABLE staging.reference_categories (
    id          TEXT,
    code        TEXT,
    mcc         TEXT,
    label       TEXT,
    description TEXT,
    avg_min     TEXT,
    avg_max     TEXT,
    loaded_at   TIMESTAMPTZ DEFAULT now()
);
