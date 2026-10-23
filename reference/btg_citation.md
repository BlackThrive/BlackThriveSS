# Cite a fixed evidence release

Cite a fixed evidence release

## Usage

``` r
btg_citation(x)
```

## Arguments

- x:

  A dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).

## Value

A character string identifying the package, data release and sources.

## Examples

``` r
btg_citation(btg_get_data())
#> [1] "Black Thrive Global (2026). BlackThriveSS development snapshot, release dashboard-2026-07-2025-99a88b69f2d6, dataset force_disparity (Black to White stop-rate comparison by police force). Police.uk stop-and-search records and ONS Census 2021 resident populations. Contains public sector information licensed under the Open Government Licence v3.0. https://data.police.uk/about/ ; https://www.nomisweb.co.uk/sources/census_2021"
```
