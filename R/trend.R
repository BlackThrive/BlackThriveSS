# Series over time, and change between two periods, drawn from the bundled
# datasets with the same evidence contract as the ranking chart: every figure
# carries its table and a replayable view, incomplete periods are marked, and
# nothing is annualised or imputed.

utils::globalVariables(c("period", "value", "lower", "upper", "series", "complete",
                         "ratio_from", "ratio_to", "year", "change_label"))

#' The colours BlackThriveSS uses for ethnic groups
#'
#' A fixed assignment of one colour to each officer-defined group, so that a
#' group keeps its colour in every chart whatever else is drawn. The four
#' compared groups use hues from the Okabe-Ito palette, chosen for separation
#' under the common forms of colour-vision deficiency; White, the reference
#' group, is drawn in the package's ink colour and Unknown in its muted grey.
#'
#' @return A named character vector of hex colours for `Asian`, `Black`,
#'   `Mixed`, `Other`, `White` and `Unknown`.
#' @export
#' @examples
#' btg_group_colours()
btg_group_colours <- function() {
  c(Asian = "#0072B2", Black = "#E69F00", Mixed = "#009E73", Other = "#D55E00",
    White = "#0B2545", Unknown = "#8A93A6")
}

# The number of months of a calendar year the source month covers.
.months_in_source <- function(x, year) {
  latest <- x$metadata$source$latest_month
  source_year <- as.integer(substr(latest, 1, 4))
  source_month <- as.integer(substr(latest, 6, 7))
  ifelse(year > source_year, 0L, ifelse(year == source_year, source_month, 12L))
}

.one_area <- function(x, level) {
  key <- if (identical(level, "force")) "force" else "council"
  areas <- unique(x$data[[key]])
  if (length(areas) != 1L) {
    stop("Select one ", key, " with btg_get_data(", key, " = ...) to draw its trend; the selection holds ",
         length(areas), ".", call. = FALSE)
  }
  label <- unique(x$data[[paste0(key, "_label")]])
  list(key = key, id = areas, label = label)
}

# The measures each dataset can draw, with axis labels.
.trend_measures <- function(dataset) {
  switch(dataset,
    force_ethnicity_year = , council_ethnicity_year = c(
      ratio = "Stop-rate ratio (1x = White baseline)",
      rate = "Recorded stops per 1,000 residents"),
    national_month_ethnicity = c(
      stops = "Recorded stops per month",
      share = "Share of recorded stops (%)"),
    national_year = c(
      stops = "Recorded stops", arrests = "Arrests", nfa = "No further action",
      s60 = "Section 60 searches", minors = "Searches of under-18s",
      arrest_rate = "Arrest rate (%)", nfa_rate = "No further action rate (%)",
      hit_rate = "Outcome linked to object of search (%)",
      strip_rate = "Strip searches (% of known)",
      eth_recorded_rate = "Ethnicity recorded (%)"),
    hit_rate_ethnicity_year = c(
      hit_rate = "Outcome linked to object of search (%)",
      hit_total = "Searches with a known outcome"),
    section60_force_year = c(s60_stops = "Section 60 searches"),
    stop("btg_plot_trend() needs a dataset with more than one period; ", dataset,
         " holds a single year.", call. = FALSE))
}

