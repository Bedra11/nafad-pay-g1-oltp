# Anomaly & Validation Policy — G1

## 1. Principles

The data pipeline follows these principles:

* staging is exhaustive and preserves all raw data
* core is strict and contains only validated and trusted data
* quarantine stores rows with missing or unresolved references
* anomalies store rows with critical inconsistencies or conflicts

No data is deleted during ingestion. All validation and routing decisions are applied after data is loaded into staging.

---

## 2. Routing Logic

Each row from staging is processed using the following logic:

* valid rows are inserted into core
* rows with missing or invalid references are routed to quarantine
* rows with critical inconsistencies are routed to anomalies

---

## 3. Validation Rules

### 3.1 Anomalies (Critical Errors)

A row is routed to ANOMALIES if:

Règle 1:
IF idempotency_key is duplicated with different payload
→ ANOMALIES
→ reason = idempotency_conflict

Règle 2:
IF status = 'FAILED' AND balance_after != balance_before
→ ANOMALIES
→ reason = invalid_failed_balance

Règle 3:
IF amount <= 0
→ ANOMALIES
→ reason = invalid_amount

Règle 4:
IF balance_after < 0
→ ANOMALIES
→ reason = negative_balance

---

### 3.2 Quarantine (Missing References)

A row is routed to QUARANTINE if:

Règle 5:
IF source_account_id is missing or does not exist
→ QUARANTINE
→ reason = missing_source_account

Règle 6:
IF destination_account_id is required but missing or invalid
→ QUARANTINE
→ reason = missing_destination_account

Règle 7:
IF transaction_type = 'PAY' AND merchant_id IS NULL
→ QUARANTINE
→ reason = missing_merchant

Règle 8:
IF agency_id is required but missing
→ QUARANTINE
→ reason = missing_agency

---

### 3.3 Core (Valid Data)

A row is routed to CORE if:

Règle 9:
IF all required references exist
AND no anomaly condition is triggered
AND all business constraints are satisfied
→ CORE

---

## 4. Data Integrity Policy

* staging data remains unchanged and fully preserved
* quarantine data is stored for traceability and potential correction
* anomaly data is stored for investigation and resolution
* core data is the only trusted dataset for reporting and operations

No automatic correction is applied to anomalous data without explicit business rules.

---

## 5. Summary

The system ensures:

* full preservation of raw data in staging
* strict validation before insertion into core
* clear separation between valid data, recoverable issues, and critical errors
