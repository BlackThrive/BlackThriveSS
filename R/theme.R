# The visual system shared by every chart the package draws: the dashboard's
# colours and one quiet ggplot2 theme.

#' The colours BlackThriveSS charts use
#'
#' A named vector of the dashboard's chart colours, so that figures drawn
#' outside the package can match them.
#'
#' @return A named character vector of hex colours: `bar` for the main
#'   series, `bar_partial` for forces with incomplete or unverified returns,
#'   `ink`, `secondary` and `muted` for text, `grid` and `baseline` for chart
#'   chrome, and `surface` for the chart background.
#' @export
#' @examples
#' btg_colours()[c("bar", "bar_partial")]
btg_colours <- function() {
  c(
    bar = "#E69F00",
    bar_partial = "#F5D27A",
    ink = "#0B2545",
    secondary = "#5C677D",
    muted = "#8A93A6",
    grid = "#E4E6EB",
    baseline = "#B6BDCB",
    surface = "#FFFFFF"
  )
}

#' The ggplot2 theme BlackThriveSS charts use
#'
#' A quiet theme built on [ggplot2::theme_minimal()]: a recessive hairline
#' grid, no minor grid or tick marks, titles aligned with the plot edge, muted
#' axis text and the legend above the plot. [btg_plot_disparity()] applies it,
#' and it can be added to any other ggplot.
#'
#' @param base_size Base font size in points.
#' @return A ggplot2 theme object.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point(colour = btg_colours()[["bar"]]) +
#'   btg_theme()
btg_theme <- function(base_size = 12) {
  col <- btg_colours()
  ggplot2::theme_minimal(base_size = base_size, base_family = "sans") +
    ggplot2::theme(
      text = ggplot2::element_text(colour = col[["ink"]]),
      plot.background = ggplot2::element_rect(fill = col[["surface"]], colour = NA),
      panel.background = ggplot2::element_rect(fill = col[["surface"]], colour = NA),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = col[["grid"]], linewidth = 0.3),
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(colour = col[["muted"]], size = ggplot2::rel(0.85)),
      axis.text.y = ggplot2::element_text(colour = col[["ink"]], size = ggplot2::rel(0.9)),
      axis.title = ggplot2::element_text(colour = col[["secondary"]], size = ggplot2::rel(0.9)),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 8), hjust = 0),
      plot.title = ggplot2::element_text(
        colour = col[["ink"]], face = "bold", size = ggplot2::rel(1.4),
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        colour = col[["secondary"]], size = ggplot2::rel(0.95),
        margin = ggplot2::margin(b = 10)
      ),
      plot.caption = ggplot2::element_text(
        colour = col[["muted"]], size = ggplot2::rel(0.72), hjust = 0,
        lineheight = 1.15, margin = ggplot2::margin(t = 12)
      ),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      legend.position = "top",
      legend.justification = c(0, 1),
      legend.location = "plot",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour = col[["secondary"]], size = ggplot2::rel(0.85)),
      legend.key.size = grid::unit(10, "pt"),
      legend.margin = ggplot2::margin(0, 0, 6, 0),
      plot.margin = ggplot2::margin(14, 22, 12, 12)
    )
}