# A long table of one value per period and series, with intervals where the
# measure has them and a flag for periods the source does not cover in full.
.trend_table <- function(x, measure) {
  dataset <- x$selection$dataset
  d <- x$data
  if (dataset %in% c("force_ethnicity_year", "council_ethnicity_year")) {
    level <- if (identical(dataset, "force_ethnicity_year")) "force" else "council"
    area <- .one_area(x, level)
    if (identical(measure, "ratio")) {
      out <- data.frame(period = d$year, series = d$group, value = d$ratio,
                        lower = d$ci_lower, upper = d$ci_upper, stringsAsFactors = FALSE)
    } else {
      white <- d[!duplicated(d$year), ]
      out <- rbind(
        data.frame(period = d$year, series = d$group, value = d$group_rate, stringsAsFactors = FALSE),
        data.frame(period = white$year, series = "White", value = white$white_rate, stringsAsFactors = FALSE))
      out$lower <- out$upper <- NA_real_
    }
    months <- .months_in_source(x, out$period)
    if (identical(level, "force")) {
      status <- d$coverage_status[match(paste(out$period), paste(d$year))]
      out$complete <- months == 12L & status %in% c("all_months_supplied", "unverified")
    } else {
      out$complete <- months == 12L
    }
    out$months_in_source <- months
    title_area <- area$label
  } else if (identical(dataset, "national_month_ethnicity")) {
    if (identical(measure, "share")) {
      totals <- tapply(d$stops, d$month, sum)
      value <- 100 * d$stops / as.numeric(totals[d$month])
    } else value <- d$stops
    out <- data.frame(period = d$month, series = d$group, value = value,
                      lower = NA_real_, upper = NA_real_, stringsAsFactors = FALSE)
    out$complete <- TRUE
    out$months_in_source <- NA_integer_
    title_area <- "England and Wales"
  } else if (identical(dataset, "national_year")) {
    out <- data.frame(period = d$year, series = "England and Wales", value = d[[measure]],
                      lower = NA_real_, upper = NA_real_, stringsAsFactors = FALSE)
    out$months_in_source <- .months_in_source(x, out$period)
    out$complete <- out$months_in_source == 12L
    title_area <- "England and Wales"
  } else if (identical(dataset, "hit_rate_ethnicity_year")) {
    out <- data.frame(period = d$year, series = d$group, value = d[[measure]],
                      lower = NA_real_, upper = NA_real_, stringsAsFactors = FALSE)
    out$months_in_source <- .months_in_source(x, out$period)
    out$complete <- out$months_in_source == 12L
    title_area <- "England and Wales"
  } else if (identical(dataset, "section60_force_year")) {
    area <- .one_area(x, "force")
    out <- data.frame(period = d$year, series = d$group, value = d$s60_stops,
                      lower = NA_real_, upper = NA_real_, stringsAsFactors = FALSE)
    out$months_in_source <- .months_in_source(x, out$period)
    if (!is.null(x$coverage)) {
      years <- as.integer(substr(x$coverage$month, 1, 4))
      missing <- tapply(x$coverage$status == "missing", years, sum)
      out$complete <- out$months_in_source == 12L & missing[as.character(out$period)] == 0
    } else out$complete <- out$months_in_source == 12L
    title_area <- area$label
  }
  out$complete <- as.logical(out$complete)
  out <- out[order(out$series, out$period), c("period", "series", "value", "lower", "upper",
                                              "complete", "months_in_source")]
  rownames(out) <- NULL
  attr(out, "area") <- title_area
  out
}

