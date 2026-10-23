# Chart how robust each displayed force's comparison is

Draws the forces the dashboard's ranking chart would display, with three
marks for each: the recorded stop-rate ratio, its 95% Poisson interval
and the range the ratio would take under every allocation of the stops
whose ethnicity was not recorded (see
[`btg_sensitivity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_sensitivity.md)).
A force whose whole range sits on one side of the parity line keeps its
direction whatever the unknown stops turn out to be.

## Usage

``` r
btg_plot_sensitivity(
  x = btg_get_data(),
  n = 10L,
  ranking = c("highest", "lowest", "closest"),
  year = NULL,
  group = NULL,
  highlight = NULL
)
```

## Arguments

- x:

  A dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md):
  `force_disparity` (2025, Black) or `force_ethnicity_year` (any year
  and group it holds).

- n:

  Maximum number of displayed forces, from 1 to 44.

- ranking:

  One of `"highest"`, `"lowest"`, or `"closest"` to parity.

- year:

  The calendar year to draw. `NULL` draws the latest year the source
  covers in full, which is the dashboard's starting year.

- group:

  The group compared with White: `"Black"`, `"Asian"`, `"Mixed"` or
  `"Other"`. `NULL` draws Black.

- highlight:

  Optional Police.uk identifier of one force to draw in the
  selected-force colour, as the dashboard does for its chosen force.

## Value

An editable `ggplot` with a saved evidence specification. The table
behind it, including the bounds, is available with
[`btg_figure_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_figure_data.md),
and the chart can be saved and replayed with
[`btg_save_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_save_view.md)
and
[`btg_from_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_view.md).
It has no page on the dashboard website, so
[`btg_dashboard_url()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_dashboard_url.md)
does not apply to it.

## Details

The selection of forces, their order and their ranks are exactly those
of
[`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md)
with the same arguments. The axis is logarithmic because ratios are
multiplicative and the allocation range can span orders of magnitude
where a group's resident population is small. Sampling intervals and
allocation ranges are drawn as separate marks and are not combined.
Display eligibility does not imply complete or comparable exposure, or
establish discrimination.

## Examples

``` r
btg_plot_sensitivity(btg_get_data())


y <- btg_get_data("force_ethnicity_year")
btg_plot_sensitivity(y, year = 2024, group = "Asian", highlight = "metropolitan")
```
