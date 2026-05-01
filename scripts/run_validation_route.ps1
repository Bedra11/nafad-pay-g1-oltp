Write-Host "Running validation and routing..." -ForegroundColor Cyan

Get-Content sql/anomalies/01_transaction_anomalies.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/anomalies/02_idempotency_conflicts.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/quarantine/01_quarantine_transactions.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/quarantine/02_quarantine_reasons.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

Get-Content sql/anomalies/05_insert_transaction_anomalies.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/anomalies/06_insert_idempotency_conflicts.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Get-Content sql/quarantine/04_insert_quarantine_transactions.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

Write-Host "Validation completed." -ForegroundColor Green