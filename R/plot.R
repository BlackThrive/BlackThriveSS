utils::globalVariables(c("ratio", "axis_label", "value_label", "fill_label",
                         "ci_lower", "ci_upper", "label_x"))

.plot_args <- function(n, ranking) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) ||
      !is.finite(n) || n < 1 || n > 44 || n != floor(n)) {
    stop("n must be an integer from 1 to 44.", call. = FALSE)
  }
  if (!is.character(ranking) || length(ranking) != 1L || is.na(ranking) ||
      !ranking %in% c("highest", "lowest", "closest")) {
    stop("ranking must be highest, lowest, or closest.", call. = FALSE)
  }
  ranking
}

# The latest year the source covers in full, which is what the dashboard's
# year slider starts on.
.default_chart_year <- function(x) {
  d <- x$data
  months <- if ("months_in_source" %in% names(d)) d$months_in_source else .months_in_source(x, d$year)
  complete <- d$year[months == 12L]
  if (!length(complete)) complete <- d$year
  max(complete)
}

# One year and one group from a force-level comparison dataset, with the
# generic column names the chart draws from.
.chart_rows <- function(x, year, group) {
  dataset <- x$selection$dataset
  d <- x$data
  if (identical(dataset, "force_disparity")) {
    if (!is.null(year) && !identical(as.integer(year), 2025L)) stop("force_disparity holds 2025 only.", call. = FALSE)
    if (!is.null(group) && !identical(group, "Black")) stop("force_disparity holds the Black comparison only.", call. = FALSE)
    return(list(rows = d, year = 2025L, group = "Black", n_eligible = sum(d$eligible)))
  }
  if (!identical(dataset, "force_ethnicity_year")) {
    stop("btg_plot_disparity() draws force-level ratios from force_disparity or force_ethnicity_year.", call. = FALSE)
  }
  year <- if (is.null(year)) .default_chart_year(x) else year
  if (!is.numeric(year) || length(year) != 1L || is.na(year) || !year %in% d$year) {
    stop("year must be one calendar year in the dataset selection.", call. = FALSE)
  }
  group <- group %||% if ("Black" %in% d$group) "Black" else d$group[1]
  if (!is.character(group) || length(group) != 1L || is.na(group) || !group %in% d$group) {
    stop("group must be one ethnic group in the dataset selection.", call. = FALSE)
  }
  rows <- d[d$year == as.integer(year) & d$group == group, , drop = FALSE]
  list(rows = rows, year = as.integer(year), group = group, n_eligible = sum(rows$eligible))
}

# The caption line that explains the asterisks on a chart's displayed forces.
.coverage_note <- function(d) {
  partial <- sum(d$coverage_status != "all_months_supplied")
  if (all(d$coverage_status == "unverified")) {
    "* Monthly submissions for this year lie outside the window the dashboard verifies; counts are as published."
  } else if (partial) {
    sprintf("* %d displayed force(s) have incomplete or unverified returns; counts are not annualised.", partial)
  } else "All displayed forces supplied all 12 months; this does not certify complete event recording."
}

.figure_rows <- function(d, n, ranking) {
  d <- d[d$eligible, , drop = FALSE]
  if (!nrow(d)) stop("No dashboard-eligible ratios in this selection.", call. = FALSE)
  score <- switch(ranking, highest = -d$ratio, lowest = d$ratio,
                  closest = abs(d$ratio - 1))
  d <- utils::head(d[order(score, d$force_label), , drop = FALSE], n)
  d$axis_label <- paste0("#", d$rank, "  ", d$force_label,
                         ifelse(d$coverage_status == "all_months_supplied", "", " *"))
  d$value_label <- sprintf("%.1fx", d$ratio)
  rownames(d) <- NULL
  d
}

