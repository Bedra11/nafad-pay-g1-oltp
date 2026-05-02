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
    quarantine.quarantine_transactions
RESTART IDENTITY CASCADE;
`

	if err := runSQLCommand(resetSQL); err != nil {
		fmt.Println("Pipeline failed:", err)
		os.Exit(1)
	}

	pipelineFiles := []string{
		// anomalies
		"sql/anomalies/05_insert_transaction_anomalies.sql",
		"sql/anomalies/06_insert_idempotency_conflicts.sql",

		// quarantine (staging level)
		"sql/quarantine/04_insert_quarantine_transactions.sql",

		// load core parents FIRST
		"sql/core_load/01_insert_core_users.sql",
		"sql/core_load/02_insert_core_accounts.sql",
		"sql/core_load/03_insert_core_merchants.sql",
		"sql/core_load/04_insert_core_agencies.sql",

		// quarantine based on core references
		"sql/quarantine/05_insert_core_reference_quarantine.sql",

		// prepare clean data
		"sql/core_ready/01_prepare_core_transactions.sql",

		// final insert
		"sql/core_ready/02_insert_core_transactions.sql",
	}

	for _, file := range pipelineFiles {
		if err := runSQLFile(file); err != nil {
			fmt.Println("Pipeline failed:", err)
			os.Exit(1)
		}
	}

	summarySQL := `
SELECT 'transaction_anomalies' AS table_name, COUNT(*) FROM anomalies.transaction_anomalies
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

	if err := runSQLCommand(summarySQL); err != nil {
		fmt.Println("Pipeline failed:", err)
		os.Exit(1)
	}

	fmt.Println("Go validation and core loading pipeline completed successfully.")
}