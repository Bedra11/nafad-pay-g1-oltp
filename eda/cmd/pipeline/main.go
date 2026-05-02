package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
)

func runSQLFile(path string) error {
	sql, err := os.ReadFile(path)
	if err != nil {
		return err
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

	fmt.Println("Running:", path)
	return cmd.Run()
}

func runSQLCommand(command string) error {
	cmd := exec.Command(
		"docker", "exec", "-i",
		"nafadpay-postgres",
		"psql", "-U", "admin", "-d", "nafadpay",
		"-v", "ON_ERROR_STOP=1",
		"-c", command,
	)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func main() {
	fmt.Println("Starting Go validation and core loading pipeline...")

	createFiles := []string{
		"sql/reference/01_reference_schema.sql",

		"sql/core/01_core_users.sql",
		"sql/core/02_core_accounts.sql",
		"sql/core/04_core_merchants.sql",
		"sql/core/05_core_agencies.sql",
		"sql/core/03_core_transactions.sql",

		"sql/anomalies/01_transaction_anomalies.sql",
		"sql/anomalies/02_idempotency_conflicts.sql",
		"sql/quarantine/01_quarantine_transactions.sql",
		"sql/quarantine/02_quarantine_reasons.sql",
	}

	for _, file := range createFiles {
		if err := runSQLFile(file); err != nil {
			fmt.Println("Pipeline failed:", err)
			os.Exit(1)
		}
	}

	resetSQL := `
TRUNCATE TABLE 
    core.transactions,
    core.accounts,
    core.merchants,
    core.agencies,
    core.users,
    anomalies.transaction_anomalies,
    anomalies.idempotency_conflicts,
    quarantine.quarantine_transactions,
    reference.tx_types,
    reference.categories,
    reference.wilayas
RESTART IDENTITY CASCADE;
`

	if err := runSQLCommand(resetSQL); err != nil {
		fmt.Println("Pipeline failed:", err)
		os.Exit(1)
	}

	referenceLoadSQL := `
INSERT INTO reference.wilayas (id, code, name)
SELECT DISTINCT
    NULLIF(wilaya_id, '')::integer,
    'W' || LPAD(NULLIF(wilaya_id, ''), 2, '0'),
    wilaya_name
FROM (
    SELECT wilaya_id, wilaya_name FROM staging.users
    UNION
    SELECT wilaya_id, wilaya_name FROM staging.merchants
    UNION
    SELECT wilaya_id, wilaya_name FROM staging.agencies
) w
WHERE wilaya_id IS NOT NULL
AND wilaya_id <> ''
AND wilaya_name IS NOT NULL
AND wilaya_name <> ''
ON CONFLICT DO NOTHING;

INSERT INTO reference.tx_types (
    id,
    code,
    label,
    description,
    requires_destination,
    requires_merchant,
    requires_agency,
    is_credit
)
SELECT
    ROW_NUMBER() OVER (ORDER BY transaction_type)::integer,
    transaction_type,
    COALESCE(NULLIF(MAX(transaction_type_label), ''), transaction_type),
    'Transaction type loaded from staging',
    CASE WHEN transaction_type = 'TRF' THEN true ELSE false END,
    CASE WHEN transaction_type = 'PAY' THEN true ELSE false END,
    CASE WHEN transaction_type IN ('DEP', 'WDL') THEN true ELSE false END,
    CASE WHEN transaction_type = 'DEP' THEN true ELSE false END
FROM staging.transactions
WHERE transaction_type IS NOT NULL
AND transaction_type <> ''
GROUP BY transaction_type
ON CONFLICT DO NOTHING;

INSERT INTO reference.categories (
    id,
    code,
    mcc,
    label,
    avg_min,
    avg_max
)
SELECT
    ROW_NUMBER() OVER (ORDER BY category_code)::integer,
    category_code,
    MIN(NULLIF(mcc, '')),
    COALESCE(NULLIF(MAX(category_label), ''), category_code),
    MIN(NULLIF(avg_transaction_min, '')::numeric),
    MAX(NULLIF(avg_transaction_max, '')::numeric)
FROM staging.merchants
WHERE category_code IS NOT NULL
AND category_code <> ''
GROUP BY category_code
ON CONFLICT DO NOTHING;
`

	fmt.Println("Loading reference data from staging...")
	if err := runSQLCommand(referenceLoadSQL); err != nil {
		fmt.Println("Pipeline failed:", err)
		os.Exit(1)
	}

	pipelineFiles := []string{
		"sql/anomalies/05_insert_transaction_anomalies.sql",
		"sql/anomalies/06_insert_idempotency_conflicts.sql",

		"sql/quarantine/04_insert_quarantine_transactions.sql",

		"sql/core_load/01_insert_core_users.sql",
		"sql/core_load/02_insert_core_accounts.sql",
		"sql/core_load/03_insert_core_merchants.sql",
		"sql/core_load/04_insert_core_agencies.sql",

		"sql/quarantine/05_insert_core_reference_quarantine.sql",

		"sql/core_ready/01_prepare_core_transactions.sql",
		"sql/core_ready/02_insert_core_transactions.sql",
	}

	for _, file := range pipelineFiles {
		if err := runSQLFile(file); err != nil {
			fmt.Println("Pipeline failed:", err)
			os.Exit(1)
		}
	}

	summarySQL := `
SELECT 'transaction_anomalies' AS table_name, COUNT(*) AS count FROM anomalies.transaction_anomalies
UNION ALL
SELECT 'idempotency_conflicts', COUNT(*) FROM anomalies.idempotency_conflicts
UNION ALL
SELECT 'quarantine_transactions', COUNT(*) FROM quarantine.quarantine_transactions
UNION ALL
SELECT 'core_users', COUNT(*) FROM core.users
UNION ALL
SELECT 'core_accounts', COUNT(*) FROM core.accounts
UNION ALL
SELECT 'core_merchants', COUNT(*) FROM core.merchants
UNION ALL
SELECT 'core_agencies', COUNT(*) FROM core.agencies
UNION ALL
SELECT 'core_transactions', COUNT(*) FROM core.transactions;
`

	fmt.Println("Final pipeline summary:")
	if err := runSQLCommand(summarySQL); err != nil {
		fmt.Println("Pipeline failed:", err)
		os.Exit(1)
	}

	fmt.Println("Pipeline completed successfully.")
}