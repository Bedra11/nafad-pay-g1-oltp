package checks

import (
	"strconv"
	"strings"
	"time"

	"eda/internal/csvx"
)

type RuleResult struct {
	Rule    string
	Count   int
	Samples []string
}

func CheckFailedBalanceInvariant(ds *csvx.Dataset, statusCol, beforeCol, afterCol, idCol string) RuleResult {
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		status := strings.TrimSpace(row[statusCol])
		if status != "FAILED" {
			continue
		}

		before, ok1 := parseFloat(row[beforeCol])
		after, ok2 := parseFloat(row[afterCol])
		if !ok1 || !ok2 {
			continue
		}

		if before != after {
			count++
			if len(samples) < 10 {
				samples = append(samples, row[idCol])
			}
		}
	}

	return RuleResult{
		Rule:    "FAILED => balance_before == balance_after",
		Count:   count,
		Samples: samples,
	}
}

func CheckNegativeOrZero(ds *csvx.Dataset, col string, allowZero bool, idCol string) RuleResult {
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		v, ok := parseFloat(row[col])
		if !ok {
			continue
		}

		bad := false
		if allowZero {
			bad = v < 0
		} else {
			bad = v <= 0
		}
		if bad {
			count++
			if len(samples) < 10 {
				samples = append(samples, row[idCol])
			}
		}
	}

	name := col + " must be "
	if allowZero {
		name += ">= 0"
	} else {
		name += "> 0"
	}

	return RuleResult{Rule: name, Count: count, Samples: samples}
}

func CheckDateOrder(ds *csvx.Dataset, createdCol, completedCol, idCol string) RuleResult {
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		created := strings.TrimSpace(row[createdCol])
		completed := strings.TrimSpace(row[completedCol])
		if created == "" || completed == "" {
			continue
		}
		tc, ok1 := parseTime(created)
		td, ok2 := parseTime(completed)
		if !ok1 || !ok2 {
			continue
		}
		if td.Before(tc) {
			count++
			if len(samples) < 10 {
				samples = append(samples, row[idCol])
			}
		}
	}

	return RuleResult{
		Rule:    "completed_at >= created_at",
		Count:   count,
		Samples: samples,
	}
}

func CheckUnexpectedStatus(ds *csvx.Dataset, statusCol, idCol string, allowed []string) RuleResult {
	allow := map[string]struct{}{}
	for _, a := range allowed {
		allow[a] = struct{}{}
	}

	count := 0
	samples := []string{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[statusCol])
		if v == "" {
			continue
		}
		if _, ok := allow[v]; !ok {
			count++
			if len(samples) < 10 {
				samples = append(samples, row[idCol]+":"+v)
			}
		}
	}

	return RuleResult{
		Rule:    "status must be one of allowed values",
		Count:   count,
		Samples: samples,
	}
}

func CheckSameIdempotencyDifferentPayload(ds *csvx.Dataset, idemCol, amountCol, statusCol, idCol string) RuleResult {
	type sig struct {
		Amount string
		Status string
	}
	seen := map[string]sig{}
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		key := strings.TrimSpace(row[idemCol])
		if key == "" {
			continue
		}
		cur := sig{
			Amount: strings.TrimSpace(row[amountCol]),
			Status: strings.TrimSpace(row[statusCol]),
		}

		if prev, ok := seen[key]; ok {
			if prev != cur {
				count++
				if len(samples) < 10 {
					samples = append(samples, key)
				}
			}
		} else {
			seen[key] = cur
		}
	}

	return RuleResult{
		Rule:    "same idempotency_key with different payload",
		Count:   count,
		Samples: samples,
	}
}

func CheckSameReferenceDifferentAmount(ds *csvx.Dataset, refCol, amountCol, idCol string) RuleResult {
	seen := map[string]string{}
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		ref := strings.TrimSpace(row[refCol])
		if ref == "" {
			continue
		}
		amt := strings.TrimSpace(row[amountCol])

		if prev, ok := seen[ref]; ok {
			if prev != amt {
				count++
				if len(samples) < 10 {
					samples = append(samples, ref)
				}
			}
		} else {
			seen[ref] = amt
		}
	}

	return RuleResult{
		Rule:    "same reference with different amount",
		Count:   count,
		Samples: samples,
	}
}

func CheckNodeVsProcessingNode(ds *csvx.Dataset, nodeCol, processingCol, idCol string) RuleResult {
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		a := strings.TrimSpace(row[nodeCol])
		b := strings.TrimSpace(row[processingCol])
		if a == "" || b == "" {
			continue
		}
		if a != b {
			count++
			if len(samples) < 10 {
				samples = append(samples, row[idCol])
			}
		}
	}

	return RuleResult{
		Rule:    "node_id != processing_node",
		Count:   count,
		Samples: samples,
	}
}

func parseFloat(s string) (float64, bool) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, false
	}
	f, err := strconv.ParseFloat(s, 64)
	return f, err == nil
}

func parseTime(s string) (time.Time, bool) {
	s = strings.TrimSpace(s)
	layouts := []string{
		time.RFC3339,
		"2006-01-02",
		"2006-01-02 15:04:05",
		"2006-01-02 15:04:05.000000",
		"2006-01-02 15:04:05.999999",
	}
	for _, l := range layouts {
		if t, err := time.Parse(l, s); err == nil {
			return t, true
		}
	}
	return time.Time{}, false
}
