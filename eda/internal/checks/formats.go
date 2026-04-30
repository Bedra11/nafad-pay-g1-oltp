package checks

import (
	"regexp"
	"strconv"
	"strings"
	"time"

	"eda/internal/csvx"
)

type FormatIssue struct {
	Rule    string
	Count   int
	Samples []string
}

func CheckPhoneFormat(ds *csvx.Dataset, col string) FormatIssue {
	re := regexp.MustCompile(`^\+222\d{8}$`)
	return checkByRegex(ds, col, re, "phone must match +222XXXXXXXX")
}

func CheckNNIFormat(ds *csvx.Dataset, col string) FormatIssue {
	re := regexp.MustCompile(`^\d{10}$`)
	return checkByRegex(ds, col, re, "nni must be 10 digits")
}

func CheckEnum(ds *csvx.Dataset, col string, allowed []string, rule string) FormatIssue {
	allow := map[string]struct{}{}
	for _, a := range allowed {
		allow[a] = struct{}{}
	}

	count := 0
	samples := []string{}
	seen := map[string]struct{}{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		if _, ok := allow[v]; !ok {
			count++
			if len(samples) < 10 {
				if _, exists := seen[v]; !exists {
					seen[v] = struct{}{}
					samples = append(samples, v)
				}
			}
		}
	}
	return FormatIssue{Rule: rule, Count: count, Samples: samples}
}

func CheckNumericNonNegative(ds *csvx.Dataset, col string, rule string) FormatIssue {
	count := 0
	samples := []string{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		f, err := strconv.ParseFloat(v, 64)
		if err != nil || f < 0 {
			count++
			if len(samples) < 10 {
				samples = append(samples, v)
			}
		}
	}
	return FormatIssue{Rule: rule, Count: count, Samples: samples}
}

func CheckNumericPositive(ds *csvx.Dataset, col string, rule string) FormatIssue {
	count := 0
	samples := []string{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		f, err := strconv.ParseFloat(v, 64)
		if err != nil || f <= 0 {
			count++
			if len(samples) < 10 {
				samples = append(samples, v)
			}
		}
	}
	return FormatIssue{Rule: rule, Count: count, Samples: samples}
}

func CheckDateParse(ds *csvx.Dataset, col string, rule string) FormatIssue {
	count := 0
	samples := []string{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		if !parseAnyTime(v) {
			count++
			if len(samples) < 10 {
				samples = append(samples, v)
			}
		}
	}
	return FormatIssue{Rule: rule, Count: count, Samples: samples}
}

func checkByRegex(ds *csvx.Dataset, col string, re *regexp.Regexp, rule string) FormatIssue {
	count := 0
	samples := []string{}
	for _, row := range ds.Rows {
		v := strings.TrimSpace(row[col])
		if v == "" {
			continue
		}
		if !re.MatchString(v) {
			count++
			if len(samples) < 10 {
				samples = append(samples, v)
			}
		}
	}
	return FormatIssue{Rule: rule, Count: count, Samples: samples}
}

func parseAnyTime(v string) bool {
	layouts := []string{
		time.RFC3339,
		"2006-01-02",
		"2006-01-02 15:04:05",
		"2006-01-02 15:04:05.000000",
		"2006-01-02 15:04:05.999999",
		"02/01/2006",
	}
	for _, l := range layouts {
		if _, err := time.Parse(l, v); err == nil {
			return true
		}
	}
	return false
}
