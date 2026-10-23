# Build an evidence profile for one force or council

Gathers, for one area and one year, everything the package can say with
its bundled evidence: each group's recorded stops, rate per 1,000
residents and ratio to White residents with its interval; the force's
rank among eligible forces, how much sampling variability moves that
rank
([`btg_rank_stability()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_rank_stability.md))
and how far the allocation of unknown-ethnicity stops could move the
ratio
([`btg_sensitivity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_sensitivity.md));
the change since the previous year
([`btg_change()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_change.md));
monthly reporting coverage; Section 60 searches; and national context.
Each finding is also written as a plain statement that carries its own
qualification, ready for a briefing.

## Usage

``` r
btg_profile(
  force = NULL,
  council = NULL,
  year = NULL,
  release = NULL,
  draws = 2000L,
  seed = 1L
)
```

## Arguments

- force:

  A Police.uk force identifier such as `"metropolitan"`, or

- council:

  an ONS local-authority code such as `"E09000022"`. Name one of the
  two.

- year:

  The calendar year to profile. `NULL` uses the latest year the source
  covers in full.

- release:

  A value from
  [`btg_releases()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_releases.md);
  `NULL` uses the default catalogue release.

- draws, seed:

  Simulation settings passed to
  [`btg_rank_stability()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_rank_stability.md).

## Value

A list of class `btg_profile` with `area`, `year`, `release`,
`source_month`, `comparisons` (one row per group), `stability` (forces
only), `change`, `coverage` (forces only), `section60` (forces only),
`national`, `statements`, `topics` and `caveats`. Each statement is
named by its topic (`coverage`, a group, `section60` or `national`), and
`topics` gives the heading for each, which
[`btg_report()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_report.md)
and the print method use to group the statements.

## Details

Ranks, rank intervals and allocation bounds are computed against every
force in the release, not only the profiled one. Councils carry no rank,
eligibility or coverage, as in the dataset, and their counts depend on
published stop coordinates.

## Examples

``` r
p <- btg_profile(force = "metropolitan", draws = 500)
p
#> BlackThriveSS evidence profile: Metropolitan Police, 2025
#> Release dashboard-2026-07-catalogue-bacf49c2a48d (source month 2026-07)
#> 
#> Reporting coverage
#> * Metropolitan Police supplied stop and search returns for all 12 months of
#>   2025.
#> 
#> Black people compared with White residents
#> * Recorded stops of Black people in 2025: 47.2 per 1,000 Black residents,
#>   4.6x the rate for White residents (10.3 per 1,000), 95% interval 4.5x to
#>   4.6x, from 56,116 and 48,798 recorded stops.
#> * That Black:White ratio ranks 30th of 40 forces with an eligible comparison;
#>   sampling variability alone puts the rank between 28 and 32.
#> * 8,826 of the 138,638 recorded stops in 2025 (6.4%) have no recorded
#>   ethnicity. Counting every one of them as White would put the Black:White
#>   ratio at 3.9x; counting every one as Black would put it at 5.3x. The ratio
#>   stays above parity under every allocation.
#> * Compared with 2024, the Black:White ratio in 2025 was 10% higher (95%
#>   interval 1.08x to 1.12x the earlier ratio); both years are covered in full.
#> 
#> Asian people compared with White residents
#> * Recorded stops of Asian people in 2025: 10.8 per 1,000 Asian residents,
#>   1.0x the rate for White residents (10.3 per 1,000), 95% interval 1.0x to
#>   1.1x, from 19,557 and 48,798 recorded stops.
#> * That Asian:White ratio ranks 36th of 40 forces with an eligible comparison;
#>   sampling variability alone puts the rank between 34 and 37.
#> * 8,826 of the 138,638 recorded stops in 2025 (6.4%) have no recorded
#>   ethnicity. Counting every one of them as White would put the Asian:White
#>   ratio at 0.9x; counting every one as Asian would put it at 1.5x. Which side
#>   of parity the ratio falls on depends on those stops.
#> * Compared with 2024, the Asian:White ratio in 2025 was 6% higher (95%
#>   interval 1.03x to 1.09x the earlier ratio); both years are covered in full.
#> 
#> Mixed people compared with White residents
#> * No stops of Mixed people were recorded under officer-defined ethnicity in
#>   2025; White residents were stopped at 10.3 per 1,000.
#> * The Mixed:White comparison does not meet the dashboard's display rule (a
#>   positive ratio from at least 200 stops with known ethnicity and comparable
#>   resident populations), so it carries no rank.
#> 
#> People of other ethnic groups compared with White residents
#> * Recorded stops of Other people in 2025: 9.6 per 1,000 Other residents, 0.9x
#>   the rate for White residents (10.3 per 1,000), 95% interval 0.9x to 1.0x,
#>   from 5,341 and 48,798 recorded stops.
#> * That Other:White ratio ranks 35th of 39 forces with an eligible comparison;
#>   sampling variability alone puts the rank between 32 and 36.
#> * 8,826 of the 138,638 recorded stops in 2025 (6.4%) have no recorded
#>   ethnicity. Counting every one of them as White would put the Other:White
#>   ratio at 0.8x; counting every one as Other would put it at 2.5x. Which side
#>   of parity the ratio falls on depends on those stops.
#> * Compared with 2024, the Other:White ratio in 2025 was 16% higher (95%
#>   interval 1.11x to 1.21x the earlier ratio); both years are covered in full.
#> 
#> Section 60 searches
#> * Metropolitan Police recorded 3,024 searches under Section 60 in 2025, 73%
#>   of them of Black people.
#> 
#> National context
#> * Across England and Wales, 505,586 stops were recorded in 2025; 14.7% led to
#>   an arrest, and the share of searches whose outcome was linked to what was
#>   searched for was 47.7% for Black people and 49.1% for White people.
#> 
#> Tables: $comparisons, $change, $coverage, $section60, $national; qualifications: $caveats
p$comparisons[c("group", "ratio", "rank", "rank_lower", "rank_upper", "parity_direction")]
#>   group     ratio rank rank_lower rank_upper parity_direction
#> 1 Black 4.5734077   30         28         32            above
#> 2 Asian 1.0426963   36         34         37        sensitive
#> 3 Mixed 0.0000000   NA         NA         NA        sensitive
#> 4 Other 0.9296962   35         32         36        sensitive
```
