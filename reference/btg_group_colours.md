# The colours BlackThriveSS uses for ethnic groups

A fixed assignment of one colour to each officer-defined group, so that
a group keeps its colour in every chart whatever else is drawn. The four
compared groups use hues from the Okabe-Ito palette, chosen for
separation under the common forms of colour-vision deficiency; White,
the reference group, is drawn in the package's ink colour and Unknown in
its muted grey.

## Usage

``` r
btg_group_colours()
```

## Value

A named character vector of hex colours for `Asian`, `Black`, `Mixed`,
`Other`, `White` and `Unknown`.

## Examples

``` r
btg_group_colours()
#>     Asian     Black     Mixed     Other     White   Unknown 
#> "#0072B2" "#E69F00" "#009E73" "#D55E00" "#0B2545" "#8A93A6" 
```
