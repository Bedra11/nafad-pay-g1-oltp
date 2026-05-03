-- ============================================================
-- FIX 4 : Index corrections
-- a) Convert idx_tx_merchant_status to a PARTIAL index (spec requirement)
-- b) Add missing idx on (node_id, sequence_number)
-- Run : docker exec -i nafadpay-postgres psql -U admin -d nafadpay < fix_04_indexes.sql
-- ============================================================

-- ── 4a : Replace full index with partial index (WHERE merchant_id IS NOT NULL) ─
-- README spec: "partial WHERE merchant_id IS NOT NULL"
-- This avoids indexing the ~majority of rows that have NULL merchant_id (P2P transfers)

DROP INDEX IF EXISTS core.idx_tx_merchant_status;

CREATE INDEX idx_tx_merchant_status
    ON core.transactions (merchant_id, status)
    WHERE merchant_id IS NOT NULL;

-- ── 4b : Add node_id + sequence_number index ─────────────────────────────────
-- README spec: "(node_id, sequence_number) – ordonnancement par nœud"
-- Essential for reconciliation queries checking clock-skew and sequence gaps

CREATE INDEX IF NOT EXISTS idx_tx_node_sequence
    ON core.transactions (node_id, sequence_number);

-- ── Verify final index list ───────────────────────────────────────────────────
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;
