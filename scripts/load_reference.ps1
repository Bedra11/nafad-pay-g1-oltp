# ============================================================
# load_reference.ps1
#
# Loads shared reference CSVs into staging reference tables.
# Uses COPY (server-side) via Docker exec.
# Does NOT require local psql installation.
#
# Run AFTER init_staging.ps1 and BEFORE load_raw.ps1.
#
# Usage (from repo root):
#   .\scripts\load_reference.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$DB_NAME   = if ($env:DB_NAME)        { $env:DB_NAME }        else { "nafadpay" }
$DB_USER   = if ($env:DB_USER)        { $env:DB_USER }        else { "admin" }
$CONTAINER = if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { "nafadpay-postgres" }

function Run-PSQL($sql) {
    docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -c $sql
    if ($LASTEXITCODE -ne 0) { throw "psql command failed" }
}

Write-Host "=== Loading reference data into staging ===" -ForegroundColor Cyan
Write-Host "Container: $CONTAINER / DB: $DB_NAME"
Write-Host ""

# ---- reference_wilayas ----
Write-Host "[1/3] Loading staging.reference_wilayas ..."
Run-PSQL "TRUNCATE staging.reference_wilayas;"
Run-PSQL "COPY staging.reference_wilayas (id, code, name, capital, latitude, longitude, population, economic_weight) FROM '/workspace/data/shared/reference_wilayas.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

# ---- reference_tx_types ----
Write-Host "[2/3] Loading staging.reference_tx_types ..."
Run-PSQL "TRUNCATE staging.reference_tx_types;"
Run-PSQL "COPY staging.reference_tx_types (id, code, label, description, requires_destination, requires_merchant, requires_agency, is_credit) FROM '/workspace/data/shared/reference_tx_types.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

# ---- reference_categories ----
Write-Host "[3/3] Loading staging.reference_categories ..."
Run-PSQL "TRUNCATE staging.reference_categories;"
Run-PSQL "COPY staging.reference_categories (id, code, mcc, label, description, avg_min, avg_max) FROM '/workspace/data/shared/reference_categories.csv' CSV HEADER;"
Write-Host "      Done." -ForegroundColor Green

Write-Host ""
Write-Host "=== Reference data loaded successfully ===" -ForegroundColor Cyan
