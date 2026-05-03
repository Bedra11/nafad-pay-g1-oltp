#!/usr/bin/env bash
# ============================================================
# run_all.sh — NAFAD-PAY G1 OLTP full run
# Runs: pipeline → indexes → validation → queries
#
# Usage (from project root):
#   bash scripts/run_all.sh
# ============================================================

set -e

DB=nafadpay-postgres
U=admin
D=nafadpay

psql_file() {
    docker exec -i $DB psql -U $U -d $D < "$1"
}

banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    printf "║  %-52s║\n" "$1"
    echo "╚══════════════════════════════════════════════════════╝"
}

step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

banner "NAFAD-PAY G1 OLTP — Full Run"
START=$(date +%s)

# ── 1. Pipeline ───────────────────────────────────────────────────────────────
step "STEP 1 — Running Go pipeline"
go run eda/cmd/pipeline/main.go

# ── 2. Indexes ────────────────────────────────────────────────────────────────
step "STEP 2 — Creating indexes"
psql_file sql/queries/nafadpay_indexes.sql

# ── 3. Validation ─────────────────────────────────────────────────────────────
step "STEP 3 — Validating pipeline output"
psql_file sql/queries/nafadpay_validate_pipeline.sql

# ── 4. Queries ────────────────────────────────────────────────────────────────
step "STEP 4 — Running analytical queries (Q1–Q20)"
psql_file sql/queries/nafadpay_queries.sql

# ── Done ──────────────────────────────────────────────────────────────────────
END=$(date +%s)
ELAPSED=$((END - START))

echo ""
echo "╔══════════════════════════════════════════════════════╗"
printf "║  All done in %ds%-38s║\n" "$ELAPSED" ""
echo "╚══════════════════════════════════════════════════════╝"
