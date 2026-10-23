# List fixed releases available offline

List fixed releases available offline

## Usage

``` r
btg_releases()
```

## Value

A data frame with one row per bundled release: its identifier, the
Police.uk source month, when the dashboard built its aggregates, and the
datasets the release contains.

## Examples

``` r
btg_releases()
#>                                    release source_month   dashboard_built_at
#> 1      dashboard-2026-07-2025-99a88b69f2d6      2026-07 2026-09-16T07:12:19Z
#> 2 dashboard-2026-07-catalogue-bacf49c2a48d      2026-07 2026-09-16T07:12:19Z
#>                                                                                                                               datasets
#> 1                                                                                                                      force_disparity
#> 2 force_ethnicity_year, national_year, national_month_ethnicity, council_ethnicity_year, hit_rate_ethnicity_year, section60_force_year
```
