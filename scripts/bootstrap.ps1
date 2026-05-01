# ============================================================
# bootstrap.ps1
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
#   .\scripts\bootstrap.ps1
#
# Optional env overrides (set before running):
#   $env:DB_NAME         (default: nafadpay)
#   $env:DB_USER         (default: admin)
#   $env:DB_PASSWORD     (default: nafadpay0001)
#   $env:DB_PORT         (default: 5432)
#   $env:CONTAINER_NAME  (default: nafadpay-postgres)
# ============================================================

$ErrorActionPreference = "Stop"

$env:DB_NAME       = if ($env:DB_NAME)       { $env:DB_NAME }       else { "nafadpay" }
$env:DB_USER       = if ($env:DB_USER)       { $env:DB_USER }       else { "admin" }
$env:DB_PASSWORD   = if ($env:DB_PASSWORD)   { $env:DB_PASSWORD }   else { "nafadpay0001" }
$env:DB_PORT       = if ($env:DB_PORT)       { $env:DB_PORT }       else { "5432" }
$env:CONTAINER_NAME = if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { "nafadpay-postgres" }

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  NAFAD PAY —  Bootstrap" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1 — Start container
Write-Host "[1/5] Starting PostgreSQL container ..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.yml up -d
if ($LASTEXITCODE -ne 0) { throw "Failed to start Docker container" }
Write-Host "      Container started." -ForegroundColor Green
Write-Host ""

# Step 2 — Wait for healthy
Write-Host "[2/5] Waiting for PostgreSQL to be ready ..." -ForegroundColor Yellow
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    docker exec $env:CONTAINER_NAME pg_isready -U $env:DB_USER -d $env:DB_NAME | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        break
    }
    Write-Host "      Not ready yet, retrying ($i/30) ..."
    Start-Sleep -Seconds 2
}
if (-not $ready) {
    throw "PostgreSQL did not become ready in time. Run: docker logs $($env:CONTAINER_NAME)"
}
Write-Host "      PostgreSQL is ready." -ForegroundColor Green
Write-Host ""

# Step 3 — Create schema and tables
Write-Host "[3/5] Creating staging schema and tables ..." -ForegroundColor Yellow
& .\scripts\init_staging.ps1
Write-Host ""

# Step 4 — Load reference data
Write-Host "[4/5] Loading reference data ..." -ForegroundColor Yellow
& .\scripts\load_reference.ps1
Write-Host ""

# Step 5 — Load raw G1 data
Write-Host "[5/5] Loading raw G1 data ..." -ForegroundColor Yellow
& .\scripts\load_raw.ps1
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " bootstrap completed successfully." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
