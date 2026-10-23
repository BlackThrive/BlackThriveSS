# Inspect monthly submission coverage

Inspect monthly submission coverage

## Usage

``` r
btg_coverage(x)
```

## Arguments

- x:

  A dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).

## Value

A data frame of force-month submission statuses and available records,
or `NULL` with a message for datasets without a coverage table. A
supplied return does not certify that every event was recorded; an
`unverified` month lies outside the window the dashboard checks.

## Examples

``` r
btg_coverage(btg_get_data(force = "metropolitan"))
#>           force         force_label   month   status records
#> 1  metropolitan Metropolitan Police 2025-01 supplied   11634
#> 2  metropolitan Metropolitan Police 2025-02 supplied   10489
#> 3  metropolitan Metropolitan Police 2025-03 supplied   11116
#> 4  metropolitan Metropolitan Police 2025-04 supplied   10779
#> 5  metropolitan Metropolitan Police 2025-05 supplied   10688
#> 6  metropolitan Metropolitan Police 2025-06 supplied   10663
#> 7  metropolitan Metropolitan Police 2025-07 supplied   11254
#> 8  metropolitan Metropolitan Police 2025-08 supplied   14899
#> 9  metropolitan Metropolitan Police 2025-09 supplied   11151
#> 10 metropolitan Metropolitan Police 2025-10 supplied   11749
#> 11 metropolitan Metropolitan Police 2025-11 supplied   12355
#> 12 metropolitan Metropolitan Police 2025-12 supplied   11861
```
