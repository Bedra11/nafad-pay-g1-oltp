#!/usr/bin/env bash
# ============================================================
# init_staging.sh
#
# Creates the staging schema and all staging tables
# by running the SQL files through the running Docker container.
#
# Must be run from the repo root.
# Run this BEFORE load_reference.sh and load_raw.sh.
#
# Usage:
#   bash scripts/init_staging.sh
# ============================================================

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
CONTAINER_NAME="${CONTAINER_NAME:-nafadpay-postgres}"

PSQL="docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1"

echo "=== Creating staging schema and tables ==="
echo "Container: $CONTAINER_NAME / DB: $DB_NAME / User: $DB_USER"
echo ""

FILES=(
  "sql/staging/00_staging_schema.sql"
  "sql/staging/01_stg_users.sql"
  "sql/staging/02_stg_accounts.sql"
  "sql/staging/03_stg_merchants.sql"
  "sql/staging/04_stg_agencies.sql"
  "sql/staging/05_stg_transactions.sql"
  "sql/staging/06_stg_reference_wilayas.sql"
  "sql/staging/07_stg_reference_tx_types.sql"
  "sql/staging/08_stg_reference_categories.sql"
)

for file in "${FILES[@]}"; do
  echo "  Running $file ..."
  $PSQL -f - < "$file"
  echo "  Done."
done

echo ""
echo "=== Staging schema created successfully ==="
