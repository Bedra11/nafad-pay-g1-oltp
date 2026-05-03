#!/usr/bin/env bash

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
CONTAINER="${CONTAINER_NAME:-nafadpay-postgres}"
WORKERS=10
INSERTS_PER_WORKER=1000
OUTPUT="docs/bench_concurrent_report.txt"

mkdir -p docs

PSQL="docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1"

# ── worker function ────────────────────────────────────────────────────────────
# Each worker inserts INSERTS_PER_WORKER rows with unique keys.
# worker_id is embedded in the key to guarantee global uniqueness.

run_worker() {
    local worker_id=$1
    local errors=0

    for i in $(seq 1 $INSERTS_PER_WORKER); do
        local ref="BENCH-W${worker_id}-TX${i}"
        local idem="idem-w${worker_id}-${i}"
        local amount=$((RANDOM % 9000 + 100))       # 100 to 9100
        local balance_before=$((RANDOM % 50000 + 1000))
        local balance_after=$((balance_before - amount))

        # Skip if balance would go negative (simulate real constraint)
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
                    ('$ref', '$idem', $worker_id, $amount,
                     $balance_before, $balance_after, 'SUCCESS');" \
            > /dev/null 2>&1 || ((errors++))
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

# Step 1 — Setup
echo "[1/4] Setting up bench table..." | tee -a "$OUTPUT"
$PSQL -f sql/tests/bench_concurrent_setup.sql >> "$OUTPUT" 2>&1
echo "" | tee -a "$OUTPUT"

# Step 2 — Launch all workers in parallel
echo "[2/4] Launching $WORKERS parallel workers..." | tee -a "$OUTPUT"
START=$(date +%s%N)  # nanoseconds

PIDS=()
for w in $(seq 1 $WORKERS); do
    run_worker "$w" >> "$OUTPUT" 2>&1 &
    PIDS+=($!)
done

# Wait for all workers to finish
for pid in "${PIDS[@]}"; do
    wait "$pid"
done

END=$(date +%s%N)
ELAPSED_MS=$(( (END - START) / 1000000 ))
ELAPSED_S=$(echo "scale=3; $ELAPSED_MS / 1000" | bc)

echo "" | tee -a "$OUTPUT"
echo "[3/4] All workers finished in ${ELAPSED_S}s" | tee -a "$OUTPUT"

# Step 3 — Calculate TPS
TOTAL=$((WORKERS * INSERTS_PER_WORKER))
TPS=$(echo "scale=0; $TOTAL * 1000 / $ELAPSED_MS" | bc)
echo "      Total inserts attempted : $TOTAL" | tee -a "$OUTPUT"
echo "      Elapsed time            : ${ELAPSED_S}s" | tee -a "$OUTPUT"
echo "      Throughput (TPS)        : ~$TPS transactions/second" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# Step 4 — Read results and verify constraints
echo "[4/4] Reading results and verifying constraints..." | tee -a "$OUTPUT"
$PSQL -f sql/tests/bench_concurrent_results.sql >> "$OUTPUT" 2>&1

echo "" | tee -a "$OUTPUT"
echo "============================================================" | tee -a "$OUTPUT"
echo "  Bench complete. Report saved to: $OUTPUT" | tee -a "$OUTPUT"
echo "============================================================" | tee -a "$OUTPUT"

echo ""
echo "Report saved to: $OUTPUT"
