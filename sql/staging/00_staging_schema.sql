-- ============================================================
-- STAGING SCHEMA
-- Purpose: permissive landing zone for all raw CSV data.
-- Rules:
--   - All columns TEXT (no type enforcement)
--   - No NOT NULL
--   - No UNIQUE
--   - No CHECK
--   - No foreign keys
--   - loaded_at added for traceability only
-- ============================================================

CREATE SCHEMA IF NOT EXISTS staging;
