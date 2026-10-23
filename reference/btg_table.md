# Set a table for a briefing or report

Formats a data frame for the document being knitted, in the style the
package's briefings use: an HTML table that the briefing stylesheet lays
out, a Word table that takes the reference document's table style, or a
booktabs table in PDF. Numeric columns are right-aligned and text
columns left-aligned unless `align` says otherwise. Outside a knitting
session it returns a plain Markdown table.

## Usage

``` r
btg_table(x, caption = NULL, align = NULL, digits = 1)
```

## Arguments

- x:

  A data frame.

- caption:

  Optional caption.

- align:

  Optional alignment string or vector as
  [`knitr::kable()`](https://rdrr.io/pkg/knitr/man/kable.html) takes it,
  one letter per column.

- digits:

  Number of decimal places for numeric columns.

## Value

A `knitr_kable` object, printed by knitr into the document; in PDF the
table is set one size smaller than the text.

## Examples

``` r
btg_table(head(btg_get_data("national_year")$data[c("year", "stops", "arrest_rate")]),
          caption = "National totals")
#> 
#> 
#> Table: National totals
#> 
#> | year|  stops| arrest_rate|
#> |----:|------:|-----------:|
#> | 2018| 319569|        15.7|
#> | 2019| 524424|        12.8|
#> | 2020| 676628|        11.4|
#> | 2021| 541523|        12.2|
#> | 2022| 477044|        12.8|
#> | 2023| 449005|        14.0|
```
