# The ggplot2 theme BlackThriveSS charts use

A quiet theme built on
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html):
a recessive hairline grid, no minor grid or tick marks, titles aligned
with the plot edge, muted axis text and the legend above the plot.
[`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md)
applies it, and it can be added to any other ggplot.

## Usage

``` r
btg_theme(base_size = 12)
```

## Arguments

- base_size:

  Base font size in points.

## Value

A ggplot2 theme object.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) +
  geom_point(colour = btg_colours()[["bar"]]) +
  btg_theme()
```
