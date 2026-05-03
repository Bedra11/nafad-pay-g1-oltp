package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"time"
)

// ── helpers ──────────────────────────────────────────────────────────────────

func runSQLFile(path string) error {
	sql, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("cannot read file %s: %w", path, err)
	}

	cmd := exec.Command(
		"docker", "exec", "-i",
		"nafadpay-postgres",
		"psql", "-U", "admin", "-d", "nafadpay",
		"-v", "ON_ERROR_STOP=1",
		"-f", "-",
	)
	cmd.Stdin = bytes.NewReader(sql)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	fmt.Printf("  → Running file : %s\n", path)
	return cmd.Run()
}

func runSQLCommand(label, command string) error {
	cmd := exec.Command(
		"docker", "exec", "-i",
		"nafadpay-postgres",
		"psql", "-U", "admin", "-d", "nafadpay",
		"-v", "ON_ERROR_STOP=1",
		"-c", command,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	fmt.Printf("  → Running SQL  : %s\n", label)
	return cmd.Run()
}

func section(title string) {
	fmt.Printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	fmt.Printf("  %s\n", title)
	fmt.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
}

func fatal(msg string, err error) {
	fmt.Printf("\n[FATAL] %s: %v\n", msg, err)
	os.Exit(1)
}

func mustRunFile(path string) {
	if err := runSQLFile(path); err != nil {
		fatal("file failed: "+path, err)
	}
}

func mustRunSQL(label, sql string) {
	if err := runSQLCommand(label, sql); err != nil {
		fatal("SQL failed: "+label, err)
	}
}

// ── main ─────────────────────────────────────────────────────────────────────

func main() {
	start := time.Now()
	fmt.Println("╔══════════════════════════════════════════════════════╗")
	fmt.Println("║     NAFAD-PAY G1 OLTP — Full Pipeline Runner        ║")
	fmt.Println("╚══════════════════════════════════════════════════════╝")

	// ── STEP 1 : Create all schemas and tables ────────────────────────────────
	section("STEP 1 — DDL: create schemas & tables")
	// Order matters: reference → staging → core (parents before children)
	// → anomalies → quarantine → core_ready
	// transactions table must come AFTER users, accounts, merchants, agencies
	// because it holds FK references to all of them.
	for _, f := range []string{
		"sql/reference/01_reference_schema.sql",

		"sql/core/01_core_users.sql",
		"sql/core/02_core_accounts.sql",
		"sql/core/04_core_merchants.sql",
		"sql/core/05_core_agencies.sql",
		"sql/core/03_core_transactions.sql", // LAST: has FK to all of the above

		"sql/anomalies/01_transaction_anomalies.sql",
		"sql/anomalies/02_idempotency_conflicts.sql",
		"sql/quarantine/01_quarantine_transactions.sql",
		"sql/quarantine/02_quarantine_reasons.sql",
	} {
		mustRunFile(f)
	}

	// ── STEP 2 : Reset — wipe ALL tables for a fully clean re-run ───────────
	section("STEP 2 — Reset: truncate all tables including reference.*")
	// reference.* MUST be included here.
	// Without it, a second run crashes with:
	//   "duplicate key value violates unique constraint wilayas_pkey"
	// because reference data was inserted in the previous run and
	// ON CONFLICT DO NOTHING only prevents the error — it does not
	// refresh stale data. Wiping + reloading is the correct pattern
	// for a fully reproducible pipeline.
	//
	// CASCADE propagates the truncate through all FK chains automatically,
	// so order within the list does not matter here.
	mustRunSQL("truncate all tables (reference + core + pipeline)", `
TRUNCATE TABLE
    reference.wilayas,
    reference.tx_types,
    reference.categories,
    core.transactions,
    core.accounts,
    core.merchants,
    core.agencies,
    core.users,
    anomalies.transaction_anomalies,
    anomalies.idempotency_conflicts,
    quarantine.quarantine_transactions,
    quarantine.quarantine_reasons
RESTART IDENTITY CASCADE;
`)

	// ── STEP 3 : Load reference tables from staging ───────────────────────────
	section("STEP 3 — Reference: populate reference.* from staging")
	// reference.* was just TRUNCATEd above, so there can be no conflicts.
	// We do NOT use ON CONFLICT here on purpose: if a duplicate appears
	// it means the staging data itself is broken and we want to know.
	// NULLIF handles empty-string CSV nulls that psql COPY loads as ''.
	mustRunSQL("load reference.wilayas", `
INSERT INTO reference.wilayas
    (id, code, name, capital, latitude, longitude, population, economic_weight)
SELECT
    id::integer,
    code,
    name,
    capital,
    NULLIF(latitude,        '')::numeric,
    NULLIF(longitude,       '')::numeric,
    NULLIF(population,      '')::integer,
    NULLIF(economic_weight, '')::numeric
FROM staging.reference_wilayas;
`)

	mustRunSQL("load reference.tx_types", `
INSERT INTO reference.tx_types
    (id, code, label, description,
     requires_destination, requires_merchant, requires_agency, is_credit)
SELECT
    id::integer,
    code,
    label,
    description,
    NULLIF(requires_destination, '')::boolean,
    NULLIF(requires_merchant,    '')::boolean,
    NULLIF(requires_agency,      '')::boolean,
    NULLIF(is_credit,            '')::boolean
FROM staging.reference_tx_types;
`)

	mustRunSQL("load reference.categories", `
INSERT INTO reference.categories
    (id, code, mcc, label, description, avg_min, avg_max)
SELECT
    id::integer,
    code,
    NULLIF(mcc, '')::integer,
    label,
    description,
    NULLIF(avg_min, '')::numeric,
    NULLIF(avg_max, '')::numeric
FROM staging.reference_categories;
`)

	// Quick sanity check — fail fast if reference counts are wrong
	mustRunSQL("verify reference row counts", `
DO $$
DECLARE
    w integer; t integer; c integer;
BEGIN
    SELECT COUNT(*) INTO w FROM reference.wilayas;
    SELECT COUNT(*) INTO t FROM reference.tx_types;
    SELECT COUNT(*) INTO c FROM reference.categories;
    IF w <> 15 THEN RAISE EXCEPTION 'reference.wilayas has % rows, expected 15', w; END IF;
    IF t <> 8  THEN RAISE EXCEPTION 'reference.tx_types has % rows, expected 8',  t; END IF;
    IF c <> 13 THEN RAISE EXCEPTION 'reference.categories has % rows, expected 13', c; END IF;
    RAISE NOTICE 'reference tables OK: wilayas=%, tx_types=%, categories=%', w, t, c;
END $$;
`)

	// ── STEP 4 : Anomaly detection ────────────────────────────────────────────
	section("STEP 4 — Anomalies: flag bad rows before loading core")
	// Idempotency conflicts and balance-anomaly transactions are identified
	// here so they can be excluded from all downstream inserts.
	for _, f := range []string{
		"sql/anomalies/05_insert_transaction_anomalies.sql",
		"sql/anomalies/06_insert_idempotency_conflicts.sql",
	} {
		mustRunFile(f)
	}

	// ── STEP 5 : Quarantine — staging-level orphans ───────────────────────────
	section("STEP 5 — Quarantine: isolate orphan & anomaly rows from staging")
	// Rows with broken source/destination references, negative amounts on
	// SUCCESS, or idempotency duplicates go here before any core insert.
	mustRunFile("sql/quarantine/04_insert_quarantine_transactions.sql")

	// ── STEP 6 : Load core dimension tables (parents first) ───────────────────
	section("STEP 6 — Core load: insert users → accounts → merchants → agencies")
	// FK dependency order: users must exist before accounts (user_id FK).
	// merchants and agencies are independent of each other but both
	// depend on reference.wilayas (wilaya_id FK) loaded in step 3.
	for _, f := range []string{
		"sql/core_load/01_insert_core_users.sql",
		"sql/core_load/02_insert_core_accounts.sql",
		"sql/core_load/03_insert_core_merchants.sql",
		"sql/core_load/04_insert_core_agencies.sql",
	} {
		mustRunFile(f)
	}

	// ── STEP 7 : Quarantine — core-reference orphans ─────────────────────────
	section("STEP 7 — Quarantine: isolate rows whose FK targets are not in core")
	// A second quarantine pass after core dimensions are loaded:
	// transactions whose source_account_id or destination_account_id
	// didn't make it into core.accounts are quarantined here.
	mustRunFile("sql/quarantine/05_insert_core_reference_quarantine.sql")

	// ── STEP 8 : Populate quarantine_reasons ─────────────────────────────────
	section("STEP 8 — Quarantine reasons: populate reason code catalogue")
	// quarantine.quarantine_reasons is a LOOKUP TABLE (reason_code PK,
	// description). It stores the catalogue of possible rejection reasons,
	// not one row per quarantined transaction.
	// The link to individual transactions lives in
	// quarantine.quarantine_transactions.reason_code (FK → here).
	// We insert all distinct reason codes that actually appear in the
	// quarantine table so the catalogue is always in sync with reality.
	mustRunSQL("populate quarantine_reasons catalogue", `
INSERT INTO quarantine.quarantine_reasons (reason_code, description)
VALUES
    ('IDEMPOTENCY_DUPLICATE',    'idempotency_key appears more than once in staging — only the first occurrence is kept'),
    ('BALANCE_ANOMALY',          'FAILED transaction has balance_before ≠ balance_after — invariant violation, data bug'),
    ('ORPHAN_SOURCE_ACCOUNT',    'source_account_number not present in core.accounts — user or account was filtered out'),
    ('ORPHAN_DESTINATION',       'destination_account_number not present in core.accounts — counterparty was filtered out'),
    ('NEGATIVE_AMOUNT',          'amount ≤ 0 after ABS cast — invalid monetary value'),
    ('MISSING_SOURCE',           'source_account_number is NULL or empty — cannot route the transaction'),
    ('CORE_REF_NOT_FOUND',       'transaction passed staging checks but FK target disappeared after core dimension load')
ON CONFLICT (reason_code) DO UPDATE
    SET description = EXCLUDED.description;
`)

	// ── STEP 9 : Prepare and insert core.transactions ─────────────────────────
	section("STEP 9 — Core transactions: prepare clean set then insert")
	// core_ready is a staging view / temp table of transactions that passed
	// all filters. It is prepared first (deduplicated, type-cast, validated)
	// then inserted into core.transactions in one atomic step.
	for _, f := range []string{
		"sql/core_ready/01_prepare_core_transactions.sql",
		"sql/core_ready/02_insert_core_transactions.sql",
	} {
		mustRunFile(f)
	}

	// ── STEP 10 : Fix merchant names (undefined prefix) ───────────────────────
	section("STEP 10 — Data quality: fix 'undefined' merchant name prefix")
	mustRunSQL("fix merchant names", `
UPDATE core.merchants
SET name = REPLACE(name, 'undefined ',
    CASE category_code
        WHEN 'ALM' THEN 'Alimentation '
        WHEN 'RST' THEN 'Restaurant '
        WHEN 'TRN' THEN 'Transport '
        WHEN 'TEL' THEN 'Télécom '
        WHEN 'CRB' THEN 'Carburant '
        WHEN 'SAN' THEN 'Santé '
        WHEN 'HAB' THEN 'Habillement '
        WHEN 'ELC' THEN 'Électronique '
        WHEN 'BTP' THEN 'BTP '
        WHEN 'EDU' THEN 'Éducation '
        WHEN 'SRV' THEN 'Services '
        WHEN 'HTL' THEN 'Hôtellerie '
        WHEN 'AUT' THEN 'Autres '
        ELSE ''
    END)
WHERE name LIKE 'undefined %';
`)

	// ── STEP 11 : Fix indexes ─────────────────────────────────────────────────
	section("STEP 11 — Indexes: partial index on merchant_status + node_sequence")
	mustRunSQL("fix idx_tx_merchant_status to partial", `
DROP INDEX IF EXISTS core.idx_tx_merchant_status;
CREATE INDEX idx_tx_merchant_status
    ON core.transactions (merchant_id, status)
    WHERE merchant_id IS NOT NULL;
`)

	mustRunSQL("add idx_tx_node_sequence", `
CREATE INDEX IF NOT EXISTS idx_tx_node_sequence
    ON core.transactions (node_id, sequence_number);
`)

	// ── STEP 12 : Full summary — every table, every schema ───────────────────
	section("STEP 12 — Summary: row counts across all schemas")
	mustRunSQL("full row count summary", `
SELECT
    schemaname  AS schema,
    relname     AS table_name,
    n_live_tup  AS row_count
FROM pg_stat_user_tables
ORDER BY schemaname, n_live_tup DESC;
`)

	// Detailed pipeline summary with expected values annotated
	mustRunSQL("pipeline integrity summary", `
SELECT table_name, row_count,
    CASE table_name
        WHEN 'staging.transactions'              THEN '= 10 000 expected'
        WHEN 'anomalies.idempotency_conflicts'   THEN '= 6 416 expected'
        WHEN 'quarantine.quarantine_transactions' THEN '≈ 3 505 expected'
        WHEN 'anomalies.transaction_anomalies'   THEN '= 52 expected'
        WHEN 'core.transactions'                 THEN '= 66 expected'
        WHEN 'core.accounts'                     THEN '= 1 087 expected'
        WHEN 'core.users'                        THEN '= 995 expected'
        WHEN 'core.merchants'                    THEN '= 100 expected'
        WHEN 'core.agencies'                     THEN '= 50 expected'
        WHEN 'reference.wilayas'                 THEN '= 15 expected'
        WHEN 'reference.categories'              THEN '= 13 expected'
        WHEN 'reference.tx_types'               THEN '= 8 expected'
        WHEN 'quarantine.quarantine_reasons'     THEN '> 0 expected (was 0)'
        ELSE ''
    END AS expected
FROM (
    SELECT 'staging.transactions'               AS table_name, COUNT(*) AS row_count FROM staging.transactions
    UNION ALL
    SELECT 'anomalies.idempotency_conflicts',                  COUNT(*) FROM anomalies.idempotency_conflicts
    UNION ALL
    SELECT 'anomalies.transaction_anomalies',                  COUNT(*) FROM anomalies.transaction_anomalies
    UNION ALL
    SELECT 'quarantine.quarantine_transactions',               COUNT(*) FROM quarantine.quarantine_transactions
    UNION ALL
    SELECT 'quarantine.quarantine_reasons',                    COUNT(*) FROM quarantine.quarantine_reasons
    UNION ALL
    SELECT 'core.users',                                       COUNT(*) FROM core.users
    UNION ALL
    SELECT 'core.accounts',                                    COUNT(*) FROM core.accounts
    UNION ALL
    SELECT 'core.merchants',                                   COUNT(*) FROM core.merchants
    UNION ALL
    SELECT 'core.agencies',                                    COUNT(*) FROM core.agencies
    UNION ALL
    SELECT 'core.transactions',                                COUNT(*) FROM core.transactions
    UNION ALL
    SELECT 'reference.wilayas',                                COUNT(*) FROM reference.wilayas
    UNION ALL
    SELECT 'reference.categories',                             COUNT(*) FROM reference.categories
    UNION ALL
    SELECT 'reference.tx_types',                               COUNT(*) FROM reference.tx_types
) counts
ORDER BY table_name;
`)

	// ── merchant name sanity check ────────────────────────────────────────────
	mustRunSQL("merchant name sanity check (must be 0)", `
SELECT COUNT(*) AS still_broken
FROM core.merchants
WHERE name LIKE 'undefined %';
`)

	elapsed := time.Since(start).Round(time.Millisecond)
	fmt.Printf("\n╔══════════════════════════════════════════════════════╗\n")
	fmt.Printf("║  Pipeline completed successfully in %-17s ║\n", elapsed)
	fmt.Printf("╚══════════════════════════════════════════════════════╝\n")
}