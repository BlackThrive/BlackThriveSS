# Summarise robustness across every year and group

One row per year and group of a force-level comparison dataset: how many
forces have counts, how many meet the display rule, how many of those
keep their side of parity under every allocation of unknown-ethnicity
stops, how large the unknown share typically is, how wide the sampling
rank intervals are and how many forces have full-year returns. It is the
table a study of robustness starts from, built from
[`btg_sensitivity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_sensitivity.md)
and
[`btg_rank_stability()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_rank_stability.md).

## Usage

``` r
btg_robustness_summary(x, draws = 2000L, seed = 1L, top = 10L, certain = 0.9)
```

## Arguments

- x:

  A force-level comparison dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md):
  `force_disparity` or `force_ethnicity_year`.

- draws:

  Number of simulated tables per year and group, at least 200.

- seed:

  Seed for the simulation.

- top:

  Rank threshold for `prob_top`: the probability that a force ranks
  within the top `top` forces, which is the number the dashboard's
  ranking chart displays by default.

- certain:

  The `prob_top` at or above which a force's place in the top `top` is
  counted as settled.

## Value

A data frame with `year`, `group`, `forces` (with counts), `eligible`,
`above`, `below`, `sensitive`, `median_unknown_share`,
`max_unknown_share`, `median_rank_interval` (upper minus lower),
`settled_top` (forces whose `prob_top` is at least `certain`),
`full_year_returns` (forces with all twelve months supplied) and
`months_in_source`. The attributes `draws`, `seed`, `top`, `certain`,
`dataset` and `release` record the settings and evidence.

## Examples

``` r
y <- btg_get_data("force_ethnicity_year", years = 2024:2025, groups = c("Black", "Asian"))
btg_robustness_summary(y, draws = 300)
#>   year group forces eligible above below sensitive median_unknown_share
#> 1 2024 Asian     42       39    31     1         7           0.04906426
#> 2 2024 Black     42       39    39     0         0           0.04906426
#> 3 2025 Asian     42       40    32     1         7           0.05122450
#> 4 2025 Black     42       40    40     0         0           0.05122450
#>   max_unknown_share median_rank_interval settled_top full_year_returns
#> 1         0.9990545                 10.0           7                40
#> 2         0.9990545                  6.0           8                40
#> 3         0.3182773                  8.5           8                37
#> 4         0.3182773                  7.0           5                37
#>   months_in_source
#> 1               12
#> 2               12
#> 3               12
#> 4               12
```
