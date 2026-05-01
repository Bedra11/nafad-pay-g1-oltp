# ============================================================
# load_raw.ps1
#
# Loads G1 raw CSVs into staging tables.
# Uses COPY (server-side) via Docker exec.
# Does NOT require local psql installation.
#
# Philosophy:
#   - Preserves ALL rows exactly as-is
#   - No cleaning, no deduplication, no rejection
#   - Validation and routing happen later in the pipeline
#
# Run AFTER load_reference.ps1.
#
# Usage (from repo root):
#   .\scripts\load_raw.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$DB_NAME   = if ($env:DB_NAME)        { $env:DB_NAME }        else { "nafadpay" }
$DB_USER   = if ($env:DB_USER)        { $env:DB_USER }        else { "admin" }
$CONTAINER = if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { "nafadpay-postgres" }

function Run-PSQL($sql) {
    docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -c $sql
    if ($LASTEXITCODE -ne 0) { throw "psql command failed" }
}

Write-Host "=== Loading raw G1 data into staging ===" -ForegroundColor Cyan
Write-Host "Container: $CONTAINER / DB: $DB_NAME"
Write-Host ""

# ---- users ----
Write-Host "[1/5] Loading staging.users ..."
Run-PSQL "TRUNCATE staging.users;"
Run-PSQL "COPY staging.users (id, nni, first_name, last_name, full_name, gender, birth_date, ethnicity, phone, email, wilaya_id, wilaya_name, moughataa_id, moughataa_name, profile_type, kyc_level, status, device_type, registration_date, last_login, created_at, updated_at) FROM '/workspace/data/G1_OLTP/users_sample.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

# ---- accounts ----
Write-Host "[2/5] Loading staging.accounts ..."
Run-PSQL "TRUNCATE staging.accounts;"
Run-PSQL "COPY staging.accounts (id, user_id, account_number, account_type, account_type_label, currency, balance, available_balance, daily_limit, monthly_limit, status, is_primary, opened_date, last_activity, created_at, updated_at) FROM '/workspace/data/G1_OLTP/accounts_sample.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

# ---- merchants ----
Write-Host "[3/5] Loading staging.merchants ..."
Run-PSQL "TRUNCATE staging.merchants;"
Run-PSQL "COPY staging.merchants (id, code, mcc, name, category_code, category_label, owner_first_name, owner_last_name, owner_full_name, owner_gender, owner_ethnicity, phone, email, wilaya_id, wilaya_name, moughataa_id, moughataa_name, address, latitude, longitude, commission_rate, avg_transaction_min, avg_transaction_max, status, registration_date, created_at) FROM '/workspace/data/G1_OLTP/merchants_sample.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

# ---- agencies ----
Write-Host "[4/5] Loading staging.agencies ..."
Run-PSQL "TRUNCATE staging.agencies;"
Run-PSQL "COPY staging.agencies (id, code, name, wilaya_id, wilaya_name, moughataa_id, moughataa_name, address, latitude, longitude, phone, email, opening_hours, status, tier, float_balance, max_float, license_number, license_expiry, created_at) FROM '/workspace/data/G1_OLTP/agencies_sample.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

# ---- transactions ----
Write-Host "[5/5] Loading staging.transactions ..."
Run-PSQL "TRUNCATE staging.transactions;"
Run-PSQL "COPY staging.transactions (id, reference, idempotency_key, transaction_type, transaction_type_label, amount, fee, total_amount, currency, source_account_id, source_account_number, source_user_id, source_user_name, destination_account_id, destination_account_number, destination_user_id, destination_user_name, merchant_id, merchant_code, merchant_name, agency_id, agency_code, agency_name, agent_id, agent_name, status, failure_reason, balance_before, balance_after, node_id, processing_node, sequence_number, channel, device_type, ip_address, description, transaction_date, transaction_time, created_at, completed_at) FROM '/workspace/data/G1_OLTP/transactions_sample.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

Write-Host ""
Write-Host "=== Raw G1 data loaded successfully ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Row counts:" -ForegroundColor Yellow
Run-PSQL @"
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
"@
