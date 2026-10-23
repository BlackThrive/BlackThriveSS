# Discover bundled dashboard datasets

One row per dataset in the bundled catalogue, with the release that
[`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md)
reads by default.

## Usage

``` r
btg_datasets()
```

## Value

A data frame with `dataset`, `title`, `level` (`force`, `council` or
`national`), `from`, `to` (calendar years), `groups` (comma-separated
ethnic groups, empty when the dataset has none), `coverage` (whether a
monthly submission table accompanies it) and `release`.

## Examples

``` r
btg_datasets()
#>                    dataset
#> 1          force_disparity
#> 2     force_ethnicity_year
#> 3            national_year
#> 4 national_month_ethnicity
#> 5   council_ethnicity_year
#> 6  hit_rate_ethnicity_year
#> 7     section60_force_year
#>                                                          title    level from
#> 1          Black to White stop-rate comparison by police force    force 2025
#> 2 Group to White stop-rate comparison by police force and year    force 2018
#> 3                    National totals and outcome rates by year national 2018
#> 4          National monthly stops by officer-defined ethnicity national 2018
#> 5      Group to White stop-rate comparison by council and year  council 2018
#> 6    National outcome-linked search rate by ethnicity and year national 2018
#> 7      Section 60 searches by police force, year and ethnicity    force 2018
#>     to                                     groups coverage
#> 1 2025                                      Black     TRUE
#> 2 2026                 Asian, Black, Mixed, Other     TRUE
#> 3 2026                                               FALSE
#> 4 2026 Asian, Black, Mixed, Other, White, Unknown    FALSE
#> 5 2026                 Asian, Black, Mixed, Other    FALSE
#> 6 2026 Asian, Black, Mixed, Other, White, Unknown    FALSE
#> 7 2026 Asian, Black, Mixed, Other, White, Unknown     TRUE
#>                                    release
#> 1      dashboard-2026-07-2025-99a88b69f2d6
#> 2 dashboard-2026-07-catalogue-bacf49c2a48d
#> 3 dashboard-2026-07-catalogue-bacf49c2a48d
#> 4 dashboard-2026-07-catalogue-bacf49c2a48d
#> 5 dashboard-2026-07-catalogue-bacf49c2a48d
#> 6 dashboard-2026-07-catalogue-bacf49c2a48d
#> 7 dashboard-2026-07-catalogue-bacf49c2a48d
```
