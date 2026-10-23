# The colours BlackThriveSS charts use

A named vector of the dashboard's chart colours, so that figures drawn
outside the package can match them.

## Usage

``` r
btg_colours()
```

## Value

A named character vector of hex colours: `bar` for the main series,
`bar_partial` for forces with incomplete or unverified returns, `ink`,
`secondary` and `muted` for text, `grid` and `baseline` for chart
chrome, and `surface` for the chart background.

## Examples

``` r
btg_colours()[c("bar", "bar_partial")]
#>         bar bar_partial 
#>   "#E69F00"   "#F5D27A" 
```
