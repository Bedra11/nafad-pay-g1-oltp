# G1 OLTP — Exploration Notes, Open Questions, and Modeling Trade-offs

This document is a working summary of our first exploration pass on the G1 OLTP dataset.  
It is **not** intended as a final design decision document yet. The goal here is to:

- summarize what we observed from profiling and checks
- highlight the anomalies we confirmed by code
- point out things that seem unclear or suspicious
- list the main trade-offs before we freeze the relational model
- identify where we may need confirmation or guidance

At this stage, we are trying to understand the data deeply enough to make good schema decisions, instead of forcing early constraints and then discovering later that the raw data does not really fit them.

---

## 1. What we understand so far about the dataset

At a high level, the dataset is clearly organized around these business entities:

- `users`
- `accounts`
- `transactions`
- `merchants`
- `agencies`
- reference tables:
  - `reference_categories`
  - `reference_tx_types`
  - `reference_wilayas`

This part seems stable and understandable. The data has enough structure for a proper relational model.

### Why we think these are real entities
Each of these tables has:
- its own `id`
- its own descriptive fields
- its own business meaning
- values that look intended to be reused from one table to another

For example:
- `accounts` clearly points to `users`
- `transactions` clearly points to accounts, users, merchants, and agencies
- `merchants` and `transactions` share category / transaction semantics
- several tables carry a `wilaya_id`, which strongly suggests a shared geographic reference model

So even though the raw data is imperfect, the business structure itself is clear.

---

## 2. First impression from profiling

The profiling gave us two very different impressions at once:

### On one side, a lot of the structure is clean
Some columns look very strong:
- all `id` columns are filled
- all main tables have stable row counts and consistent headers
- some business identifiers are clean and unique
- transaction types match the transaction-type reference file
- merchant categories match the category reference file

### On the other side, some columns look partially generated, incomplete, or non-authoritative
We found several columns that are:
- 100% empty
- filled with `NaN`
- sometimes containing `undefined ...` in text values
- possibly descriptive only, not reliable enough to drive integrity

This suggests that not every column should be treated as equally trustworthy.

The profiling confirms that the dataset is **usable**, but not in a “load directly into strict final tables” way. :contentReference[oaicite:0]{index=0}

---

## 3. What looks strong enough to support keys and relationships

### 3.1 Candidate primary keys
The `id` columns look like the best primary key candidates in all major tables:

- `users.id`
- `accounts.id`
- `transactions.id`
- `merchants.id`
- `agencies.id`
- reference table `id`s

They are non-empty and unique in our duplicate checks.

### Why this matters
Using technical IDs as PKs gives us:
- stable joins
- simpler foreign key design
- less dependence on business fields that may later need cleaning

So for now, the `id` fields look safe as technical primary keys.

---

## 4. Business identifiers: strong, weak, and questionable

### 4.1 Very strong business identifiers
Some columns look strong enough to become `UNIQUE` constraints later, at least in the cleaned core model:

- `users.nni`
- `accounts.account_number`
- `merchants.code`
- `agencies.code`
- `reference_categories.code`
- `reference_tx_types.code`
- `reference_wilayas.code`

These are all non-empty and unique in the current exploration.

### 4.2 Phone is more ambiguous than expected
`users.phone` has valid format everywhere, but it is **not unique**:
- 5 duplicate keys
- 10 affected rows

This is interesting because it shows an important distinction:
- **format-valid** does not mean **identity-valid**

So phone looks useful, but maybe not strong enough to be the sole unique user identifier without cleanup.

### 4.3 Transactions have the most problematic business keys
Two columns stand out immediately:

- `transactions.reference`
- `transactions.idempotency_key`

Both look like fields that, conceptually, should be unique in a payment system.  
But in the raw data they are not:

- `reference`: 3 duplicate keys, 6 rows affected
- `idempotency_key`: 2,682 duplicate keys, 6,416 rows affected

Even more importantly:
- 3 duplicated references have **different amounts**
- 3,710 duplicated idempotency keys have **different payloads**

This is much more serious than “some duplicates exist.” It means some duplicates may represent actual conflicts, not harmless retries.

### Open question
For the final model, should we:
1. enforce uniqueness only after cleaning and conflict resolution,
2. keep all raw duplicates in staging,
3. or preserve conflicting cases in quarantine only?

At the moment, we strongly feel that raw ingestion and final-core constraints must be separated.

