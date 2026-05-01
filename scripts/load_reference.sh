#!/usr/bin/env bash
# ============================================================
# load_reference.sh
#
# Loads shared reference CSVs into staging reference tables.
# Uses COPY (server-side) from files mounted inside the container.
# Does NOT require local psql installation.
#
# Run AFTER init_staging.sh and BEFORE load_raw.sh.
#
# Usage:
#   bash scripts/load_reference.sh
# ============================================================

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
CONTAINER_NAME="${CONTAINER_NAME:-nafadpay-postgres}"

PSQL="docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1"

echo "=== Loading reference data into staging ==="
echo "Container: $CONTAINER_NAME / DB: $DB_NAME"
echo ""

# ---- reference_wilayas ----
echo "[1/3] Loading staging.reference_wilayas ..."
$PSQL -c "TRUNCATE staging.reference_wilayas;"
$PSQL -c "COPY staging.reference_wilayas (id, code, name, capital, latitude, longitude, population, economic_weight) FROM '/workspace/data/shared/reference_wilayas.csv' CSV HEADER;"
echo "      Done."

# ---- reference_tx_types ----
echo "[2/3] Loading staging.reference_tx_types ..."
$PSQL -c "TRUNCATE staging.reference_tx_types;"
$PSQL -c "COPY staging.reference_tx_types (id, code, label, description, requires_destination, requires_merchant, requires_agency, is_credit) FROM '/workspace/data/shared/reference_tx_types.csv' CSV HEADER;"
echo "      Done."

# ---- reference_categories ----
echo "[3/3] Loading staging.reference_categories ..."
$PSQL -c "TRUNCATE staging.reference_categories;"
$PSQL -c "COPY staging.reference_categories (id, code, mcc, label, description, avg_min, avg_max) FROM '/workspace/data/shared/reference_categories.csv' CSV HEADER;"
echo "      Done."

echo ""
echo "=== Reference data loaded successfully ==="
