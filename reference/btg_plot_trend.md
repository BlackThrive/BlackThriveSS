# Chart a series over time from a bundled dataset

Draws how a measure moves across the years, or months, a dataset holds:
a force's or council's stop-rate ratios or rates per 1,000 residents for
each group compared with White, national monthly stops by group,
national totals and rates by year, outcome-linked search rates by group,
or a force's Section 60 searches by group. Each group keeps its colour
from
[`btg_group_colours()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_group_colours.md)
in every chart. Periods the source does not cover in full, or for which
a force's returns were incomplete, are drawn with hollow markers and
named in the subtitle; nothing is annualised.

## Usage

``` r
btg_plot_trend(x, measure = NULL, highlight = NULL)
```

## Arguments

- x:

  A dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).
  Force- and council-level datasets must be selected down to one area
  with the `force` or `council` argument of
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).

- measure:

  What to draw. The default is the dataset's first measure: `"ratio"` or
  `"rate"` for the comparison datasets; `"stops"` or `"share"` for
  national monthly stops; any total or rate column of `national_year`;
  `"hit_rate"` or `"hit_total"` for outcome-linked search rates;
  `"s60_stops"` for Section 60 searches.

- highlight:

  Optional name of one series (a group) to emphasise. The other series
  are drawn in grey as context.

## Value

An editable `ggplot` with its evidence table, available through
[`btg_figure_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_figure_data.md)
as one row per period and series with `value`, `lower`, `upper`,
`complete` and `months_in_source`, and a saved view that
[`btg_save_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_save_view.md)
and
[`btg_from_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_view.md)
replay.

## Details

Ratios carry their 95% Poisson intervals as vertical lines. Rates per
1,000 residents and counts for an incomplete period are lower simply
because fewer months are covered; the ratio of two rates from the same
months is unaffected by that, which is why incomplete periods are shown
rather than dropped, but marked. Resident populations are fixed at
Census 2021 for every year, so a trend in a rate reflects recorded stops
only, not population change. A ratio is descriptive and does not
establish discrimination.

## Examples

``` r
met <- btg_get_data("force_ethnicity_year", force = "metropolitan")
btg_plot_trend(met)

btg_plot_trend(met, measure = "rate", highlight = "Black")

btg_plot_trend(btg_get_data("national_month_ethnicity"), measure = "share")

btg_plot_trend(btg_get_data("hit_rate_ethnicity_year"))
```
