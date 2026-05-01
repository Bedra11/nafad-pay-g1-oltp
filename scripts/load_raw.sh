#!/usr/bin/env bash
# ============================================================
# load_raw.sh
#
# Loads G1 raw CSVs into staging tables.
# Uses COPY (server-side) from files mounted inside the container.
# Does NOT require local psql installation.
#
# Philosophy:
#   - Preserves ALL rows exactly as-is
#   - No cleaning, no deduplication, no rejection
#   - Validation and routing done later by Member 3 / Go pipeline
#
# Run AFTER load_reference.sh.
#
# Usage:
#   bash scripts/load_raw.sh
# ============================================================

set -euo pipefail

DB_NAME="${DB_NAME:-nafadpay}"
DB_USER="${DB_USER:-admin}"
CONTAINER_NAME="${CONTAINER_NAME:-nafadpay-postgres}"

PSQL="docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1"

echo "=== Loading raw G1 data into staging ==="
echo "Container: $CONTAINER_NAME / DB: $DB_NAME"
echo ""

# ---- users ----
echo "[1/5] Loading staging.users ..."
$PSQL -c "TRUNCATE staging.users;"
$PSQL -c "COPY staging.users (id, nni, first_name, last_name, full_name, gender, birth_date, ethnicity, phone, email, wilaya_id, wilaya_name, moughataa_id, moughataa_name, profile_type, kyc_level, status, device_type, registration_date, last_login, created_at, updated_at) FROM '/workspace/data/G1_OLTP/users_sample.csv' CSV HEADER;"
echo "      Done."

# ---- accounts ----
echo "[2/5] Loading staging.accounts ..."
$PSQL -c "TRUNCATE staging.accounts;"
$PSQL -c "COPY staging.accounts (id, user_id, account_number, account_type, account_type_label, currency, balance, available_balance, daily_limit, monthly_limit, status, is_primary, opened_date, last_activity, created_at, updated_at) FROM '/workspace/data/G1_OLTP/accounts_sample.csv' CSV HEADER;"
echo "      Done."

# ---- merchants ----
echo "[3/5] Loading staging.merchants ..."
$PSQL -c "TRUNCATE staging.merchants;"
$PSQL -c "COPY staging.merchants (id, code, mcc, name, category_code, category_label, owner_first_name, owner_last_name, owner_full_name, owner_gender, owner_ethnicity, phone, email, wilaya_id, wilaya_name, moughataa_id, moughataa_name, address, latitude, longitude, commission_rate, avg_transaction_min, avg_transaction_max, status, registration_date, created_at) FROM '/workspace/data/G1_OLTP/merchants_sample.csv' CSV HEADER;"
echo "      Done."

# ---- agencies ----
echo "[4/5] Loading staging.agencies ..."
$PSQL -c "TRUNCATE staging.agencies;"
$PSQL -c "COPY staging.agencies (id, code, name, wilaya_id, wilaya_name, moughataa_id, moughataa_name, address, latitude, longitude, phone, email, opening_hours, status, tier, float_balance, max_float, license_number, license_expiry, created_at) FROM '/workspace/data/G1_OLTP/agencies_sample.csv' CSV HEADER;"
echo "      Done."

# ---- transactions ----
echo "[5/5] Loading staging.transactions ..."
$PSQL -c "TRUNCATE staging.transactions;"
$PSQL -c "COPY staging.transactions (id, reference, idempotency_key, transaction_type, transaction_type_label, amount, fee, total_amount, currency, source_account_id, source_account_number, source_user_id, source_user_name, destination_account_id, destination_account_number, destination_user_id, destination_user_name, merchant_id, merchant_code, merchant_name, agency_id, agency_code, agency_name, agent_id, agent_name, status, failure_reason, balance_before, balance_after, node_id, processing_node, sequence_number, channel, device_type, ip_address, description, transaction_date, transaction_time, created_at, completed_at) FROM '/workspace/data/G1_OLTP/transactions_sample.csv' CSV HEADER;"
echo "      Done."

echo ""
echo "=== Raw G1 data loaded successfully ==="
echo ""
echo "Row counts:"
$PSQL -c "
SELECT 'staging.users'               AS table_name, COUNT(*) AS rows FROM staging.users
UNION ALL
SELECT 'staging.accounts',                          COUNT(*) FROM staging.accounts
UNION ALL
SELECT 'staging.merchants',                         COUNT(*) FROM staging.merchants
UNION ALL
SELECT 'staging.agencies',                          COUNT(*) FROM staging.agencies
UNION ALL
SELECT 'staging.transactions',                      COUNT(*) FROM staging.transactions
UNION ALL
SELECT 'staging.reference_wilayas',                 COUNT(*) FROM staging.reference_wilayas
UNION ALL
SELECT 'staging.reference_tx_types',                COUNT(*) FROM staging.reference_tx_types
UNION ALL
SELECT 'staging.reference_categories',              COUNT(*) FROM staging.reference_categories
ORDER BY table_name;
"
