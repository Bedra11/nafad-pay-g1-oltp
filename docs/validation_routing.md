# Validation & Routing — Member 3 Recap (G1 OLTP)

## Objective

The goal of this work is to implement a validation and routing system that processes data from the staging layer and routes each transaction into one of the following categories:

- ANOMALIES (critical errors)
- QUARANTINE (missing references)
- CORE (valid data, prepared but not inserted)

The system follows strict principles:

- staging is exhaustive (no data loss)
- core is strict and trusted
- no row belongs to more than one category

---

## Global Logic

### Routing Rules

IF anomaly → ANOMALIES  
ELSE IF missing reference → QUARANTINE  
ELSE → CORE  

### Priority

ANOMALIES > QUARANTINE > CORE  

This ensures:

- no overlap between tables
- deterministic routing
- clean data for CORE

---

## Files Created and Their Purpose

### 1. Documentation

File: docs/anomaly_pipeline.md

Purpose:

- define all validation rules
- explain routing logic
- document priority rules
- provide reference for Go pipeline and CORE validation

Why it was created:

to clearly explain how and why data is classified

---

### 2. SQL — ANOMALIES

File: sql/anomalies/01_transaction_anomalies.sql  
Creates table: anomalies.transaction_anomalies

File: sql/anomalies/02_idempotency_conflicts.sql  
Creates table: anomalies.idempotency_conflicts

File: sql/anomalies/03_detect_transaction_anomalies.sql  

Purpose:

- detect anomalies from staging:
  - amount ≤ 0  
  - invalid balance after FAILED  
  - negative balance  

Why:

to separate detection logic from insertion (clean architecture)

File: sql/anomalies/04_detect_idempotency_conflicts.sql  

Purpose:

- detect duplicate idempotency_key with different payload

File: sql/anomalies/05_insert_transaction_anomalies.sql  

Purpose:

- insert detected anomalies into final table

File: sql/anomalies/06_insert_idempotency_conflicts.sql  

Purpose:

- insert detected idempotency conflicts

---

### 3. SQL — QUARANTINE

File: sql/quarantine/01_quarantine_transactions.sql  
Creates table: quarantine.quarantine_transactions

File: sql/quarantine/02_quarantine_reasons.sql  

Purpose:

- store rejection reasons

File: sql/quarantine/03_detect_quarantine_transactions.sql  

Purpose:

- detect rows with missing references:
  - source_account missing  
  - destination_account missing  
  - merchant missing  

File: sql/quarantine/04_insert_quarantine_transactions.sql  

Purpose:

- insert detected quarantine rows

Important logic:

- exclude anomalies  
- exclude idempotency_conflicts  

Why:

to ensure no overlap between tables

---

### 4. Execution Files

File: validation_route.sql  

Purpose:

- central SQL orchestrator
- defines execution order of validation logic
- calls anomaly and quarantine scripts

File: scripts/run_validation_route.ps1  
File: scripts/run_validation_route.sh  

Purpose:

- execute full validation pipeline
- reset tables before execution (TRUNCATE)
- run all SQL files in correct order

Why:

- automation  
- reproducibility  
- clean execution  

---

## Execution Commands

Run pipeline (Windows):

```powershell
.\scripts\run_validation_route.ps1

Run pipeline (Linux / EC2):

bash scripts/run_validation_route.sh
Validation Tests

File: sql/tests/01_validation_routing_checks.sql

Purpose:

verify row counts
verify anomaly classification
verify quarantine classification
verify absence of overlap
verify rule correctness

Run tests:

Get-Content sql/tests/01_validation_routing_checks.sql -Raw | docker exec -i nafadpay-postgres psql -U admin -d nafadpay -f -
Results Obtained
Data Volume

staging.transactions = 10000

Anomalies

transaction_anomalies = 52
idempotency_conflicts = 6416

Quarantine

quarantine_transactions = 3504

Critical Validations
overlap anomalies/quarantine = 0
overlap idempotency/quarantine = 0
invalid_amount: valid
invalid_failed_balance: valid
negative_balance: valid
missing_source_account: valid
missing_destination_account: valid
Note

16 transactions have multiple anomalies.

This is allowed because one transaction can contain multiple critical issues.