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

Rule 1:
IF idempotency_key is duplicated with different payload  
→ ANOMALIES  
→ reason = idempotency_conflict  

Rule 2:
IF status = 'FAILED' AND balance_after != balance_before  
→ ANOMALIES  
→ reason = invalid_failed_balance  

Rule 3:
IF amount <= 0  
→ ANOMALIES  
→ reason = invalid_amount  

Rule 4:
IF balance_after < 0  
→ ANOMALIES  
→ reason = negative_balance  

Note:  
A row may have multiple anomaly types if several critical conditions are triggered.

---

### 3.2 Quarantine (Missing References)

A row is routed to QUARANTINE if:

Rule 5:
IF source_account_id is missing or does not exist  
→ QUARANTINE  
→ reason = missing_source_account  

Rule 6:
IF destination_account_id is required but missing or invalid  
→ QUARANTINE  
→ reason = missing_destination_account  

Rule 7:
IF transaction_type = 'PAY' AND merchant_id IS NULL  
→ QUARANTINE  
→ reason = missing_merchant  

Rule 8:
IF agency_id is required but missing  
→ QUARANTINE  
→ reason = missing_agency  

Rule 9:  
IF a required reference does not exist in CORE tables (accounts, merchants, agencies)  
→ QUARANTINE  
→ reason = missing_core_reference  

This validation is applied after loading core parent tables and before inserting into core.transactions.

Reason:  
To prevent foreign key constraint violations and ensure referential integrity in CORE.


---

### 3.3 Core (Valid Data)

A row is routed to CORE if:

Rule 10:
IF all required references exist  
AND no anomaly condition is triggered  
AND all business constraints are satisfied  
→ CORE  

---

### 3.4 Routing Priority (Critical)

To ensure consistency and avoid overlapping classifications, the routing process follows a strict priority order:

1. Anomalies (highest priority)  
2. Quarantine  
3. Core (only if no other condition is met)  

This implies:

* A row classified as anomaly must NOT be inserted into quarantine
* A row classified as anomaly must NOT be inserted into core
* A row classified as idempotency conflict must NOT be inserted into quarantine
* Each row must belong to exactly one final category

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
* deterministic routing with no overlap between anomalies, quarantine, and core