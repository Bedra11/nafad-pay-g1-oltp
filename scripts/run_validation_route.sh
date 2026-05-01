#!/bin/bash

echo "Running validation and routing..."

# Reset validation tables (VERY IMPORTANT)
docker exec -i nafadpay-postgres psql -U admin -d nafadpay -c "TRUNCATE TABLE anomalies.transaction_anomalies, anomalies.idempotency_conflicts, quarantine.quarantine_transactions RESTART IDENTITY;"

# Create schemas and tables
cat sql/anomalies/01_transaction_anomalies.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
cat sql/anomalies/02_idempotency_conflicts.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
cat sql/quarantine/01_quarantine_transactions.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
cat sql/quarantine/02_quarantine_reasons.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

# Insert data
cat sql/anomalies/05_insert_transaction_anomalies.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
cat sql/anomalies/06_insert_idempotency_conflicts.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
cat sql/quarantine/04_insert_quarantine_transactions.sql | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -

echo "Validation completed."