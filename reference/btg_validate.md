# Validate the integrity and internal consistency of a fixed dataset

Checks the bundled checksums, unchanged provenance, record totals,
monthly coverage and stored calculations. This is not a certification
that all police events were reported or that the exposure assumptions
are correct.

## Usage

``` r
btg_validate(x = btg_get_data())
```

## Arguments

- x:

  A dataset returned by
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).
  Every catalogue dataset is supported; the checks that apply depend on
  what the dataset holds.

## Value

A data frame with `check`, `passed` and `detail` columns. Changed data
or provenance raises an error. Internal consistency checks return
`FALSE` for failures; use `stopifnot(all(btg_validate(x)$passed))` in a
workflow.

## Examples

``` r
checks <- btg_validate(btg_get_data())
checks
#>                check passed
#> 1  release_integrity   TRUE
#> 2             schema   TRUE
#> 3              types   TRUE
#> 4               keys   TRUE
#> 5             period   TRUE
#> 6             counts   TRUE
#> 7    missing_returns   TRUE
#> 8   coverage_summary   TRUE
#> 9     monthly_totals   TRUE
#> 10  ethnicity_totals   TRUE
#> 11 derived_estimates   TRUE
#> 12     rank_encoding   TRUE
#>                                                                                    detail
#> 1                       SHA-256 payloads and selected evidence match the bundled release.
#> 2                                   Required evidence and monthly coverage columns exist.
#> 3                             Counts, rates, labels and flags use their documented types.
#> 4                                       One annual row and unique monthly keys per force.
#> 5                Every selected force has all 12 coverage entries for calendar year 2025.
#> 6                  Counts and Census populations are nonnegative whole values or missing.
#> 7                    Missing or unverified returns have missing record counts, not zeros.
#> 8                   Annual submission counts and coverage labels match the monthly table.
#> 9                           Annual recorded events reconcile to supplied monthly returns.
#> 10        Known and unknown ethnicity reconcile; group counts do not exceed known counts.
#> 11 Stored rates, approximate intervals and eligibility match the documented calculations.
#> 12    Only eligible rows carry positive integer ranks; subsets retain full-release ranks.
stopifnot(all(checks$passed))
btg_validate(btg_get_data("force_ethnicity_year", years = 2025))
#>                check passed
#> 1  release_integrity   TRUE
#> 2             schema   TRUE
#> 3               keys   TRUE
#> 4             counts   TRUE
#> 5   ethnicity_totals   TRUE
#> 6    missing_returns   TRUE
#> 7   coverage_summary   TRUE
#> 8     monthly_totals   TRUE
#> 9  derived_estimates   TRUE
#> 10     rank_encoding   TRUE
#>                                                                                                            detail
#> 1                                               SHA-256 payloads and selected evidence match the bundled release.
#> 2                                                                                    Key and count columns exist.
#> 3                                                                           Every row has a unique, complete key.
#> 4                                          Counts and Census populations are nonnegative whole values or missing.
#> 5                                 Known and unknown ethnicity reconcile; group counts do not exceed known counts.
#> 6                                            Missing or unverified returns have missing record counts, not zeros.
#> 7                                           Annual submission counts and coverage labels match the monthly table.
#> 8                        Annual recorded events reconcile to supplied monthly returns where the year is verified.
#> 9                          Stored rates, approximate intervals and eligibility match the documented calculations.
#> 10 Only eligible rows carry positive integer ranks; subsets retain full-release ranks within each year and group.
```
