package checks

import (
	"sort"
	"strings"

	"eda/internal/csvx"
)

type DuplicateResult struct {
	Dataset        string
	Column         string
	EmptyCount     int
	DistinctCount  int
	DuplicateKeys  int
	DuplicateRows  int
	SampleValues   []string
	IsUniqueStrict bool
}

func CheckDuplicates(ds *csvx.Dataset, col string) DuplicateResult {
	counts := map[string]int{}
	empty := 0

	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			empty++
			continue
		}
		counts[v]++
	}

	dupKeys := 0
	dupRows := 0
	samples := []string{}
	for k, c := range counts {
		if c > 1 {
			dupKeys++
			dupRows += c
			if len(samples) < 10 {
				samples = append(samples, k)
			}
		}
	}
	sort.Strings(samples)

	return DuplicateResult{
		Dataset:        ds.Name,
		Column:         col,
		EmptyCount:     empty,
		DistinctCount:  len(counts),
		DuplicateKeys:  dupKeys,
		DuplicateRows:  dupRows,
		SampleValues:   samples,
		IsUniqueStrict: dupKeys == 0 && empty == 0,
	}
}
