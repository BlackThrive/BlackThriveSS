# Chart how forces' stop-rate ratios changed between two years

A dumbbell chart of one group's ratio in two years for the forces whose
change was largest, from
[`btg_change()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_change.md).
The light marker is the earlier year and the dark marker the later one;
the label gives the percentage change, and the subtitle says how many of
the displayed changes have 95% intervals that exclude no change.

## Usage

``` r
btg_plot_change(
  x,
  from = NULL,
  to = NULL,
  group = NULL,
  n = 10L,
  order = c("largest", "increase", "decrease")
)
```

## Arguments

- x:

  A comparison dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md)
  holding more than one year: `force_ethnicity_year` or
  `council_ethnicity_year`.

- from, to:

  The two calendar years. `to` defaults to the latest year the source
  covers in full and `from` to the year before it; both must be in the
  selection.

- group:

  The group compared with White. `NULL` draws Black when the selection
  holds it, otherwise its first group.

- n:

  Maximum number of displayed forces, from 1 to 44.

- order:

  `"largest"` shows the forces with the largest proportional change in
  either direction; `"increase"` and `"decrease"` show the largest rises
  or falls.

## Value

An editable `ggplot` with its evidence table, from
[`btg_figure_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_figure_data.md),
and a replayable saved view.

## Details

Only forces with a dashboard-eligible ratio in both years are displayed.
Forces whose returns do not cover both years in full are marked with an
asterisk, because fewer months lower counts but not, under uniform
reporting, the ratio. Changes are descriptive: see
[`btg_change()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_change.md)
for what they can and cannot show.

## Examples

``` r
y <- btg_get_data("force_ethnicity_year")
btg_plot_change(y)

btg_plot_change(y, from = 2023, to = 2025, group = "Asian", order = "decrease")
```
