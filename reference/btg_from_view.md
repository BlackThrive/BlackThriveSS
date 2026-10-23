# Reproduce a chart from a pinned view file

Reproduce a chart from a pinned view file

## Usage

``` r
btg_from_view(path)
```

## Arguments

- path:

  A local JSON file created by
  [`btg_save_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_save_view.md).

## Value

A ggplot with the original evidence table and saved specification.

## Details

Unknown releases, checksums, fields or chart versions fail explicitly.
Files cannot trigger downloads or execute code. Views written by earlier
package versions (schema 1) replay unchanged. A view names its chart, so
a view saved from
[`btg_plot_sensitivity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_sensitivity.md),
[`btg_plot_trend()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_trend.md)
or
[`btg_plot_change()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_change.md)
replays that chart with its settings. A dashboard link is not a view
file; use
[`btg_from_url()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_url.md)
for links.

## Examples

``` r
file <- system.file("examples", "disparity-2025.json", package = "BlackThriveSS")
btg_from_view(file)
```
