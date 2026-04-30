package report

import (
	"fmt"
	"os"
	"strings"

	"eda/internal/checks"
	"eda/internal/profile"
)

func WriteMarkdown(path string, content string) error {
	return os.WriteFile(path, []byte(content), 0644)
}

func RenderProfileReport(title string, profiles []profile.DatasetProfile) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")

	for _, p := range profiles {
		b.WriteString(fmt.Sprintf("## %s\n\n", p.Name))
		b.WriteString(fmt.Sprintf("- Rows: %d\n", p.RowCount))
		b.WriteString(fmt.Sprintf("- Columns: %d\n\n", p.ColumnCount))
		b.WriteString("| Column | Empty Count | Empty % | Distinct | Inferred Type | Min | Max | Examples |\n")
		b.WriteString("|---|---:|---:|---:|---|---|---|---|\n")
		for _, c := range p.Columns {
			b.WriteString(fmt.Sprintf(
				"| %s | %d | %.2f | %d | %s | %s | %s | %s |\n",
				escape(c.Name), c.EmptyCount, c.EmptyPct, c.DistinctCount, escape(c.InferredType),
				escape(c.MinValue), escape(c.MaxValue), escape(strings.Join(c.Examples, ", ")),
			))
		}
		b.WriteString("\n")
	}
	return b.String()
}

func RenderDuplicateReport(title string, items []checks.DuplicateResult) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")
	b.WriteString("| Dataset | Column | Empty | Distinct | Duplicate Keys | Duplicate Rows | Strict Unique? | Samples |\n")
	b.WriteString("|---|---|---:|---:|---:|---:|---|---|\n")
	for _, it := range items {
		b.WriteString(fmt.Sprintf(
			"| %s | %s | %d | %d | %d | %d | %t | %s |\n",
			escape(it.Dataset), escape(it.Column), it.EmptyCount, it.DistinctCount,
			it.DuplicateKeys, it.DuplicateRows, it.IsUniqueStrict,
			escape(strings.Join(it.SampleValues, ", ")),
		))
	}
	b.WriteString("\n")
	return b.String()
}

func RenderFormatReport(title string, items []checks.FormatIssue) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")
	b.WriteString("| Rule | Count | Samples |\n")
	b.WriteString("|---|---:|---|\n")
	for _, it := range items {
		b.WriteString(fmt.Sprintf("| %s | %d | %s |\n",
			escape(it.Rule), it.Count, escape(strings.Join(it.Samples, ", ")),
		))
	}
	b.WriteString("\n")
	return b.String()
}

func RenderReferenceReport(title string, items []checks.ReferenceIssue) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")
	b.WriteString("| Dataset | Column | Reference Set | Invalid Count | Samples |\n")
	b.WriteString("|---|---|---|---:|---|\n")
	for _, it := range items {
		b.WriteString(fmt.Sprintf("| %s | %s | %s | %d | %s |\n",
			escape(it.Dataset), escape(it.Column), escape(it.ReferenceSet),
			it.InvalidCount, escape(strings.Join(it.Samples, ", ")),
		))
	}
	b.WriteString("\n")
	return b.String()
}

func RenderOrphanReport(title string, items []checks.OrphanResult) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")
	b.WriteString("| Dataset | Column | Target | Orphan Count | Samples |\n")
	b.WriteString("|---|---|---|---:|---|\n")
	for _, it := range items {
		b.WriteString(fmt.Sprintf("| %s | %s | %s | %d | %s |\n",
			escape(it.Dataset), escape(it.Column), escape(it.Target),
			it.OrphanCount, escape(strings.Join(it.Samples, ", ")),
		))
	}
	b.WriteString("\n")
	return b.String()
}

func RenderRuleReport(title string, items []checks.RuleResult) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")
	b.WriteString("| Rule | Count | Samples |\n")
	b.WriteString("|---|---:|---|\n")
	for _, it := range items {
		b.WriteString(fmt.Sprintf("| %s | %d | %s |\n",
			escape(it.Rule), it.Count, escape(strings.Join(it.Samples, ", ")),
		))
	}
	b.WriteString("\n")
	return b.String()
}

func escape(s string) string {
	return strings.ReplaceAll(s, "|", `\|`)
}

func RenderPairConsistencyReport(title string, items []checks.PairConsistencyIssue) string {
	var b strings.Builder
	b.WriteString("# " + title + "\n\n")
	b.WriteString("| Dataset | ID Column | Name Column | Reference Set | Invalid Count | Samples |\n")
	b.WriteString("|---|---|---|---|---:|---|\n")
	for _, it := range items {
		b.WriteString(fmt.Sprintf("| %s | %s | %s | %s | %d | %s |\n",
			escape(it.Dataset),
			escape(it.IDColumn),
			escape(it.NameColumn),
			escape(it.ReferenceSet),
			it.InvalidCount,
			escape(strings.Join(it.Samples, ", ")),
		))
	}
	b.WriteString("\n")
	return b.String()
}
