# Estimate how stable each force's rank is under sampling variability

Ranks in a league table are far less certain than the ratios they order.
This function redraws the recorded group and White counts of every
eligible force from Poisson distributions with the recorded counts as
means, re-ranks the forces in each draw and summarises where each
force's rank falls. The draws use a fixed seed, so the result is
reproducible, and the caller's random number state is left untouched.

## Usage

``` r
btg_rank_stability(
  x,
  year = NULL,
  group = NULL,
  draws = 2000L,
  seed = 1L,
  top = 10L
)
```

## Arguments

- x:

  A force-level comparison dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md):
  `force_disparity` or `force_ethnicity_year`.

- year:

  Optional single calendar year to keep.

- group:

  Optional single ethnic group to keep.

- draws:

  Number of simulated tables per year and group, at least 200.

- seed:

  Seed for the simulation.

- top:

  Rank threshold for `prob_top`: the probability that a force ranks
  within the top `top` forces, which is the number the dashboard's
  ranking chart displays by default.

## Value

A data frame of the dashboard-eligible forces with their recorded
`ratio` and `rank`, the 2.5th and 97.5th percentiles of the simulated
rank (`rank_lower`, `rank_upper`) and `prob_top`. Ranks are among the
eligible forces of the same year and group. The attributes `draws`,
`seed`, `top`, `dataset` and `release` record the settings and evidence.

## Details

The simulation conditions on the fixed Census populations and on the
recorded counts, which is the same model behind the Poisson intervals in
the dataset. It describes sampling variability only: the allocation of
unknown-ethnicity stops is examined separately by
[`btg_sensitivity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_sensitivity.md),
and missing monthly returns, classification and exposure choices are not
simulated. Results depend on R's default random number generator.

## Examples

``` r
r <- btg_rank_stability(btg_get_data(), draws = 500)
head(r[c("force_label", "ratio", "rank", "rank_lower", "rank_upper", "prob_top")])
#>        force_label    ratio rank rank_lower rank_upper prob_top
#> 1          Norfolk 9.971068    1          1          6    1.000
#> 2 Devon & Cornwall 9.748324    2          1          7    1.000
#> 3      West Mercia 9.673905    3          1          6    1.000
#> 4           Sussex 9.461250    4          1          6    1.000
#> 5           Surrey 8.612550    5          3          9    0.994
#> 6           Dorset 8.217899    6          1         18    0.704
```
