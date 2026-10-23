# Link a chart to the same view on the dashboard

Builds the dashboard address that opens the Disparity page at the year,
group, display and selected force a chart was drawn from. The link
selects a view on the live website; it does not freeze the numbers,
which the website recomputes from its current release. The chart's own
numbers stay pinned in the saved view and the package snapshot.

## Usage

``` r
btg_dashboard_url(
  p,
  format = c("parameters", "state"),
  base = btg_dashboard_base()
)
```

## Arguments

- p:

  A plot from
  [`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md),
  [`btg_from_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_view.md)
  or
  [`btg_from_url()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_url.md).

- format:

  `"parameters"` (the default) writes the per-parameter form that every
  deployed dashboard version reads; `"state"` writes the newer JSON
  state form, which also carries the ranking order and the source month
  the chart came from.

- base:

  The dashboard address; see
  [`btg_dashboard_base()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_dashboard_base.md).

## Value

A single URL.

## Details

The dashboard page defaults to its map view with the chart beneath;
links from this function ask for the chart view. The ranking order is
only carried by the `"state"` form. A `highlight` force becomes the
page's selected force.

## Examples

``` r
p <- btg_plot_disparity(highlight = "metropolitan")
btg_dashboard_url(p)
#> [1] "https://bgtresearch-stop-search-dashboard.share.connect.posit.cloud/?tab=disparity&year=2025&eth=Black&def=std&view=chart&force=Metropolitan%20Police"
btg_dashboard_url(p, format = "state")
#> [1] "https://bgtresearch-stop-search-dashboard.share.connect.posit.cloud/?tab=disparity&v=1&state=%7B%22year%22%3A2025%2C%22eth%22%3A%22Black%22%2C%22def%22%3A%22std%22%2C%22view%22%3A%22chart%22%2C%22ranking_view%22%3A%22highest%22%2C%22_focus%22%3A%22Metropolitan%20Police%22%7D&release=2026-07"
```
