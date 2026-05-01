Write-Host "Running validation and routing..." -ForegroundColor Cyan

# Reset validation tables (VERY IMPORTANT)
docker exec -i nafadpay-postgres psql -U admin -d nafadpay -c "
TRUNCATE TABLE 
    anomalies.transaction_anomalies, 
    anomalies.idempotency_conflicts, 
    quarantine.quarantine_transactions 
RESTART IDENTITY;
"

# Create schemas and tables
Get-Content sql/anomalies/01_transaction_anomalies.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/anomalies/02_idempotency_conflicts.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/quarantine/01_quarantine_transactions.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/quarantine/02_quarantine_reasons.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

# Insert anomalies
Get-Content sql/anomalies/05_insert_transaction_anomalies.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/anomalies/06_insert_idempotency_conflicts.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

# Insert quarantine
Get-Content sql/quarantine/04_insert_quarantine_transactions.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

# 🔥 STEP 6 — Prepare CORE READY DATA
Get-Content sql/core_ready/01_prepare_core_transactions.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

Write-Host "Validation and core-ready preparation completed." -ForegroundColor Green