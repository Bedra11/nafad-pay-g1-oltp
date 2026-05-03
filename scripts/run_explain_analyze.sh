#!/usr/bin/env bash

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
CONTAINER="${CONTAINER_NAME:-nafadpay-postgres}"
OUTPUT="docs/explain_analyze_report.txt"

mkdir -p docs

echo "Running EXPLAIN ANALYZE on 5 queries..."
echo "Output will be saved to: $OUTPUT"
echo ""

{
    echo "============================================================"
    echo "  NAFAD PAY G1 OLTP — EXPLAIN ANALYZE REPORT"
    echo "  Generated: $(date)"
    echo "  Container: $CONTAINER / DB: $DB_NAME"
    echo "============================================================"
    echo ""

    docker exec -i "$CONTAINER" \
        psql -U "$DB_USER" -d "$DB_NAME" \
        -v ON_ERROR_STOP=1 \
        -f - < sql/tests/nafadpay_explain_analyze.sql

} > "$OUTPUT" 2>&1

echo "Done. Report saved to: $OUTPUT"
echo ""
echo "--- Preview (last 10 lines) ---"
tail -10 "$OUTPUT"
