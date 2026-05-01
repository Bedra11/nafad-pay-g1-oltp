\echo 'Running anomaly and quarantine routing...'

\i sql/anomalies/01_transaction_anomalies.sql
\i sql/anomalies/02_idempotency_conflicts.sql
\i sql/quarantine/01_quarantine_transactions.sql
\i sql/quarantine/02_quarantine_reasons.sql

\i sql/anomalies/05_insert_transaction_anomalies.sql
\i sql/anomalies/06_insert_idempotency_conflicts.sql
\i sql/quarantine/04_insert_quarantine_transactions.sql

\echo 'Validation and routing completed.'