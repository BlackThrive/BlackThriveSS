# Bound a comparison under every allocation of unknown-ethnicity stops

The recorded stop-rate ratio leaves out stops whose ethnicity was not
recorded. This function reports the range the ratio would take if every
one of those stops belonged to the compared group, or every one of them
to the White group, which are the two extreme allocations. Any
allocation of the unknown stops between the groups gives a ratio inside
that range, and allocating them in the same proportions as the recorded
stops leaves the ratio unchanged. For force-level datasets the function
also reports the best and worst rank a force could hold if every force's
unknown stops were allocated in its favour or against it.

## Usage

``` r
btg_sensitivity(x, year = NULL, group = NULL)
```

## Arguments

- x:

  A comparison dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md):
  `force_disparity`, `force_ethnicity_year` or `council_ethnicity_year`.

- year:

  Optional single calendar year to keep. `NULL` keeps every year in the
  selection.

- group:

  Optional single ethnic group to keep. `NULL` keeps every group in the
  selection.

## Value

A data frame with one row per area, year and group: the recorded counts,
`unknown_share` (unknown-ethnicity stops as a share of all records), the
recorded `ratio` with its Poisson interval, `ratio_min` (every unknown
stop assigned to White), `ratio_max` (every unknown stop assigned to the
compared group) and `parity_direction`: `"above"` when the whole range
exceeds 1, `"below"` when it is entirely under 1, and `"sensitive"` when
the side of parity depends on the unknown stops. Force rows add
`eligible`, `rank`, `rank_best`, `rank_worst` (ranks among the forces
eligible in the recorded data, under the most favourable and least
favourable allocations) and the coverage columns. Missing returns remain
missing. The attributes `dataset` and `release` identify the evidence.

## Details

The sampling interval and the allocation range answer different
questions and are deliberately not combined. The interval conditions on
the recorded counts; the range conditions on nothing about the unknown
stops except their number. Neither captures missing monthly returns,
classification differences between officer-defined and Census ethnicity,
or the choice of resident populations as the exposure measure, and
neither establishes discrimination. Council rows carry no rank or
eligibility, as in the dataset.

## Examples

``` r
s <- btg_sensitivity(btg_get_data())
head(s[c("force_label", "ratio", "ratio_min", "ratio_max", "parity_direction")])
#>        force_label    ratio ratio_min ratio_max parity_direction
#> 1          Norfolk 9.971068  9.616471 13.788563            above
#> 2 Devon & Cornwall 9.748324  9.336930 20.940844            above
#> 3      West Mercia 9.673905  9.134508 16.137257            above
#> 4           Sussex 9.461250  9.338614 10.414488            above
#> 5           Surrey 8.612550  8.419686  9.743609            above
#> 6           Dorset 8.217899  6.250789 51.673153            above
table(s$parity_direction, useNA = "ifany")
#> 
#> above  <NA> 
#>    40     4 

y <- btg_get_data("force_ethnicity_year", years = 2025, groups = "Asian")
head(btg_sensitivity(y)[c("force_label", "rank", "rank_best", "rank_worst")])
#>       force_label rank rank_best rank_worst
#> 1     West Mercia    1         1         11
#> 2 North Yorkshire    2         2         24
#> 3   Staffordshire    3         1         30
#> 4  West Yorkshire    4         2         29
#> 5         Cumbria    5         1         32
#> 6 South Yorkshire    6         1         31
```
