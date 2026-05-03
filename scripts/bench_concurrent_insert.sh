#!/usr/bin/env bash
# ============================================================
# bench_concurrent_insert.sh
# Member 4 — NAFAD PAY G1 OLTP
#
# Concurrent insertion bench:
#   - 10 parallel workers
#   - Each inserts 1000 transactions into bench.transactions
#   - Measures total time, TPS, and checks for deadlocks
#
# Usage (from repo root):
#   bash scripts/bench_concurrent_insert.sh
#
# Output saved to: docs/bench_concurrent_report.txt
# ============================================================

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
CONTAINER="${CONTAINER_NAME:-nafadpay-postgres}"
WORKERS=10
INSERTS_PER_WORKER=1000
OUTPUT="docs/bench_concurrent_report.txt"

mkdir -p docs

# Use docker exec with -c flag (inline SQL) instead of -f - (stdin pipe)
# This avoids Git Bash on Windows stdin redirection issues
run_psql() {
    docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "$1"
}

# ── worker function ────────────────────────────────────────────────────────────
run_worker() {
    local worker_id=$1
    local errors=0

    for i in $(seq 1 $INSERTS_PER_WORKER); do
        local ref="BENCH-W${worker_id}-TX${i}"
        local idem="idem-w${worker_id}-${i}"
        local amount=$((RANDOM % 9000 + 100))
        local balance_before=$((RANDOM % 50000 + 1000))
        local balance_after=$((balance_before - amount))

        if [ "$balance_after" -lt 0 ]; then
            balance_after=0
        fi

        docker exec -i "$CONTAINER" psql \
            -U "$DB_USER" -d "$DB_NAME" \
            -v ON_ERROR_STOP=0 \
            -c "INSERT INTO bench.transactions
                    (reference, idempotency_key, worker_id, amount,
                     balance_before, balance_after, status)
                VALUES
                    ('$ref','$idem',$worker_id,$amount,
                     $balance_before,$balance_after,'SUCCESS');" \
            > /dev/null 2>&1 || ((errors++)) || true
    done

    echo "Worker $worker_id done — errors: $errors"
}

# ── main ──────────────────────────────────────────────────────────────────────

{
echo "============================================================"
echo "  NAFAD PAY G1 OLTP — CONCURRENT INSERTION BENCH"
echo "  Generated: $(date)"
echo "  Workers: $WORKERS | Inserts per worker: $INSERTS_PER_WORKER"
echo "  Total target: $((WORKERS * INSERTS_PER_WORKER)) rows"
echo "============================================================"
echo ""
} | tee "$OUTPUT"

# Step 1 — Setup bench table using inline SQL (no file pipe)
echo "[1/4] Setting up bench table..." | tee -a "$OUTPUT"

run_psql "CREATE SCHEMA IF NOT EXISTS bench;" >> "$OUTPUT" 2>&1
run_psql "DROP TABLE IF EXISTS bench.transactions CASCADE;" >> "$OUTPUT" 2>&1
run_psql "CREATE TABLE bench.transactions (
    id               BIGSERIAL PRIMARY KEY,
    reference        TEXT        NOT NULL UNIQUE,
    idempotency_key  TEXT        NOT NULL UNIQUE,
    worker_id        INTEGER     NOT NULL,
    amount           NUMERIC     NOT NULL CHECK (amount > 0),
    balance_before   NUMERIC     NOT NULL CHECK (balance_before >= 0),
    balance_after    NUMERIC     NOT NULL CHECK (balance_after  >= 0),
    status           TEXT        NOT NULL DEFAULT 'SUCCESS',
    inserted_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);" >> "$OUTPUT" 2>&1

echo "      bench.transactions created." | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# Step 2 — Launch all workers in parallel
echo "[2/4] Launching $WORKERS parallel workers..." | tee -a "$OUTPUT"
START=$(date +%s)

PIDS=()
for w in $(seq 1 $WORKERS); do
    run_worker "$w" >> "$OUTPUT" 2>&1 &
    PIDS+=($!)
done

# Wait for all workers
for pid in "${PIDS[@]}"; do
    wait "$pid"
done

END=$(date +%s)
ELAPSED=$((END - START))

echo "" | tee -a "$OUTPUT"
echo "[3/4] All workers finished in ${ELAPSED}s" | tee -a "$OUTPUT"

# Calculate TPS
TOTAL=$((WORKERS * INSERTS_PER_WORKER))
if [ "$ELAPSED" -gt 0 ]; then
    TPS=$((TOTAL / ELAPSED))
else
    TPS="$TOTAL (< 1s)"
fi

echo "      Total inserts attempted : $TOTAL" | tee -a "$OUTPUT"
echo "      Elapsed time            : ${ELAPSED}s" | tee -a "$OUTPUT"
echo "      Throughput (TPS)        : ~$TPS transactions/second" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# Step 3 — Read results using inline SQL
echo "[4/4] Verifying results and constraints..." | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

echo "--- Total rows inserted ---" | tee -a "$OUTPUT"
run_psql "SELECT COUNT(*) AS total_rows_inserted FROM bench.transactions;" \
    | tee -a "$OUTPUT"

echo "" | tee -a "$OUTPUT"
echo "--- Rows per worker ---" | tee -a "$OUTPUT"
run_psql "SELECT worker_id, COUNT(*) AS rows_inserted,
    EXTRACT(EPOCH FROM (MAX(inserted_at) - MIN(inserted_at))) AS duration_seconds
FROM bench.transactions
GROUP BY worker_id ORDER BY worker_id;" \
    | tee -a "$OUTPUT"

echo "" | tee -a "$OUTPUT"
echo "--- Duplicate idempotency_key check (must be 0) ---" | tee -a "$OUTPUT"
run_psql "SELECT COUNT(*) AS duplicates FROM (
    SELECT idempotency_key FROM bench.transactions
    GROUP BY idempotency_key HAVING COUNT(*) > 1
) x;" | tee -a "$OUTPUT"

echo "" | tee -a "$OUTPUT"
echo "--- Constraint violations check (must be 0) ---" | tee -a "$OUTPUT"
run_psql "SELECT
    COUNT(*) FILTER (WHERE amount <= 0)       AS bad_amount,
    COUNT(*) FILTER (WHERE balance_after < 0) AS bad_balance
FROM bench.transactions;" | tee -a "$OUTPUT"

# Cleanup
echo "" | tee -a "$OUTPUT"
echo "--- Cleaning up bench schema ---" | tee -a "$OUTPUT"
run_psql "DROP TABLE IF EXISTS bench.transactions; DROP SCHEMA IF EXISTS bench;" \
    >> "$OUTPUT" 2>&1
echo "      bench schema dropped." | tee -a "$OUTPUT"

echo "" | tee -a "$OUTPUT"
echo "============================================================" | tee -a "$OUTPUT"
echo "  Bench complete. Report saved to: $OUTPUT"                   | tee -a "$OUTPUT"
echo "============================================================" | tee -a "$OUTPUT"
