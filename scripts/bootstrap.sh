#!/usr/bin/env bash
# ============================================================
# bootstrap.sh
# NAFAD PAY G1 OLTP
#
# One-command bootstrap for the staging setup:
#   1. Starts the PostgreSQL Docker container
#   2. Waits for it to be healthy
#   3. Creates staging schema and tables
#   4. Loads reference data
#   5. Loads raw G1 data
#
# Usage (from repo root):
#   bash scripts/bootstrap.sh
#
# Optional env overrides:
#   DB_NAME          (default: nafadpay)
#   DB_USER          (default: admin)
#   DB_PASSWORD      (default: nafadpay0001)
#   DB_PORT          (default: 5432)
#   CONTAINER_NAME   (default: nafadpay-postgres)
# ============================================================

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-nafadpay0001}"
DB_PORT="${DB_PORT:-5432}"
CONTAINER_NAME="${CONTAINER_NAME:-nafadpay-postgres}"

export DB_NAME DB_USER DB_PASSWORD DB_PORT CONTAINER_NAME

echo "=================================================="
echo "  NAFAD PAY —  Bootstrap"
echo "=================================================="
echo ""

# Step 1 — Start container
echo "[1/5] Starting PostgreSQL container ..."
docker compose -f docker/docker-compose.yml up -d
echo "      Container started."
echo ""

# Step 2 — Wait for healthy
echo "[2/5] Waiting for PostgreSQL to be ready ..."
READY=0
for i in $(seq 1 30); do
  if docker exec "$CONTAINER_NAME" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
    READY=1
    break
  fi
  echo "      Not ready yet, retrying ($i/30) ..."
  sleep 2
done

if [ "$READY" -ne 1 ]; then
  echo "ERROR: PostgreSQL did not become ready in time. Check docker logs $CONTAINER_NAME"
  exit 1
fi
echo "      PostgreSQL is ready."
echo ""

# Step 3 — Create schema and tables
echo "[3/5] Creating staging schema and tables ..."
bash scripts/init_staging.sh
echo ""

# Step 4 — Load reference data
echo "[4/5] Loading reference data ..."
bash scripts/load_reference.sh
echo ""

# Step 5 — Load raw G1 data
echo "[5/5] Loading raw G1 data ..."
bash scripts/load_raw.sh
echo ""

echo "=================================================="
echo " bootstrap completed successfully."
echo "=================================================="