---

## 5. Foreign-key candidates and one important mapping issue

### 5.1 Logical foreign keys that seem natural
The following relationships look very plausible:

- `accounts.user_id -> users.id`
- `transactions.source_user_id -> users.id`
- `transactions.destination_user_id -> users.id`
- `transactions.source_account_id -> accounts.id`
- `transactions.destination_account_id -> accounts.id`
- `transactions.merchant_id -> merchants.id`
- `transactions.agency_id -> agencies.id`

These look like the expected core relationships of the system.

### 5.2 Reference-table relationships that seem strong
Two reference links look clean:

- `transactions.transaction_type -> reference_tx_types.code`
- `merchants.category_code -> reference_categories.code`

These both validated well in our checks.

### 5.3 Wilaya reference validation

After the reference check logic, the wilaya fields  validate cleanly in all three business tables.

The checks show:

- `users.wilaya_id -> reference_wilayas.id`: 0 invalid
- `users.wilaya_name -> reference_wilayas.name`: 0 invalid
- `agencies.wilaya_id -> reference_wilayas.id`: 0 invalid
- `agencies.wilaya_name -> reference_wilayas.name`: 0 invalid
- `merchants.wilaya_id -> reference_wilayas.id`: 0 invalid
- `merchants.wilaya_name -> reference_wilayas.name`: 0 invalid

We also added a stronger row-level consistency check, comparing `wilaya_id` and `wilaya_name` together against the reference table (`reference_wilayas.id -> name`). That check also returned 0 invalid rows for `users`, `agencies`, and `merchants`.

### What this means
At this point, the geography reference looks clean and internally coherent:

- `wilaya_id` exists in the official wilaya reference table
- `wilaya_name` exists in the official wilaya reference table
- the `wilaya_id` and `wilaya_name` values match each other row by row



### Modeling implication
This gives us much more confidence in the geographic part of the schema.

The most reasonable normalized interpretation now seems to be:

- `users.wilaya_id -> reference_wilayas.id`
- `agencies.wilaya_id -> reference_wilayas.id`
- `merchants.wilaya_id -> reference_wilayas.id`

In other words, `wilaya_id` looks like the authoritative relational field, while `wilaya_name` looks like a redundant descriptive field that can be derived from the reference table in the normalized core model.

### Remaining trade-off
The main remaining design choice is not whether the wilaya reference is valid, but whether to keep both fields in the final model:

#### Option A — keep only `wilaya_id` in the normalized core
Pros:
- avoids duplication
- keeps one source of truth
- more consistent with 3NF design

Cons:
- requires a join to display the name

#### Option B — keep both `wilaya_id` and `wilaya_name` in the core
Pros:
- simpler direct reads
- easier display without joins

Cons:
- duplicates the same information
- creates risk of future inconsistency if both fields diverge later

#### At this stage, the data quality results clearly support `wilaya_id` as a foreign key. The main open question is therefore a design trade-off about normalization and convenience, not a data-quality problem.
---

## 6. Nullable fields: where the data suggests optionality

One major lesson from the profiling is that some fields are clearly optional, not globally mandatory.

### 6.1 `users.email`
`email` is empty on 59.3% of rows.

So unless we are expected to force an email-based design, this field looks optional in practice.

### 6.2 Transaction destination fields
The following are empty on 53.66% of rows:

- `destination_account_id`
- `destination_account_number`
- `destination_user_id`
- `destination_user_name`

This suggests that many transaction types do not need a destination in the same way a transfer would.

### 6.3 Merchant / agency / agent fields
These are even more sparse:

- `merchant_*`: around 86.3% empty
- `agency_*` / `agent_*`: around 68.5% empty

This does **not automatically mean bad data**. It may simply mean:
- some transaction types are merchant-related
- some are agency-related
- some are direct transfers
- some are wallet-only operations

### Trade-off
We see two possible directions:

#### Option A — keep many transaction columns nullable
Pros:
- easier to fit the raw data
- closer to the actual operational diversity of transaction types

Cons:
- weakens strictness
- makes some invariants less obvious

#### Option B — split transactions into more specialized subtypes or business rules
Pros:
- cleaner semantics
- stricter per-type validation

Cons:
- more complex schema
- maybe too heavy for this project stage

At this point, we are leaning toward nullable fields plus per-type validation rules, but we do not want to finalize that yet without more discussion.

---

