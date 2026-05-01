# ============================================================
# init_staging.ps1
#
# Creates the staging schema and all staging tables
# by piping SQL files into the running Docker container.
# Does NOT require local psql installation.
#
# Run AFTER the container is up. BEFORE load_reference.ps1.
#
# Usage (from repo root):
#   .\scripts\init_staging.ps1
# ============================================================

$ErrorActionPreference = "Stop"

$DB_NAME       = if ($env:DB_NAME)       { $env:DB_NAME }       else { "nafadpay" }
$DB_USER       = if ($env:DB_USER)       { $env:DB_USER }       else { "admin" }
$CONTAINER     = if ($env:CONTAINER_NAME){ $env:CONTAINER_NAME } else { "nafadpay-postgres" }

$files = @(
    "sql\staging\00_staging_schema.sql",
    "sql\staging\01_stg_users.sql",
    "sql\staging\02_stg_accounts.sql",
    "sql\staging\03_stg_merchants.sql",
    "sql\staging\04_stg_agencies.sql",
    "sql\staging\05_stg_transactions.sql",
    "sql\staging\06_stg_reference_wilayas.sql",
    "sql\staging\07_stg_reference_tx_types.sql",
    "sql\staging\08_stg_reference_categories.sql"
)

Write-Host "=== Creating staging schema and tables ===" -ForegroundColor Cyan
Write-Host "Container: $CONTAINER / DB: $DB_NAME / User: $DB_USER"
Write-Host ""

foreach ($file in $files) {
    Write-Host "  Running $file ..."
    Get-Content $file -Raw | docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=1 -f -
    if ($LASTEXITCODE -ne 0) { throw "Failed running $file" }
    Write-Host "  Done." -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Staging schema created successfully ===" -ForegroundColor Cyan
