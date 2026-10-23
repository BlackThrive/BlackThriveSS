# Read a fixed dashboard dataset with coverage and provenance

Reads one dataset from the bundled catalogue, verifies its checksum,
applies the requested selection and returns the rows with their monthly
coverage and provenance. Rates divide recorded events by Census 2021
residents. They are not individual stop probabilities or causal
estimates.

## Usage

``` r
btg_get_data(
  dataset = "force_disparity",
  force = NULL,
  years = NULL,
  groups = NULL,
  council = NULL,
  release = NULL
)
```

## Arguments

- dataset:

  A dataset name from
  [`btg_datasets()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_datasets.md).
  The default, `"force_disparity"`, is the original 2025 Black to White
  force comparison.

- force:

  Optional character vector of exact Police.uk identifiers, such as
  `"metropolitan"`, for force-level datasets. See `x$data$force`.

- years:

  Calendar years to keep. `NULL` keeps every year the dataset holds;
  `force_disparity` holds 2025 only.

- groups:

  Ethnic groups to keep, for datasets with a `group` column. `NULL`
  keeps all of them.

- council:

  Optional character vector of ONS local-authority codes, such as
  `"E09000022"`, for the council-level dataset. See `x$data$council`.

- release:

  A value from
  [`btg_releases()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_releases.md).
  `NULL` selects the dataset's default release; saved views always carry
  an explicit release identifier.

## Value

A `btg_dataset` list containing an ordinary data frame `data`, a
`coverage` data frame of force-month submission statuses (`NULL` for
datasets without one), an explicit `metadata` list and a `selection`
list. Missing force returns remain missing; they are never imputed as
zero stops.

## Details

Force-level comparison datasets hold group and White counts, known and
unknown ethnicity counts, Census populations, rates per 1,000, the rate
ratio, approximate Poisson log-ratio intervals, display eligibility,
ranks within each year and group, and submission coverage. The intervals
condition on recorded counts and fixed denominators: they do not capture
missing-return, classification or exposure uncertainty. `eligible`
reproduces the dashboard's rule (positive finite ratio and at least 200
records with known ethnicity, with resident-rate exclusions). It does
not imply complete reporting. The dashboard verifies monthly submissions
only inside a recent window; earlier months are `unverified`, never
assumed supplied. See
`system.file("NOTES", "data-dictionary.md", package = "BlackThriveSS")`
for every column.

## Examples

``` r
x <- btg_get_data()
head(x$data)
#>               force              force_label  pfa_code year black_stops
#> 1 avon-and-somerset        Avon and Somerset E23000036 2025         672
#> 2      bedfordshire             Bedfordshire E23000026 2025         750
#> 3               btp British Transport Police      <NA> 2025        3607
#> 4    cambridgeshire           Cambridgeshire E23000023 2025         354
#> 5          cheshire                 Cheshire E23000006 2025         469
#> 6    city-of-london          London, City of E23000034 2025         611
#>   white_stops known_ethnicity_stops unknown_ethnicity_stops total_records
#> 1        3952                  5191                    1159          6350
#> 2        2159                  3920                     259          4179
#> 3        6942                 12586                     134         12720
#> 4        1930                  2728                     159          2887
#> 5       11243                 12362                     469         12831
#> 6         722                  1755                      34          1789
#>   black_population white_population months_supplied months_missing
#> 1            37844          1584583              12              0
#> 2            39601           507517              12              0
#> 3               NA               NA              12              0
#> 4            18496           763744              12              0
#> 5             6616          1038185              12              0
#> 6              232             5955              12              0
#>   months_unverified     coverage_status small_population comparable    ratio
#> 1                 0 all_months_supplied            FALSE       TRUE 7.119841
#> 2                 0 all_months_supplied            FALSE       TRUE 4.451979
#> 3                 0 all_months_supplied            FALSE      FALSE       NA
#> 4                 0 all_months_supplied            FALSE       TRUE 7.573837
#> 5                 0 all_months_supplied            FALSE       TRUE 6.545908
#> 6                 0 all_months_supplied             TRUE      FALSE       NA
#>   white_rate black_rate ci_upper ci_lower eligible rank
#> 1   2.494032   17.75711 7.726597 6.560732     TRUE   14
#> 2   4.254045   18.93892 4.837617 4.097082     TRUE   32
#> 3         NA         NA       NA       NA    FALSE   NA
#> 4   2.527025   19.13927 8.482644 6.762397     TRUE   11
#> 5  10.829476   70.88875 7.179367 5.968341     TRUE   17
#> 6         NA         NA       NA       NA    FALSE   NA
btg_get_data(force = "metropolitan")$data
#>          force         force_label  pfa_code year black_stops white_stops
#> 1 metropolitan Metropolitan Police E23000001 2025       56116       48798
#>   known_ethnicity_stops unknown_ethnicity_stops total_records black_population
#> 1                129812                    8826        138638          1188137
#>   white_population months_supplied months_missing months_unverified
#> 1          4725217              12              0                 0
#>       coverage_status small_population comparable    ratio white_rate
#> 1 all_months_supplied            FALSE       TRUE 4.573408   10.32714
#>   black_rate ci_upper ci_lower eligible rank
#> 1   47.23024 4.629229  4.51826     TRUE   30

y <- btg_get_data("force_ethnicity_year", groups = "Black", years = 2023:2025)
head(y$data[c("force_label", "year", "ratio", "coverage_status")])
#>                force_label year    ratio coverage_status
#> 1        Avon and Somerset 2023 7.572790      unverified
#> 2             Bedfordshire 2023 4.227280      unverified
#> 3 British Transport Police 2023       NA      unverified
#> 4           Cambridgeshire 2023 5.949912      unverified
#> 5                 Cheshire 2023 5.092750      unverified
#> 6          London, City of 2023       NA      unverified
btg_get_data("national_year")$data[c("year", "stops", "arrest_rate")]
#>   year  stops arrest_rate
#> 1 2018 319569    15.72149
#> 2 2019 524424    12.80929
#> 3 2020 676628    11.38765
#> 4 2021 541523    12.22386
#> 5 2022 477044    12.81140
#> 6 2023 449005    13.95909
#> 7 2024 471542    15.13587
#> 8 2025 505586    14.66833
#> 9 2026 275024    15.49647
```
