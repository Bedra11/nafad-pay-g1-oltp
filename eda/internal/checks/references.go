package checks

import (
	"sort"
	"strings"

	"eda/internal/csvx"
)

type ReferenceIssue struct {
	Dataset      string
	Column       string
	ReferenceSet string
	InvalidCount int
	Samples      []string
}

func CheckValuesInReferenceSet(ds *csvx.Dataset, col string, refName string, allowed map[string]struct{}) ReferenceIssue {
	count := 0
	samples := []string{}
	seen := map[string]struct{}{}

	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		if _, ok := allowed[v]; !ok {
			count++
			if len(samples) < 10 {
				if _, exists := seen[v]; !exists {
					seen[v] = struct{}{}
					samples = append(samples, v)
				}
			}
		}
	}

	sort.Strings(samples)

	return ReferenceIssue{
		Dataset:      ds.Name,
		Column:       col,
		ReferenceSet: refName,
		InvalidCount: count,
		Samples:      samples,
	}
}

type PairConsistencyIssue struct {
	Dataset      string
	IDColumn     string
	NameColumn   string
	ReferenceSet string
	InvalidCount int
	Samples      []string
}

func CheckIDNameConsistency(
	ds *csvx.Dataset,
	idCol string,
	nameCol string,
	refName string,
	refMap map[string]string,
) PairConsistencyIssue {
	count := 0
	samples := []string{}

	for _, row := range ds.Rows {
		idVal := strings.TrimSpace(row[idCol])
		nameVal := strings.TrimSpace(row[nameCol])

		if idVal == "" || nameVal == "" {
			continue
		}

		expectedName, ok := refMap[idVal]
		if !ok {
			continue
		}

		if expectedName != nameVal {
			count++
			if len(samples) < 10 {
				samples = append(samples, idVal+" => expected="+expectedName+", got="+nameVal)
			}
		}
	}

	sort.Strings(samples)

	return PairConsistencyIssue{
		Dataset:      ds.Name,
		IDColumn:     idCol,
		NameColumn:   nameCol,
		ReferenceSet: refName,
		InvalidCount: count,
		Samples:      samples,
	}
}