## 7. Columns that look empty, low-value, or suspicious

### 7.1 100% empty columns
We found several fields that are completely empty:

- `users.moughataa_name`
- `users.kyc_level`
- `accounts.account_type_label`
- `transactions.transaction_type_label`
- `merchants.category_label`
- `merchants.moughataa_name`
- `agencies.moughataa_name`
- `reference_categories.label`
- `reference_categories.description`
- `reference_tx_types.label`
- `reference_tx_types.description`
- `reference_wilayas.latitude`
- `reference_wilayas.longitude`

### What this suggests
These fields probably should not be central in the first version of the relational model.

At minimum:
- they should not drive key design
- they should not be used for mandatory constraints
- several can probably be excluded from the first clean core schema

### 7.2 `NaN` coordinates
In both `merchants` and `agencies`, latitude/longitude appear filled but are effectively unusable because the values are `NaN`.

So these fields are not truly populated for practical purposes.

### 7.3 Text fields containing `undefined ...`
We noticed suspicious values like:
- merchant names beginning with `undefined`
- agency addresses containing `undefined`

This makes us hesitant to treat these text fields as authoritative.

### Open question
Should these text fields:
- be kept as descriptive raw attributes only,
- be cleaned into canonical values,
- or be partially ignored in the core model?

We are leaning toward keeping them in staging/raw and only selectively promoting trusted fields into core.

---

## 8. Orphans: one of the biggest structural issues

This was one of the clearest findings in the whole exploration.

### Measured orphan counts in transactions
- `source_user_id`: 2,110
- `destination_user_id`: 2,273
- `source_account_id`: 2,110
- `destination_account_id`: 2,273
- `merchant_id`: 1,115
- `agency_id`: 1,674

These are high numbers.

### Why this is important
If we enforce all foreign keys directly at load time into final tables, a large share of the transaction data will fail to load.

### Trade-off
#### Strict core from the start
Pros:
- very clean final database
- strong integrity guarantees

Cons:
- massive rejection rate
- risk of losing too much raw evidence

#### Staging + quarantine + clean core
Pros:
- preserves raw data
- allows investigation
- cleaner audit trail
- realistic for messy operational data

Cons:
- more work
- introduces a pipeline instead of a single load step

At this point, the second option seems much more realistic.

### Question
Would you prefer us to:
- reject all invalid transaction rows from the final model,
- keep them in quarantine with reject reasons,
- or preserve some “partial” transactions if the missing references are business-optional?

---

## 9. Business-rule anomalies confirmed by code

This part feels especially important because it affects whether the data can support a core banking model safely.

### 9.1 Failed transaction invariant
Rule checked:
- `FAILED => balance_before == balance_after`

Result:
- **28 violations**

### Why we think this matters
A failed transaction should normally not change money state.  
If the balance changes anyway, then either:
- the transaction is not really failed,
- or the balance columns are wrong,
- or the data is intentionally showing corruption/anomaly cases

This seems serious enough that those rows should probably not enter a trusted financial ledger table unchanged.

---

### 9.2 Negative amounts
Rule checked:
- `amount > 0`

Result:
- **5 violations**

This is another important case.  
If transaction direction is supposed to be represented by transaction type, then negative amounts create ambiguity and probably should be treated as invalid.

---

### 9.3 Negative `balance_after`
Rule checked:
- `balance_after >= 0`

Result:
- **19 violations**

This suggests that some transactions produce impossible account states, unless the dataset intentionally includes overdraft-like behavior that is not documented.

Right now, we are treating these as strong anomalies.

---

### 9.4 Timestamp ordering
Rule checked:
- `completed_at >= created_at`

Result:
- **6 violations**

This might reflect:
- clock skew
- bad synthetic generation
- or cross-node timing anomalies

Not huge in volume, but definitely worth documenting.

---

### 9.5 Duplicate idempotency keys with conflicting payloads
Rule checked:
- same `idempotency_key` with different payload

Result:
- **3,710 violations**

This is one of the strongest findings in the entire exploration.

In a payment system, idempotency is supposed to prevent duplicate execution of the same request.  
If the same idempotency key appears with different values, then we are no longer looking at a harmless retry. We may be looking at:
- collisions
- simulated replay anomalies
- or a deliberately broken idempotency mechanism

### Why we do not want to make a rushed decision here
If we simply pick one row and discard the others, we may hide exactly the anomaly the dataset wants us to study.

