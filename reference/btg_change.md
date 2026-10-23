# Change in stop-rate ratios between two years

Compares each area's ratio in one year with the same group's ratio in
another, as the multiplicative change `ratio_to / ratio_from` with a 95%
interval on the assumption that the four recorded counts are independent
Poisson counts. Coverage of both years is reported beside the change, so
that a change between a complete year and an incomplete one is not read
as a change in policing.

## Usage

``` r
btg_change(x, from = NULL, to = NULL)
```

## Arguments

- x:

  A comparison dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md)
  holding more than one year: `force_ethnicity_year` or
  `council_ethnicity_year`.

- from, to:

  The two calendar years. `to` defaults to the latest year the source
  covers in full and `from` to the year before it; both must be in the
  selection.

## Value

A data frame with one row per area and group: the two ratios, the
`change` and its interval (`change_lower`, `change_upper`),
`change_direction` (`"higher"`, `"lower"` or `"unclear"` according to
whether the interval excludes 1, `NA` where a ratio is missing), the
coverage status and months covered of both years, and
`comparable_coverage`, which is `TRUE` only when both years are covered
in full by supplied or unverified returns. The attributes `dataset` and
`release` identify the evidence.

## Details

A change in a ratio between two years is a change in recorded stops
relative to fixed Census 2021 populations. It can reflect recording
practice, the share of stops with unknown ethnicity, changes in who is
present in an area and changes in policing, which this table does not
separate. The interval describes sampling variability only.

## Examples

``` r
y <- btg_get_data("force_ethnicity_year", groups = "Black")
ch <- btg_change(y)
head(ch[c("force_label", "ratio_from", "ratio_to", "change", "change_direction")])
#>                force_label ratio_from ratio_to    change change_direction
#> 1        Avon and Somerset   6.824324 7.119841 1.0433035          unclear
#> 2             Bedfordshire   4.586762 4.451979 0.9706147          unclear
#> 3 British Transport Police         NA       NA        NA             <NA>
#> 4           Cambridgeshire   6.011442 7.573837 1.2599035           higher
#> 5                 Cheshire   6.017040 6.545908 1.0878951          unclear
#> 6          London, City of         NA       NA        NA             <NA>
table(ch$change_direction, useNA = "ifany")
#> 
#>  higher unclear    <NA> 
#>       9      31       4 
```