#' Chart a series over time from a bundled dataset
#'
#' Draws how a measure moves across the years, or months, a dataset holds:
#' a force's or council's stop-rate ratios or rates per 1,000 residents for
#' each group compared with White, national monthly stops by group, national
#' totals and rates by year, outcome-linked search rates by group, or a
#' force's Section 60 searches by group. Each group keeps its colour from
#' [btg_group_colours()] in every chart. Periods the source does not cover in
#' full, or for which a force's returns were incomplete, are drawn with hollow
#' markers and named in the subtitle; nothing is annualised.
#'
#' @param x A dataset from [btg_get_data()]. Force- and council-level
#'   datasets must be selected down to one area with the `force` or `council`
#'   argument of [btg_get_data()].
#' @param measure What to draw. The default is the dataset's first measure:
#'   `"ratio"` or `"rate"` for the comparison datasets; `"stops"` or
#'   `"share"` for national monthly stops; any total or rate column of
#'   `national_year`; `"hit_rate"` or `"hit_total"` for outcome-linked search
#'   rates; `"s60_stops"` for Section 60 searches.
#' @param highlight Optional name of one series (a group) to emphasise. The
#'   other series are drawn in grey as context.
#' @return An editable `ggplot` with its evidence table, available through
#'   [btg_figure_data()] as one row per period and series with `value`,
#'   `lower`, `upper`, `complete` and `months_in_source`, and a saved view
#'   that [btg_save_view()] and [btg_from_view()] replay.
#' @details Ratios carry their 95% Poisson intervals as vertical lines.
#'   Rates per 1,000 residents and counts for an incomplete period are lower
#'   simply because fewer months are covered; the ratio of two rates from the
#'   same months is unaffected by that, which is why incomplete periods are
#'   shown rather than dropped, but marked. Resident populations are fixed at
#'   Census 2021 for every year, so a trend in a rate reflects recorded stops
#'   only, not population change. A ratio is descriptive and does not
#'   establish discrimination.
#' @export
#' @examples
#' met <- btg_get_data("force_ethnicity_year", force = "metropolitan")
#' btg_plot_trend(met)
#' btg_plot_trend(met, measure = "rate", highlight = "Black")
#' btg_plot_trend(btg_get_data("national_month_ethnicity"), measure = "share")
#' btg_plot_trend(btg_get_data("hit_rate_ethnicity_year"))
btg_plot_trend <- function(x, measure = NULL, highlight = NULL) {
  .validate_dataset(x)
  dataset <- x$selection$dataset
  measures <- .trend_measures(dataset)
  measure <- measure %||% names(measures)[1]
  .scalar_string(measure, "measure")
  if (!measure %in% names(measures)) {
    stop("measure must be one of: ", paste(names(measures), collapse = ", "), ".", call. = FALSE)
  }
  table <- .trend_table(x, measure)
  series <- unique(table$series)
  if (!is.null(highlight)) {
    .scalar_string(highlight, "highlight")
    if (!highlight %in% series) stop("highlight must be one of the drawn series: ", paste(series, collapse = ", "), ".", call. = FALSE)
  }
  col <- btg_colours()
  groups <- btg_group_colours()
  palette <- vapply(series, function(s) if (s %in% names(groups)) groups[[s]] else col[["bar"]], character(1))
  if (!is.null(highlight)) palette[names(palette) != highlight] <- col[["baseline"]]
  plotted <- table[!is.na(table$value), ]
  monthly <- is.character(plotted$period) && all(grepl("^\\d{4}-\\d{2}$", plotted$period))
  if (monthly) plotted$period <- as.Date(paste0(plotted$period, "-01"))
  plotted$series <- factor(plotted$series, levels = series)
  incomplete <- plotted[!plotted$complete, ]
  incomplete_note <- if (nrow(incomplete)) {
    periods <- sort(unique(incomplete$period))
    latest <- x$metadata$source$latest_month
    sprintf("Hollow markers: %s %s not covered in full (source month %s); counts are not annualised.",
            paste(format(periods), collapse = ", "), if (length(periods) > 1L) "are" else "is", latest)
  } else "Every period is covered in full by supplied returns within the source month."
  caption <- .chart_caption(
    "Sources: Police.uk; ONS Census 2021. Officer-defined ethnicity; resident populations fixed at Census 2021.",
    if (identical(measure, "ratio")) "Vertical lines are 95% Poisson intervals on the recorded counts; they exclude reporting and classification uncertainty." else NULL,
    "Recorded events are not unique people, and a ratio or rate does not establish discrimination.",
    paste("Fixed release:", x$metadata$release))
  area <- attr(table, "area")
  periods <- range(table$period)
  description <- sub(" [(].*$", "", measures[[measure]])
  if (identical(measure, "ratio")) description <- "stop-rate ratios"
  if (!startsWith(description, "Section")) description <- paste0(tolower(substr(description, 1, 1)), substring(description, 2))
  title <- .wrap_caption(sprintf("%s: %s, %s to %s", area, description, periods[1], periods[2]), 62)
  compared <- if (measure %in% c("ratio", "rate")) "Compared with White residents. " else ""
  subtitle <- if (length(series) > 1L) {
    sprintf("%s%s. %s", compared, paste(series, collapse = ", "), incomplete_note)
  } else paste0(compared, incomplete_note)
  subtitle <- .wrap_caption(subtitle, 95)
  show_intervals <- any(is.finite(plotted$lower))
  p <- ggplot2::ggplot(plotted, ggplot2::aes(x = period, y = value, colour = series, group = series))
  if (identical(measure, "ratio")) {
    p <- p + ggplot2::geom_hline(yintercept = 1, colour = col[["secondary"]], linewidth = 0.5) +
      ggplot2::annotate("text", x = -Inf, y = 1, label = "parity", hjust = -0.2, vjust = -0.5,
                        colour = col[["secondary"]], size = 3)
  }
  if (show_intervals) {
    p <- p + ggplot2::geom_linerange(ggplot2::aes(ymin = lower, ymax = upper), linewidth = 0.5,
                                     alpha = 0.55, na.rm = TRUE, show.legend = FALSE)
  }
  p <- p + ggplot2::geom_line(linewidth = 0.8, lineend = "round") +
    ggplot2::geom_point(ggplot2::aes(fill = ifelse(complete, as.character(series), "incomplete")),
                        shape = 21, size = if (monthly) 1.1 else 2.4, stroke = 0.9, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = palette, breaks = series, drop = FALSE) +
    ggplot2::scale_fill_manual(values = c(palette, incomplete = col[["surface"]]), guide = "none") +
    ggplot2::labs(title = title, subtitle = subtitle, x = NULL, y = measures[[measure]],
                  colour = NULL, caption = caption) +
    btg_theme() +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
  if (monthly) {
    p <- p + ggplot2::scale_x_date(date_breaks = "1 year", date_labels = "%Y",
                                   expand = ggplot2::expansion(mult = c(0.01, 0.04)))
  } else {
    p <- p + ggplot2::scale_x_continuous(breaks = function(l) seq(ceiling(l[1]), floor(l[2])),
                                         expand = ggplot2::expansion(mult = c(0.03, 0.06)))
  }
  if (measure %in% c("share", "arrest_rate", "nfa_rate", "hit_rate", "strip_rate", "eth_recorded_rate")) {
    p <- p + ggplot2::scale_y_continuous(limits = c(0, NA), labels = function(z) paste0(z, "%"),
                                         expand = ggplot2::expansion(mult = c(0, 0.08)))
  } else {
    p <- p + ggplot2::scale_y_continuous(limits = c(0, NA),
                                         labels = function(z) format(z, big.mark = ",", scientific = FALSE, trim = TRUE),
                                         expand = ggplot2::expansion(mult = c(0, 0.08)))
  }
  if (length(series) == 1L) p <- p + ggplot2::theme(legend.position = "none")
  attr(p, "btg_figure_data") <- table
  attr(p, "btg_view") <- .new_view(x, "trend", list(measure = measure, highlight = highlight %||% NA_character_))
  p
}

