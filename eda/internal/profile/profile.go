package profile

import (
	"sort"
	"strconv"
	"strings"
	"time"

	"eda/internal/csvx"
)

type ColumnProfile struct {
	Name          string
	EmptyCount    int
	EmptyPct      float64
	DistinctCount int
	Examples      []string
	InferredType  string
	MinValue      string
	MaxValue      string
}

type DatasetProfile struct {
	Name        string
	RowCount    int
	ColumnCount int
	Columns     []ColumnProfile
}

func ProfileDataset(ds *csvx.Dataset) DatasetProfile {
	out := DatasetProfile{
		Name:        ds.Name,
		RowCount:    len(ds.Rows),
		ColumnCount: len(ds.Header),
		Columns:     make([]ColumnProfile, 0, len(ds.Header)),
	}

	for _, col := range ds.Header {
		cp := profileColumn(ds, col)
		out.Columns = append(out.Columns, cp)
	}

	return out
}

func profileColumn(ds *csvx.Dataset, col string) ColumnProfile {
	distinct := map[string]struct{}{}
	examples := []string{}
	exSeen := map[string]struct{}{}
	empty := 0

	nonEmptyValues := []string{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			empty++
			continue
		}
		distinct[v] = struct{}{}
		nonEmptyValues = append(nonEmptyValues, v)

		if len(examples) < 5 {
			if _, ok := exSeen[v]; !ok {
				exSeen[v] = struct{}{}
				examples = append(examples, v)
			}
		}
	}

	minV, maxV := minMax(nonEmptyValues)

	emptyPct := 0.0
	if len(ds.Rows) > 0 {
		emptyPct = float64(empty) * 100 / float64(len(ds.Rows))
	}

	return ColumnProfile{
		Name:          col,
		EmptyCount:    empty,
		EmptyPct:      emptyPct,
		DistinctCount: len(distinct),
		Examples:      examples,
		InferredType:  inferType(nonEmptyValues),
		MinValue:      minV,
		MaxValue:      maxV,
	}
}

func minMax(values []string) (string, string) {
	if len(values) == 0 {
		return "", ""
	}
	cp := append([]string{}, values...)
	sort.Strings(cp)
	return cp[0], cp[len(cp)-1]
}

func inferType(values []string) string {
	if len(values) == 0 {
		return "empty"
	}

	intOK := true
	floatOK := true
	dateOK := true

	for _, v := range values {
		if _, err := strconv.ParseInt(v, 10, 64); err != nil {
			intOK = false
		}
		if _, err := strconv.ParseFloat(v, 64); err != nil {
			floatOK = false
		}
		if !looksLikeDate(v) {
			dateOK = false
		}
	}

	switch {
	case intOK:
		return "integer"
	case floatOK:
		return "float"
	case dateOK:
		return "date/datetime"
	default:
		return "string"
	}
}

func looksLikeDate(s string) bool {
	layouts := []string{
		time.RFC3339,
		"2006-01-02",
		"2006-01-02 15:04:05",
		"2006-01-02 15:04:05.000000",
		"02/01/2006",
	}
	for _, l := range layouts {
		if _, err := time.Parse(l, s); err == nil {
			return true
		}
	}
	return false
}
