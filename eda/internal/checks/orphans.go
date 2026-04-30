package checks

import (
	"sort"
	"strings"

	"eda/internal/csvx"
)

type OrphanResult struct {
	Dataset     string
	Column      string
	Target      string
	OrphanCount int
	Samples     []string
}

func CheckOrphans(ds *csvx.Dataset, col string, targetName string, valid map[string]struct{}) OrphanResult {
	count := 0
	samples := []string{}
	seen := map[string]struct{}{}

	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		if _, ok := valid[v]; !ok {
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

	return OrphanResult{
		Dataset:     ds.Name,
		Column:      col,
		Target:      targetName,
		OrphanCount: count,
		Samples:     samples,
	}
}