#' Change in stop-rate ratios between two years
#'
#' Compares each area's ratio in one year with the same group's ratio in
#' another, as the multiplicative change `ratio_to / ratio_from` with a 95%
#' interval on the assumption that the four recorded counts are independent
#' Poisson counts. Coverage of both years is reported beside the change, so
#' that a change between a complete year and an incomplete one is not read as
#' a change in policing.
#'
#' @param x A comparison dataset from [btg_get_data()] holding more than one
#'   year: `force_ethnicity_year` or `council_ethnicity_year`.
#' @param from,to The two calendar years. `to` defaults to the latest year the
#'   source covers in full and `from` to the year before it; both must be in
#'   the selection.
#' @return A data frame with one row per area and group: the two ratios, the
#'   `change` and its interval (`change_lower`, `change_upper`),
#'   `change_direction` (`"higher"`, `"lower"` or `"unclear"` according to
#'   whether the interval excludes 1, `NA` where a ratio is missing), the
#'   coverage status and months covered of both years, and
#'   `comparable_coverage`, which is `TRUE` only when both years are covered in
#'   full by supplied or unverified returns. The attributes `dataset` and
#'   `release` identify the evidence.
#' @details A change in a ratio between two years is a change in recorded
#'   stops relative to fixed Census 2021 populations. It can reflect recording
#'   practice, the share of stops with unknown ethnicity, changes in who is
#'   present in an area and changes in policing, which this table does not
#'   separate. The interval describes sampling variability only.
#' @export
#' @examples
#' y <- btg_get_data("force_ethnicity_year", groups = "Black")
#' ch <- btg_change(y)
#' head(ch[c("force_label", "ratio_from", "ratio_to", "change", "change_direction")])
#' table(ch$change_direction, useNA = "ifany")
btg_change <- function(x, from = NULL, to = NULL) {
  .validate_dataset(x)
  dataset <- x$selection$dataset
  if (!dataset %in% c("force_ethnicity_year", "council_ethnicity_year")) {
    stop("btg_change() compares years of force_ethnicity_year or council_ethnicity_year.", call. = FALSE)
  }
  d <- x$data
  years <- sort(unique(d$year))
  to <- to %||% .default_chart_year(x)
  from <- from %||% (to - 1L)
  for (value in list(from, to)) {
    if (!is.numeric(value) || length(value) != 1L || is.na(value) || !value %in% years) {
      stop("from and to must be calendar years in the dataset selection.", call. = FALSE)
    }
  }
  if (from == to) stop("from and to must differ.", call. = FALSE)
  level <- if (identical(dataset, "force_ethnicity_year")) "force" else "council"
  keys <- c(level, paste0(level, "_label"), "group")
  a <- d[d$year == from, ]
  b <- d[d$year == to, ]
  m <- match(paste(b[[level]], b$group), paste(a[[level]], a$group))
  a <- a[m, ]
  out <- b[keys]
  out$year_from <- as.integer(from)
  out$year_to <- as.integer(to)
  out$ratio_from <- a$ratio
  out$ratio_to <- b$ratio
  out$change <- b$ratio / a$ratio
  z <- stats::qnorm(0.975)
  counts <- cbind(a$group_stops, a$white_stops, b$group_stops, b$white_stops)
  ok <- is.finite(out$change) & rowSums(!is.finite(counts) | counts <= 0) == 0
  se <- sqrt(rowSums(1 / counts))
  out$change_lower <- out$change_upper <- NA_real_
  out$change_lower[ok] <- exp(log(out$change[ok]) - z * se[ok])
  out$change_upper[ok] <- exp(log(out$change[ok]) + z * se[ok])
  out$change_direction <- NA_character_
  out$change_direction[ok] <- ifelse(out$change_lower[ok] > 1, "higher",
                                     ifelse(out$change_upper[ok] < 1, "lower", "unclear"))
  months <- function(year) .months_in_source(x, rep(year, nrow(out)))
  out$months_in_source_from <- months(from)
  out$months_in_source_to <- months(to)
  if (identical(level, "force")) {
    out$coverage_from <- a$coverage_status
    out$coverage_to <- b$coverage_status
    full <- c("all_months_supplied", "unverified")
    out$comparable_coverage <- out$months_in_source_from == 12L & out$months_in_source_to == 12L &
      out$coverage_from %in% full & out$coverage_to %in% full
  } else {
    out$comparable_coverage <- out$months_in_source_from == 12L & out$months_in_source_to == 12L
  }
  out <- out[order(out$group, out[[level]]), ]
  rownames(out) <- NULL
  attr(out, "dataset") <- dataset
  attr(out, "release") <- x$metadata$release
  out
}

