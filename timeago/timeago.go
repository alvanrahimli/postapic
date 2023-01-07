package timeago

import (
	"fmt"
	"strings"
	"time"
)

const (
	Day   time.Duration = time.Hour * 24
	Month time.Duration = Day * 30
	Year  time.Duration = Day * 365
)

type FormatPeriod struct {
	D    time.Duration
	One  string
	Many string
}

type Config struct {
	PastPrefix   string
	PastSuffix   string
	FuturePrefix string
	FutureSuffix string

	Periods []FormatPeriod

	Zero string
	Max  time.Duration //Maximum duration for using the special formatting.
	//DefaultLayout is used if delta is greater than the minimum of last period
	//in Periods and Max. It is the desired representation of the date 2nd of
	// January 2006.
	DefaultLayout string
}

var English = Config{
	PastPrefix:   "",
	PastSuffix:   " ago",
	FuturePrefix: "in ",
	FutureSuffix: "",

	Periods: []FormatPeriod{
		{time.Second, "about a second", "%d seconds"},
		{time.Minute, "about a minute", "%d minutes"},
		{time.Hour, "about an hour", "%d hours"},
		{Day, "one day", "%d days"},
		{Month, "one month", "%d months"},
		{Year, "one year", "%d years"},
	},

	Zero: "about a second",

	Max:           73 * time.Hour,
	DefaultLayout: "2006-01-02",
}

func (cfg Config) Format(t time.Time) string {
	return cfg.FormatReference(t, time.Now())
}

func (cfg Config) FormatReference(t time.Time, reference time.Time) string {

	d := reference.Sub(t)

	if (d >= 0 && d >= cfg.Max) || (d < 0 && -d >= cfg.Max) {
		return t.Format(cfg.DefaultLayout)
	}

	return cfg.FormatRelativeDuration(d)
}

func (cfg Config) FormatRelativeDuration(d time.Duration) string {

	isPast := d >= 0

	if d < 0 {
		d = -d
	}

	s, _ := cfg.getTimeText(d, true)

	if isPast {
		return strings.Join([]string{cfg.PastPrefix, s, cfg.PastSuffix}, "")
	} else {
		return strings.Join([]string{cfg.FuturePrefix, s, cfg.FutureSuffix}, "")
	}
}

func round(d time.Duration, step time.Duration, roundCloser bool) time.Duration {

	if roundCloser {
		return time.Duration(float64(d)/float64(step) + 0.5)
	}

	return time.Duration(float64(d) / float64(step))
}

// Count the number of parameters in a format string
func nbParamInFormat(f string) int {
	return strings.Count(f, "%") - 2*strings.Count(f, "%%")
}

// Convert a duration to a text, based on the current config
func (cfg Config) getTimeText(d time.Duration, roundCloser bool) (string, time.Duration) {
	if len(cfg.Periods) == 0 || d < cfg.Periods[0].D {
		return cfg.Zero, 0
	}

	for i, p := range cfg.Periods {

		next := p.D
		if i+1 < len(cfg.Periods) {
			next = cfg.Periods[i+1].D
		}

		if i+1 == len(cfg.Periods) || d < next {

			r := round(d, p.D, roundCloser)

			if next != p.D && r == round(next, p.D, roundCloser) {
				continue
			}

			if r == 0 {
				return "", d
			}

			layout := p.Many
			if r == 1 {
				layout = p.One
			}

			if nbParamInFormat(layout) == 0 {
				return layout, d - r*p.D
			}

			return fmt.Sprintf(layout, r), d - r*p.D
		}
	}

	return d.String(), 0
}

// NoMax creates a new config without a maximum
func NoMax(cfg Config) Config {
	return WithMax(cfg, 9223372036854775807, time.RFC3339)
}

// WithMax creates a new config with special formatting limited to durations less than max.
// Values greater than max will be formatted by the standard time package using the defaultLayout.
func WithMax(cfg Config, max time.Duration, defaultLayout string) Config {
	n := cfg
	n.Max = max
	n.DefaultLayout = defaultLayout
	return n
}
