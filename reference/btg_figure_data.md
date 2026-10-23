# Extract the original numerical table behind a chart

Extract the original numerical table behind a chart

## Usage

``` r
btg_figure_data(p)
```

## Arguments

- p:

  A plot returned by
  [`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md),
  [`btg_from_view()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_view.md)
  or
  [`btg_from_url()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_from_url.md).

## Value

An ordinary data frame in display order, including counts, denominators,
ratios, approximate intervals and reporting coverage.

## Details

This returns the original evidence table. User-added ggplot layers and
transformations do not change that table or the saved view.

## Examples

``` r
btg_figure_data(btg_plot_disparity())
#>                 force      force_label  pfa_code year black_stops white_stops
#> 1             norfolk          Norfolk E23000024 2025         175        1817
#> 2  devon-and-cornwall Devon & Cornwall E23000035 2025         189        4925
#> 3         west-mercia      West Mercia E23000016 2025         229        2591
#> 4              sussex           Sussex E23000033 2025         665        5102
#> 5              surrey           Surrey E23000031 2025         731        4191
#> 6              dorset           Dorset E23000039 2025          66        1109
#> 7     nottinghamshire  Nottinghamshire E23000019 2025         782        2245
#> 8             cumbria          Cumbria E23000002 2025         121        6146
#> 9        warwickshire     Warwickshire E23000017 2025         111         941
#> 10            suffolk          Suffolk E23000025 2025         233        2120
#>    known_ethnicity_stops unknown_ethnicity_stops total_records black_population
#> 1                   2122                      67          2189             8376
#> 2                   5286                     217          5503             6768
#> 3                   3298                     153          3451            11185
#> 4                   6331                      67          6398            21388
#> 5                   5576                      96          5672            20832
#> 6                   1234                     349          1583             5315
#> 7                   3469                      23          3492            42141
#> 8                   6565                    2267          8832             1194
#> 9                   1223                      78          1301             8018
#> 10                  2607                      73          2680            10168
#>    white_population months_supplied months_missing months_unverified
#> 1            867152              11              1                 0
#> 2           1719233              12              0                 0
#> 3           1224249              12              0                 0
#> 4           1552521              12              0                 0
#> 5           1028639              12              0                 0
#> 6            733925              12              0                 0
#> 7            980656              12              0                 0
#> 8            488025              12              0                 0
#> 9            531672              12              0                 0
#> 10           708272              11              1                 0
#>        coverage_status small_population comparable    ratio white_rate
#> 1         partial_year            FALSE       TRUE 9.971068   2.095365
#> 2  all_months_supplied            FALSE       TRUE 9.748324   2.864650
#> 3  all_months_supplied            FALSE       TRUE 9.673905   2.116400
#> 4  all_months_supplied            FALSE       TRUE 9.461250   3.286268
#> 5  all_months_supplied            FALSE       TRUE 8.612550   4.074316
#> 6  all_months_supplied            FALSE       TRUE 8.217899   1.511054
#> 7  all_months_supplied            FALSE       TRUE 8.105919   2.289284
#> 8  all_months_supplied            FALSE       TRUE 8.046936  12.593617
#> 9  all_months_supplied            FALSE       TRUE 7.821879   1.769888
#> 10        partial_year            FALSE       TRUE 7.655695   2.993200
#>    black_rate  ci_upper ci_lower eligible rank           axis_label value_label
#> 1    20.89303 11.644313 8.538263     TRUE    1        #1  Norfolk *       10.0x
#> 2    27.92553 11.272561 8.430189     TRUE    2 #2  Devon & Cornwall        9.7x
#> 3    20.47385 11.073475 8.451227     TRUE    3      #3  West Mercia        9.7x
#> 4    31.09220 10.257510 8.726800     TRUE    4           #4  Sussex        9.5x
#> 5    35.09025  9.316438 7.961842     TRUE    5           #5  Surrey        8.6x
#> 6    12.41769 10.534385 6.410803     TRUE    6           #6  Dorset        8.2x
#> 7    18.55675  8.793205 7.472352     TRUE    7  #7  Nottinghamshire        8.1x
#> 8   101.34003  9.633199 6.721877     TRUE    8          #8  Cumbria        8.0x
#> 9    13.84385  9.522169 6.425195     TRUE    9     #9  Warwickshire        7.8x
#> 10   22.91503  8.764622 6.687072     TRUE   10       #10  Suffolk *        7.7x
```