#' Chart how forces' stop-rate ratios changed between two years
#'
#' A dumbbell chart of one group's ratio in two years for the forces whose
#' change was largest, from [btg_change()]. The light marker is the earlier
#' year and the dark marker the later one; the label gives the percentage
#' change, and the subtitle says how many of the displayed changes have 95%
#' intervals that exclude no change.
#'
#' @inheritParams btg_change
#' @param group The group compared with White. `NULL` draws Black when the
#'   selection holds it, otherwise its first group.
#' @param n Maximum number of displayed forces, from 1 to 44.
#' @param order `"largest"` shows the forces with the largest proportional
#'   change in either direction; `"increase"` and `"decrease"` show the
#'   largest rises or falls.
#' @return An editable `ggplot` with its evidence table, from
#'   [btg_figure_data()], and a replayable saved view.
#' @details Only forces with a dashboard-eligible ratio in both years are
#'   displayed. Forces whose returns do not cover both years in full are
#'   marked with an asterisk, because fewer months lower counts but not, under
#'   uniform reporting, the ratio. Changes are descriptive: see
#'   [btg_change()] for what they can and cannot show.
#' @export
#' @examples
#' y <- btg_get_data("force_ethnicity_year")
#' btg_plot_change(y)
#' btg_plot_change(y, from = 2023, to = 2025, group = "Asian", order = "decrease")
btg_plot_change <- function(x, from = NULL, to = NULL, group = NULL, n = 10L,
                            order = c("largest", "increase", "decrease")) {
  if (missing(order)) order <- "largest"
  if (!is.character(order) || length(order) != 1L || !order %in% c("largest", "increase", "decrease")) {
    stop("order must be largest, increase, or decrease.", call. = FALSE)
  }
  .plot_args(n, "highest")
  .validate_dataset(x)
  if (!identical(x$selection$dataset, "force_ethnicity_year")) {
    stop("btg_plot_change() draws force_ethnicity_year.", call. = FALSE)
  }
  ch <- btg_change(x, from = from, to = to)
  group <- group %||% if ("Black" %in% ch$group) "Black" else ch$group[1]
  if (!is.character(group) || length(group) != 1L || is.na(group) || !group %in% ch$group) {
    stop("group must be one ethnic group in the dataset selection.", call. = FALSE)
  }
  d <- x$data
  eligible <- function(year) d$force[d$year == year & d$group == group & d$eligible]
  rows <- ch[ch$group == group & ch$force %in% eligible(ch$year_from[1]) &
               ch$force %in% eligible(ch$year_to[1]) & is.finite(ch$change), ]
  if (!nrow(rows)) stop("No force has a dashboard-eligible ratio in both years.", call. = FALSE)
  score <- switch(order, largest = -abs(log(rows$change)), increase = -log(rows$change),
                  decrease = log(rows$change))
  rows <- utils::head(rows[order(score, rows$force_label), ], n)
  rows$axis_label <- paste0(rows$force_label, ifelse(rows$comparable_coverage, "", " *"))
  rows$change_label <- sprintf("%+.0f%%", 100 * (rows$change - 1))
  rownames(rows) <- NULL
  col <- btg_colours()
  levels_years <- c(paste(rows$year_from[1]), paste(rows$year_to[1]))
  plotted <- rows
  plotted$axis_label <- factor(plotted$axis_label, levels = rev(plotted$axis_label))
  points <- rbind(
    data.frame(axis_label = plotted$axis_label, value = plotted$ratio_from, year = levels_years[1]),
    data.frame(axis_label = plotted$axis_label, value = plotted$ratio_to, year = levels_years[2]))
  points$year <- factor(points$year, levels = levels_years)
  plotted$label_x <- pmax(plotted$ratio_from, plotted$ratio_to)
  clear <- sum(rows$change_direction %in% c("higher", "lower"))
  subtitle <- .wrap_caption(sprintf("%s: %d of %d forces eligible in both years. %d of %d changes have 95%% intervals that exclude no change.",
                      switch(order, largest = "Largest changes in either direction",
                             increase = "Largest increases", decrease = "Largest decreases"),
                      nrow(rows), sum(ch$group == group & ch$force %in% eligible(ch$year_from[1]) &
                                        ch$force %in% eligible(ch$year_to[1]) & is.finite(ch$change)),
                      clear, nrow(rows)), 95)
  caption <- .chart_caption(
    "Sources: Police.uk; ONS Census 2021. Resident-based event rates; officer-defined ethnicity.",
    "Change is the later ratio divided by the earlier one; intervals treat the four recorded counts as independent Poisson counts.",
    if (any(!rows$comparable_coverage)) "* Returns do not cover both years in full; fewer months lower counts but not, under uniform reporting, the ratio." else "Every displayed force has full-year returns in both years.",
    "A change in recorded stops relative to fixed populations does not by itself show a change in policing or establish discrimination.",
    paste("Fixed release:", x$metadata$release))
  upper <- max(plotted$label_x) * 1.18
  p <- ggplot2::ggplot(plotted, ggplot2::aes(y = axis_label)) +
    ggplot2::geom_vline(xintercept = 1, colour = col[["secondary"]], linewidth = 0.5) +
    ggplot2::geom_segment(ggplot2::aes(x = ratio_from, xend = ratio_to, yend = axis_label),
                          colour = col[["baseline"]], linewidth = 1.2) +
    ggplot2::geom_point(data = points, ggplot2::aes(x = value, y = axis_label, fill = year),
                        shape = 21, size = 3.4, colour = col[["surface"]], stroke = 0.7) +
    ggplot2::geom_text(ggplot2::aes(x = label_x, label = change_label), hjust = -0.3,
                       colour = col[["ink"]], size = 3.6) +
    ggplot2::scale_fill_manual(values = stats::setNames(c(col[["bar_partial"]], col[["bar"]]), levels_years)) +
    ggplot2::scale_x_continuous(labels = function(z) paste0(z, "x"),
                                breaks = function(l) pretty(l, n = 6),
                                limits = c(0, upper), expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.6, 0.8))) +
    ggplot2::labs(title = sprintf("%s:White stop-rate ratios, %s to %s", group, levels_years[1], levels_years[2]),
                  subtitle = subtitle, x = "Recorded stop-rate ratio (1x = White baseline)",
                  y = NULL, fill = NULL, caption = caption) +
    btg_theme() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  attr(p, "btg_figure_data") <- rows[setdiff(names(rows), "axis_label")]
  attr(p, "btg_view") <- .new_view(x, "change", list(from = as.integer(rows$year_from[1]), to = as.integer(rows$year_to[1]),
                                                     group = group, n = as.integer(n), order = order))
  p
}
