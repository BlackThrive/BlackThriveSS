# Save the evidence specification for a reproducible chart

Save the evidence specification for a reproducible chart

## Usage

``` r
btg_save_view(p, path, overwrite = FALSE)
```

## Arguments

- p:

  A plot from
  [`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md),
  [`btg_from_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_view.md)
  or
  [`btg_from_url()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_url.md).

- path:

  Path for the JSON view file.

- overwrite:

  Whether to replace an existing file. Defaults to `FALSE`.

## Value

The file path, invisibly.

## Details

Saves release identifiers, SHA-256 checksums, the dataset selection, the
chart's settings and its chart version. User-added ggplot styling is not
serialised. Numerical replay is guaranteed for supported versions; pixel
identity requires the same fonts, graphics dependencies and rendering
settings. No R code is stored or run.

## Examples

``` r
path <- tempfile(fileext = ".json")
btg_save_view(btg_plot_disparity(), path)
btg_from_view(path)

unlink(path)
```
