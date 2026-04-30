package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"eda/internal/checks"
	"eda/internal/csvx"
	"eda/internal/profile"
	"eda/internal/report"
)

func main() {
	if err := os.MkdirAll("reports", 0755); err != nil {
		log.Fatal(err)
	}

	// Chargement des datasets
	users := mustLoad("../data/G1_OLTP/users_sample.csv")
	accounts := mustLoad("../data/G1_OLTP/accounts_sample.csv")
	transactions := mustLoad("../data/G1_OLTP/transactions_sample.csv")
	merchants := mustLoad("../data/G1_OLTP/merchants_sample.csv")
	agencies := mustLoad("../data/G1_OLTP/agencies_sample.csv")

	refCategories := mustLoad("../data/shared/reference_categories.csv")
	refTxTypes := mustLoad("../data/shared/reference_tx_types.csv")
	refWilayas := mustLoad("../data/shared/reference_wilayas.csv")

	// 1. Profiling
	profiles := []profile.DatasetProfile{
		profile.ProfileDataset(users),
		profile.ProfileDataset(accounts),
		profile.ProfileDataset(transactions),
		profile.ProfileDataset(merchants),
		profile.ProfileDataset(agencies),
		profile.ProfileDataset(refCategories),
		profile.ProfileDataset(refTxTypes),
		profile.ProfileDataset(refWilayas),
	}
	write("reports/01_profiling.md", report.RenderProfileReport("Profiling", profiles))

	// 2. Duplicates
	dupItems := []checks.DuplicateResult{}
	addDup := func(ds *csvx.Dataset, cols ...string) {
		for _, c := range cols {
			if csvx.HasColumn(ds, c) {
				dupItems = append(dupItems, checks.CheckDuplicates(ds, c))
			}
		}
	}

	addDup(users, "id", "nni", "phone", "email")
	addDup(accounts, "id", "account_number", "user_id")
	addDup(transactions, "id", "reference", "idempotency_key")
	addDup(merchants, "id", "code")
	addDup(agencies, "id", "code")
	addDup(refCategories, "id", "code", "category_code")
	addDup(refTxTypes, "id", "code", "tx_type_code")
	addDup(refWilayas, "id", "code", "wilaya_id")

	write("reports/02_duplicates.md", report.RenderDuplicateReport("Duplicate Checks", dupItems))

	// 3. Format checks
	formatItems := []checks.FormatIssue{}

	if csvx.HasColumn(users, "phone") {
		formatItems = append(formatItems, checks.CheckPhoneFormat(users, "phone"))
	}
	if csvx.HasColumn(users, "nni") {
		formatItems = append(formatItems, checks.CheckNNIFormat(users, "nni"))
	}
	if csvx.HasColumn(transactions, "amount") {
		formatItems = append(formatItems, checks.CheckNumericPositive(transactions, "amount", "transactions.amount > 0"))
	}
	if csvx.HasColumn(transactions, "fee") {
		formatItems = append(formatItems, checks.CheckNumericNonNegative(transactions, "fee", "transactions.fee >= 0"))
	}
	if csvx.HasColumn(transactions, "balance_before") {
		formatItems = append(formatItems, checks.CheckNumericNonNegative(transactions, "balance_before", "transactions.balance_before >= 0"))
	}
	if csvx.HasColumn(transactions, "balance_after") {
		formatItems = append(formatItems, checks.CheckNumericNonNegative(transactions, "balance_after", "transactions.balance_after >= 0"))
	}
	if csvx.HasColumn(transactions, "created_at") {
		formatItems = append(formatItems, checks.CheckDateParse(transactions, "created_at", "transactions.created_at parsable"))
	}
	if csvx.HasColumn(transactions, "completed_at") {
		formatItems = append(formatItems, checks.CheckDateParse(transactions, "completed_at", "transactions.completed_at parsable"))
	}
	if csvx.HasColumn(transactions, "status") {
		formatItems = append(formatItems, checks.CheckEnum(transactions, "status", []string{"SUCCESS", "FAILED", "PENDING"}, "transactions.status in {SUCCESS,FAILED,PENDING}"))
	}

	write("reports/03_formats.md", report.RenderFormatReport("Format Checks", formatItems))

	// 4. Reference checks using shared
	// 4. Reference checks using shared
	refItems := []checks.ReferenceIssue{}

	// --- transaction type checks
	txTypeRefCol := csvx.FirstExistingColumn(refTxTypes, "code")
	if txTypeRefCol != "" {
		txTypeSet := csvx.DistinctNonEmpty(refTxTypes, txTypeRefCol)
		if c := csvx.FirstExistingColumn(transactions, "transaction_type", "tx_type", "type_code"); c != "" {
			refItems = append(refItems,
				checks.CheckValuesInReferenceSet(
					transactions,
					c,
					"reference_tx_types."+txTypeRefCol,
					txTypeSet,
				),
			)
		}
	}

	// --- category checks
	categoryRefCol := csvx.FirstExistingColumn(refCategories, "code")
	if categoryRefCol != "" {
		categorySet := csvx.DistinctNonEmpty(refCategories, categoryRefCol)
		if c := csvx.FirstExistingColumn(merchants, "category_code", "category"); c != "" {
			refItems = append(refItems,
				checks.CheckValuesInReferenceSet(
					merchants,
					c,
					"reference_categories."+categoryRefCol,
					categorySet,
				),
			)
		}
	}

	// --- wilaya checks
	wilayaRefIDCol := csvx.FirstExistingColumn(refWilayas, "id")
	wilayaRefNameCol := csvx.FirstExistingColumn(refWilayas, "name")

	wilayaIDSet := map[string]struct{}{}
	wilayaNameSet := map[string]struct{}{}

	if wilayaRefIDCol != "" {
		wilayaIDSet = csvx.DistinctNonEmpty(refWilayas, wilayaRefIDCol)
	}
	if wilayaRefNameCol != "" {
		wilayaNameSet = csvx.DistinctNonEmpty(refWilayas, wilayaRefNameCol)
	}

	addWilayaChecks := func(ds *csvx.Dataset) {
		if c := csvx.FirstExistingColumn(ds, "wilaya_id"); c != "" && wilayaRefIDCol != "" {
			refItems = append(refItems,
				checks.CheckValuesInReferenceSet(
					ds,
					c,
					"reference_wilayas."+wilayaRefIDCol,
					wilayaIDSet,
				),
			)
		}

		if c := csvx.FirstExistingColumn(ds, "wilaya_name"); c != "" && wilayaRefNameCol != "" {
			refItems = append(refItems,
				checks.CheckValuesInReferenceSet(
					ds,
					c,
					"reference_wilayas."+wilayaRefNameCol,
					wilayaNameSet,
				),
			)
		}
	}

	addWilayaChecks(users)
	addWilayaChecks(agencies)
	addWilayaChecks(merchants)

	write("reports/04_reference_checks.md", report.RenderReferenceReport("Reference Checks", refItems))

	// 4b. Wilaya ID/name consistency checks
	pairItems := []checks.PairConsistencyIssue{}

	wilayaIDCol := csvx.FirstExistingColumn(refWilayas, "id")
	wilayaNameCol := csvx.FirstExistingColumn(refWilayas, "name")

	if wilayaIDCol != "" && wilayaNameCol != "" {
		wilayaMap := map[string]string{}

		for _, row := range refWilayas.Rows {
			idVal := row[wilayaIDCol]
			nameVal := row[wilayaNameCol]
			if idVal != "" && nameVal != "" {
				wilayaMap[idVal] = nameVal
			}
		}

		addWilayaPairCheck := func(ds *csvx.Dataset) {
			idCol := csvx.FirstExistingColumn(ds, "wilaya_id")
			nameCol := csvx.FirstExistingColumn(ds, "wilaya_name")

			if idCol != "" && nameCol != "" {
				pairItems = append(pairItems,
					checks.CheckIDNameConsistency(
						ds,
						idCol,
						nameCol,
						"reference_wilayas(id->name)",
						wilayaMap,
					),
				)
			}
		}

		addWilayaPairCheck(users)
		addWilayaPairCheck(agencies)
		addWilayaPairCheck(merchants)
	}

	write("reports/04b_wilaya_pair_consistency.md",
		report.RenderPairConsistencyReport("Wilaya ID/Name Pair Consistency", pairItems))
	// 5. Orphan checks
	orphanItems := []checks.OrphanResult{}

	userIDCol := csvx.FirstExistingColumn(users, "id", "user_id")
	accountIDCol := csvx.FirstExistingColumn(accounts, "id", "account_id")
	merchantIDCol := csvx.FirstExistingColumn(merchants, "id", "merchant_id")
	agencyIDCol := csvx.FirstExistingColumn(agencies, "id", "agency_id")

	userIDs := csvx.DistinctNonEmpty(users, userIDCol)
	accountIDs := csvx.DistinctNonEmpty(accounts, accountIDCol)
	merchantIDs := csvx.DistinctNonEmpty(merchants, merchantIDCol)
	agencyIDs := csvx.DistinctNonEmpty(agencies, agencyIDCol)

	checkOrphanIfExists := func(col string, target string, valid map[string]struct{}) {
		if col != "" {
			orphanItems = append(orphanItems, checks.CheckOrphans(transactions, col, target, valid))
		}
	}

	checkOrphanIfExists(csvx.FirstExistingColumn(transactions, "source_user_id"), "users."+userIDCol, userIDs)
	checkOrphanIfExists(csvx.FirstExistingColumn(transactions, "destination_user_id"), "users."+userIDCol, userIDs)
	checkOrphanIfExists(csvx.FirstExistingColumn(transactions, "source_account_id"), "accounts."+accountIDCol, accountIDs)
	checkOrphanIfExists(csvx.FirstExistingColumn(transactions, "destination_account_id"), "accounts."+accountIDCol, accountIDs)
	checkOrphanIfExists(csvx.FirstExistingColumn(transactions, "merchant_id"), "merchants."+merchantIDCol, merchantIDs)
	checkOrphanIfExists(csvx.FirstExistingColumn(transactions, "agency_id"), "agencies."+agencyIDCol, agencyIDs)

	write("reports/05_orphans.md", report.RenderOrphanReport("Orphan Checks", orphanItems))

	// 6. Transaction rules
	ruleItems := []checks.RuleResult{}
	txIDCol := csvx.FirstExistingColumn(transactions, "id", "reference")

	statusCol := csvx.FirstExistingColumn(transactions, "status")
	beforeCol := csvx.FirstExistingColumn(transactions, "balance_before")
	afterCol := csvx.FirstExistingColumn(transactions, "balance_after")
	amountCol := csvx.FirstExistingColumn(transactions, "amount")
	feeCol := csvx.FirstExistingColumn(transactions, "fee")
	createdCol := csvx.FirstExistingColumn(transactions, "created_at")
	completedCol := csvx.FirstExistingColumn(transactions, "completed_at")
	idemCol := csvx.FirstExistingColumn(transactions, "idempotency_key")
	refCol := csvx.FirstExistingColumn(transactions, "reference")
	nodeCol := csvx.FirstExistingColumn(transactions, "node_id")
	processingNodeCol := csvx.FirstExistingColumn(transactions, "processing_node")

	if statusCol != "" && beforeCol != "" && afterCol != "" {
		ruleItems = append(ruleItems, checks.CheckFailedBalanceInvariant(transactions, statusCol, beforeCol, afterCol, txIDCol))
	}
	if amountCol != "" {
		ruleItems = append(ruleItems, checks.CheckNegativeOrZero(transactions, amountCol, false, txIDCol))
	}
	if feeCol != "" {
		ruleItems = append(ruleItems, checks.CheckNegativeOrZero(transactions, feeCol, true, txIDCol))
	}
	if beforeCol != "" {
		ruleItems = append(ruleItems, checks.CheckNegativeOrZero(transactions, beforeCol, true, txIDCol))
	}
	if afterCol != "" {
		ruleItems = append(ruleItems, checks.CheckNegativeOrZero(transactions, afterCol, true, txIDCol))
	}
	if createdCol != "" && completedCol != "" {
		ruleItems = append(ruleItems, checks.CheckDateOrder(transactions, createdCol, completedCol, txIDCol))
	}
	if statusCol != "" {
		ruleItems = append(ruleItems, checks.CheckUnexpectedStatus(transactions, statusCol, txIDCol, []string{"SUCCESS", "FAILED", "PENDING"}))
	}
	if idemCol != "" && amountCol != "" && statusCol != "" {
		ruleItems = append(ruleItems, checks.CheckSameIdempotencyDifferentPayload(transactions, idemCol, amountCol, statusCol, txIDCol))
	}
	if refCol != "" && amountCol != "" {
		ruleItems = append(ruleItems, checks.CheckSameReferenceDifferentAmount(transactions, refCol, amountCol, txIDCol))
	}
	if nodeCol != "" && processingNodeCol != "" {
		ruleItems = append(ruleItems, checks.CheckNodeVsProcessingNode(transactions, nodeCol, processingNodeCol, txIDCol))
	}

	write("reports/06_transaction_rules.md", report.RenderRuleReport("Transaction Rules", ruleItems))

	// 7. Summary markdown skeleton
	write("reports/99_summary.md", summaryTemplate())

	fmt.Println("Exploration terminée. Rapports générés dans ./reports")
	printReports()
}

func mustLoad(path string) *csvx.Dataset {
	ds, err := csvx.LoadCSV(path)
	if err != nil {
		log.Fatal(err)
	}
	return ds
}

func write(path, content string) {
	if err := report.WriteMarkdown(path, content); err != nil {
		log.Fatalf("write %s: %v", path, err)
	}
}

func printReports() {
	entries, err := filepath.Glob("reports/*.md")
	if err != nil {
		return
	}
	for _, e := range entries {
		fmt.Println("-", e)
	}
}

func summaryTemplate() string {
	return `# Final Exploration Summary

## 1. Tables and entities understood
- users
- accounts
- transactions
- merchants
- agencies
- reference tables

## 2. Columns likely to become primary keys
- TODO

## 3. Columns likely to become unique constraints
- TODO

## 4. Columns likely to become foreign keys
- TODO

## 5. Columns that should remain nullable
- TODO

## 6. Columns that are too dirty / empty / ignorable
- TODO

## 7. Orphans and quarantine decisions
- TODO

## 8. Business-rule violations
- TODO

## 9. Other anomalies discovered beyond README
- TODO

## 10. Impact on relational model
- TODO
`
}