So this feels like a place where we should be careful and maybe ask for clarification on the intended treatment.

---

### 9.6 Duplicate references with conflicting amounts
Rule checked:
- same `reference` with different amount

Result:
- **3 violations**

Lower volume than idempotency conflicts, but conceptually also very serious.  
A business reference should normally not point to several different transaction meanings.

---

## 10. Additional anomalies discovered beyond the obvious ones

We also found issues that were not just “the classic expected anomalies.”

### 10.1 NNI validity problem
Format rule:
- NNI must be 10 digits

Result:
- **5 invalid values**, containing masked characters like `XX`

So `nni` is unique, but not always cleanly valid.

This is useful because it reminds us that:
- uniqueness != correctness

### 10.2 Phone duplicates despite valid format
All phones match the expected `+222XXXXXXXX` pattern, but some are duplicated.

Again:
- format-valid != identity-valid

### 10.3 Future-looking dates
Some profiled columns extend unexpectedly far into the future:
- `users.registration_date` up to 2035
- `transactions.created_at` up to 2035

This may just be part of the synthetic dataset, but it stood out enough that we thought it was worth recording.

### 10.4 Reference metadata looks incomplete
The reference tables themselves have many empty descriptive fields:
- labels/descriptions empty
- all boolean-like flags in `reference_tx_types` constant as `false`

That makes the references usable as code sets, but not yet rich enough to drive advanced business rules without interpretation.

### Question
Are those reference tables intended only as code dictionaries, or should we also rely on them for transaction-behavior logic?

---

## 11. What all this suggests about modeling — without locking the decision yet

At this point, we do **not** want to claim “this is the final model.”  
But the exploration does suggest some likely directions.

### 11.1 We probably need at least two layers, maybe three
The raw data seems too inconsistent to load directly into a strict final schema.

So a layered approach seems more appropriate:

- raw/staging tables
- validated core tables
- possibly quarantine/rejected rows

### Why this seems reasonable
It allows us to:
- preserve the original CSV evidence
- analyze anomalies instead of silently dropping them
- still design a trustworthy final relational core

### 11.2 We probably should not promote every column into the first core schema
Some columns look:
- empty
- descriptive only
- partially generated
- untrustworthy as authoritative values

So the first core version may need to be more conservative than the raw CSVs.

### 11.3 Constraints may need to be phased
Some constraints look safe early:
- PKs on IDs
- some `UNIQUE`s on clean code fields

Some constraints look unsafe on raw data:
- `UNIQUE(idempotency_key)`
- `UNIQUE(reference)`
- full transaction FK enforcement
- broad `NOT NULL` on all transaction-party columns

This makes us think that constraint design should follow the pipeline stage, not be applied uniformly from the beginning.

---

## 12. Main trade-offs we see right now

### Trade-off A — strictness vs preserving evidence
If we make the final schema strict immediately:
- we get strong integrity
- but we reject a lot of rows

If we keep everything permissive:
- we preserve evidence
- but we lose trust in the core tables

### Trade-off B — one transaction table vs more specialized structure
A single wide transaction table is simpler.
But the sparsity patterns suggest that different transaction types may not share all the same fields meaningfully.

### Trade-off C — deduplicate aggressively vs preserve anomalies
For `reference` and `idempotency_key`, deduplicating too early may hide important anomalies.
Preserving all rows forever in the core, however, weakens the meaning of those business identifiers.


---

## 13. Where we would especially appreciate guidance

These are the points where we feel a short confirmation from the professor could save us from choosing the wrong interpretation:


1. **Handling of orphan transactions**
   - Is quarantine the expected strategy, or should some partial rows remain in the modeled dataset?

2. **Treatment of conflicting idempotency keys**
   - Should we preserve all conflicts for study, or resolve them into a canonical transaction representation?

4. **Meaning of duplicate references**
   - Should we treat them as hard errors, synthetic test cases, or evidence of replay/collision scenarios?

5. **Expected strictness of the final OLTP core**
   - Is the main goal a very strict “production-like” core, or a realistic model that still exposes raw distributed-system anomalies?

---

## 14. Current takeaway

Our current takeaway is not “the model is decided,” but rather:

- the business entities are clear
- the raw data is structured enough for a good relational design
- several fields are strong enough for keys and references
- but the transaction dataset is too anomaly-heavy to be loaded directly into a final strict schema
- some anomalies look like true data-quality issues

