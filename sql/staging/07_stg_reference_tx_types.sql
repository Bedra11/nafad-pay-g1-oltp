-- ============================================================
-- staging.reference_tx_types
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
-- ============================================================

DROP TABLE IF EXISTS staging.reference_tx_types;

CREATE TABLE staging.reference_tx_types (
    id                   TEXT,
    code                 TEXT,
    label                TEXT,
    description          TEXT,
    requires_destination TEXT,
    requires_merchant    TEXT,
    requires_agency      TEXT,
    is_credit            TEXT,
    loaded_at            TIMESTAMPTZ DEFAULT now()
);