#' Reproduce the dashboard's force ranking as an editable plot
#'
#' Recreates the values, eligibility rule and ordering of the dashboard's
#' ranking of forces by the rate at which one group is stopped compared with
#' White residents. This is a static ggplot version: interactive hover text and
#' previous-year change annotations are not reproduced. Partial reporting is
#' labelled explicitly, each bar carries its 95% interval, and one force can be
#' highlighted as the dashboard's selected force.
#'
#' @param x A dataset from [btg_get_data()]: `force_disparity` (2025, Black)
#'   or `force_ethnicity_year` (any year and group it holds).
#' @param n Maximum number of displayed forces, from 1 to 44.
#' @param ranking One of `"highest"`, `"lowest"`, or `"closest"` to parity.
#' @param year The calendar year to draw. `NULL` draws the latest year the
#'   source covers in full, which is the dashboard's starting year.
#' @param group The group compared with White: `"Black"`, `"Asian"`, `"Mixed"`
#'   or `"Other"`. `NULL` draws Black.
#' @param highlight Optional Police.uk identifier of one force to draw in the
#'   selected-force colour, as the dashboard does for its chosen force.
#' @return An editable `ggplot` with a saved evidence specification. The
#'   underlying original chart table is available with [btg_figure_data()].
#' @details Ranks refer to every eligible force in that year and group, even
#'   after selecting forces. The solid line is parity (1). An asterisk and a
#'   lighter fill mark incomplete or unverified monthly returns; the dashboard
#'   verifies submissions only inside a recent window, so earlier years show
#'   every force as unverified; when that is true of every displayed force the
#'   bars keep the ordinary fill and the caption says so. A highlighted force is
#'   drawn only if it falls within the `n` displayed forces, as on the
#'   dashboard. Counts are not annualised. Display eligibility does not imply
#'   complete or comparable exposure, or establish discrimination.
#' @export
#' @examples
#' p <- btg_plot_disparity(btg_get_data())
#' p
#' head(btg_figure_data(p))
#'
#' y <- btg_get_data("force_ethnicity_year")
#' btg_plot_disparity(y, year = 2024, group = "Asian", highlight = "metropolitan")
btg_plot_disparity <- function(x = btg_get_data(), n = 10L,
                               ranking = c("highest", "lowest", "closest"),
                               year = NULL, group = NULL, highlight = NULL) {
  if (missing(ranking)) ranking <- "highest"
  ranking <- .plot_args(n, ranking)
  .validate_dataset(x)
  chart <- .chart_rows(x, year, group)
  if (!is.null(highlight)) {
    .scalar_string(highlight, "highlight")
    if (!highlight %in% chart$rows$force) stop("highlight must be a force in the dataset selection.", call. = FALSE)
  }
  d <- .figure_rows(chart$rows, n, ranking)
  col <- btg_colours()
  fill_levels <- c("All 12 months supplied", "Incomplete or unverified returns", "Selected force")
  plotted <- d
  plotted$axis_label <- factor(plotted$axis_label, levels = rev(plotted$axis_label))
  partial <- sum(d$coverage_status != "all_months_supplied")
  all_unverified <- all(d$coverage_status == "unverified")
  # When no displayed force has verified coverage, the lighter fill would say
  # nothing about any one force; the caption explains the year instead.
  plotted$fill_label <- ifelse(plotted$coverage_status == "all_months_supplied" | all_unverified,
                               fill_levels[1], fill_levels[2])
  if (!is.null(highlight)) plotted$fill_label[plotted$force == highlight] <- fill_levels[3]
  plotted$fill_label <- factor(plotted$fill_label, levels = fill_levels)
  plotted$label_x <- pmax(plotted$ratio, plotted$ci_upper, na.rm = TRUE)
  present <- fill_levels[fill_levels %in% plotted$fill_label]
  subtitle <- switch(ranking, highest = "Highest displayed ratios",
                     lowest = "Lowest displayed ratios", closest = "Closest to parity")
  caption <- paste(
    "Sources: Police.uk; ONS Census 2021. Resident-based event rates; officer-defined ethnicity.",
    "Dark lines are 95% Poisson intervals on the recorded counts; they exclude reporting and classification uncertainty.",
    .coverage_note(d),
    "Ranks follow dashboard eligibility, not a measure of individual risk or causal discrimination.",
    paste("Fixed release:", x$metadata$release), sep = "\n")
  upper <- max(1.35, max(plotted$label_x) * 1.16)
  p <- ggplot2::ggplot(plotted, ggplot2::aes(x = ratio, y = axis_label)) +
    ggplot2::geom_col(ggplot2::aes(fill = fill_label), width = 0.62) +
    ggplot2::geom_vline(xintercept = 1, colour = col[["secondary"]], linewidth = 0.5) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = ci_lower, xmax = ci_upper),
                            colour = col[["ink"]], linewidth = 0.6, na.rm = TRUE) +
    ggplot2::geom_text(ggplot2::aes(x = label_x, label = value_label), hjust = -0.25,
                       colour = col[["ink"]], size = 3.6) +
    ggplot2::annotate("text", x = 1, y = Inf, label = "parity", hjust = -0.15, vjust = 1.4,
                      colour = col[["secondary"]], size = 3) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(c(col[["bar"]], col[["bar_partial"]], col[["ink"]]), fill_levels),
      breaks = present,
      guide = if (length(present) > 1L) "legend" else "none") +
    ggplot2::scale_x_continuous(labels = function(z) paste0(z, "x"),
                                breaks = function(l) pretty(l, n = 6),
                                limits = c(0, upper),
                                expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.6, 1.1))) +
    ggplot2::labs(title = sprintf("%s:White stop-rate ratios, %d", chart$group, chart$year),
                  subtitle = sprintf("%s: %d of %d eligible forces", subtitle, nrow(d), chart$n_eligible),
                  x = "Recorded stop-rate ratio (1x = White baseline)",
                  y = NULL, fill = NULL, caption = caption) +
    btg_theme() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  attr(p, "btg_figure_data") <- d
  attr(p, "btg_view") <- list(
    schema_version = 2L, chart = "force_disparity_ranking", chart_version = 1L,
    dataset = x$selection$dataset, release = x$metadata$release,
    data_sha256 = spec$sha256,
    coverage_sha256 = if (!is.null(spec$coverage)) x$metadata$files[[spec$coverage]]$sha256 else "",
    force = x$selection$force, year = chart$year, group = chart$group,
    n = as.integer(n), ranking = ranking,
    highlight = if (is.null(highlight)) NA_character_ else highlight)
  p
}

#' Extract the original numerical table behind a chart
#' @param p A plot returned by [btg_plot_disparity()], [btg_from_view()] or
#'   [btg_from_url()].
#' @return An ordinary data frame in display order, including counts,
#'   denominators, ratios, approximate intervals and reporting coverage.
#' @details This returns the original evidence table. User-added ggplot layers
#'   and transformations do not change that table or the saved view.
#' @export
#' @examples
#' btg_figure_data(btg_plot_disparity())
btg_figure_data <- function(p) {
  d <- attr(p, "btg_figure_data", exact = TRUE)
  if (is.null(d)) stop("No BlackThriveSS evidence table on this plot.", call. = FALSE)
  d
}
