package csvx

import (
	"encoding/csv"
	"fmt"
	"os"
	"strings"
)

type Dataset struct {
	Path   string
	Name   string
	Header []string
	Rows   []map[string]string
}

func LoadCSV(path string) (*Dataset, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("open %s: %w", path, err)
	}
	defer f.Close()

	r := csv.NewReader(f)
	r.FieldsPerRecord = -1
	r.TrimLeadingSpace = true

	raw, err := r.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	if len(raw) == 0 {
		return nil, fmt.Errorf("empty csv: %s", path)
	}

	header := normalizeHeader(raw[0])
	rows := make([]map[string]string, 0, len(raw)-1)

	for _, rr := range raw[1:] {
		row := make(map[string]string, len(header))
		for i, h := range header {
			val := ""
			if i < len(rr) {
				val = strings.TrimSpace(rr[i])
			}
			row[h] = val
		}
		rows = append(rows, row)
	}

	return &Dataset{
		Path:   path,
		Name:   fileName(path),
		Header: header,
		Rows:   rows,
	}, nil
}

func normalizeHeader(cols []string) []string {
	out := make([]string, len(cols))
	for i, c := range cols {
		out[i] = strings.TrimSpace(c)
	}
	return out
}

func fileName(path string) string {
	parts := strings.Split(path, "/")
	return parts[len(parts)-1]
}

func DistinctNonEmpty(ds *Dataset, col string) map[string]struct{} {
	out := map[string]struct{}{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v != "" {
			out[v] = struct{}{}
		}
	}
	return out
}

func Values(ds *Dataset, col string) []string {
	out := make([]string, 0, len(ds.Rows))
	for _, row := range ds.Rows {
		out = append(out, strings.TrimSpace(row[col]))
	}
	return out
}

func HasColumn(ds *Dataset, col string) bool {
	for _, h := range ds.Header {
		if h == col {
			return true
		}
	}
	return false
}

func FirstExistingColumn(ds *Dataset, candidates ...string) string {
	for _, c := range candidates {
		if HasColumn(ds, c) {
			return c
		}
	}
	return ""
}
