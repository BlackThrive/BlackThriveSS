# Robustness of a comparison to what the data do not say: stops whose
# ethnicity is unknown, and the sampling variability behind a force's rank.
# Assumption ranges and sampling intervals are reported separately and never
# combined into one number.

utils::globalVariables(c("ratio_min", "ratio_max"))

# The comparison datasets with the generic column names the calculations use.
# force_disparity names its group columns black_*; the catalogue datasets use
# group_*.
.comparison_rows <- function(x) {
  dataset <- x$selection$dataset
  d <- x$data
  if (identical(dataset, "force_disparity")) {
    d$group <- "Black"
    d$group_stops <- d$black_stops
    d$group_population <- d$black_population
    d$group_rate <- d$black_rate
  } else if (!dataset %in% c("force_ethnicity_year", "council_ethnicity_year")) {
    stop("This analysis applies to the comparison datasets force_disparity, ",
         "force_ethnicity_year and council_ethnicity_year.", call. = FALSE)
  }
  d
}

.select_year_group <- function(d, year, group) {
  if (!is.null(year)) {
    if (!is.numeric(year) || length(year) != 1L || is.na(year) || !year %in% d$year) {
      stop("year must be one calendar year in the dataset selection.", call. = FALSE)
    }
    d <- d[d$year == as.integer(year), , drop = FALSE]
  }
  if (!is.null(group)) {
    if (!is.character(group) || length(group) != 1L || is.na(group) || !group %in% d$group) {
      stop("group must be one ethnic group in the dataset selection.", call. = FALSE)
    }
    d <- d[d$group == group, , drop = FALSE]
  }
  rownames(d) <- NULL
  d
}

.count_argument <- function(value, name, minimum) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || !is.finite(value) ||
      value < minimum || value != floor(value)) {
    stop(name, " must be a whole number of at least ", minimum, ".", call. = FALSE)
  }
  as.integer(value)
}

# Evaluate code with a fixed random seed and leave the caller's random number
# state exactly as it was.
.with_seed <- function(seed, code) {
  env <- globalenv()
  had <- exists(".Random.seed", envir = env, inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = env, inherits = FALSE)
  on.exit({
    if (had) {
      assign(".Random.seed", old, envir = env)
    } else if (exists(".Random.seed", envir = env, inherits = FALSE)) {
      rm(".Random.seed", envir = env)
    }
  }, add = TRUE)
  set.seed(seed)
  code
}

#' Bound a comparison under every allocation of unknown-ethnicity stops
#'
#' The recorded stop-rate ratio leaves out stops whose ethnicity was not
#' recorded. This function reports the range the ratio would take if every one
#' of those stops belonged to the compared group, or every one of them to the
#' White group, which are the two extreme allocations. Any allocation of the
#' unknown stops between the groups gives a ratio inside that range, and
#' allocating them in the same proportions as the recorded stops leaves the
#' ratio unchanged. For force-level datasets the function also reports the
#' best and worst rank a force could hold if every force's unknown stops were
#' allocated in its favour or against it.
#'
#' @param x A comparison dataset from [btg_get_data()]: `force_disparity`,
#'   `force_ethnicity_year` or `council_ethnicity_year`.
#' @param year Optional single calendar year to keep. `NULL` keeps every year
#'   in the selection.
#' @param group Optional single ethnic group to keep. `NULL` keeps every group
#'   in the selection.
#' @return A data frame with one row per area, year and group: the recorded
#'   counts, `unknown_share` (unknown-ethnicity stops as a share of all
#'   records), the recorded `ratio` with its Poisson interval, `ratio_min`
#'   (every unknown stop assigned to White), `ratio_max` (every unknown stop
#'   assigned to the compared group) and `parity_direction`: `"above"` when
#'   the whole range exceeds 1, `"below"` when it is entirely under 1, and
#'   `"sensitive"` when the side of parity depends on the unknown stops. Force
#'   rows add `eligible`, `rank`, `rank_best`, `rank_worst` (ranks among the
#'   forces eligible in the recorded data, under the most favourable and least
#'   favourable allocations) and the coverage columns. Missing returns remain
#'   missing. The attributes `dataset` and `release` identify the evidence.
#' @details The sampling interval and the allocation range answer different
#'   questions and are deliberately not combined. The interval conditions on
#'   the recorded counts; the range conditions on nothing about the unknown
#'   stops except their number. Neither captures missing monthly returns,
#'   classification differences between officer-defined and Census ethnicity,
#'   or the choice of resident populations as the exposure measure, and
#'   neither establishes discrimination. Council rows carry no rank or
#'   eligibility, as in the dataset.
#' @export
#' @examples
#' s <- btg_sensitivity(btg_get_data())
#' head(s[c("force_label", "ratio", "ratio_min", "ratio_max", "parity_direction")])
#' table(s$parity_direction, useNA = "ifany")
#'
#' y <- btg_get_data("force_ethnicity_year", years = 2025, groups = "Asian")
#' head(btg_sensitivity(y)[c("force_label", "rank", "rank_best", "rank_worst")])
btg_sensitivity <- function(x, year = NULL, group = NULL) {
  .validate_dataset(x)
  level <- .dataset_spec(x$metadata, x$selection$dataset)$level
  d <- .select_year_group(.comparison_rows(x), year, group)
  u <- d$unknown_ethnicity_stops
  to_group <- d
  to_group$group_stops <- d$group_stops + u
  to_white <- d
  to_white$white_stops <- d$white_stops + u
  d$ratio_min <- .rates_and_ratio(to_white, d$comparable)$ratio
  d$ratio_max <- .rates_and_ratio(to_group, d$comparable)$ratio
  # A withheld ratio (zero White count or non-comparable populations) has no bounds.
  withheld <- !is.finite(d$ratio)
  d$ratio_min[withheld] <- NA_real_
  d$ratio_max[withheld] <- NA_real_
  d$unknown_share <- ifelse(is.finite(d$total_records) & d$total_records > 0,
                            u / d$total_records, NA_real_)
  bounded <- is.finite(d$ratio_min) & is.finite(d$ratio_max)
  d$parity_direction <- NA_character_
  d$parity_direction[bounded & d$ratio_min > 1] <- "above"
  d$parity_direction[bounded & d$ratio_max < 1] <- "below"
  d$parity_direction[bounded & d$ratio_min <= 1 & d$ratio_max >= 1] <- "sensitive"
  if (identical(level, "force")) {
    d$rank_best <- d$rank_worst <- NA_integer_
    for (key in unique(paste(d$year, d$group))) {
      rows <- which(paste(d$year, d$group) == key & d$eligible)
      lo <- d$ratio_min[rows]
      hi <- d$ratio_max[rows]
      for (i in seq_along(rows)) {
        d$rank_best[rows[i]] <- 1L + sum(lo[-i] > hi[i], na.rm = TRUE)
        d$rank_worst[rows[i]] <- 1L + sum(hi[-i] > lo[i], na.rm = TRUE)
      }
    }
    keys <- c("force", "force_label")
    extra <- c("eligible", "rank", "rank_best", "rank_worst", "coverage_status", "months_supplied")
    d <- d[order(d$year, d$group, !d$eligible, d$rank, d$force), , drop = FALSE]
  } else {
    keys <- c("council", "council_label")
    extra <- character()
    d <- d[order(d$year, d$group, d$council), , drop = FALSE]
  }
  out <- d[c(keys, "year", "group", "group_stops", "white_stops", "unknown_ethnicity_stops",
             "total_records", "unknown_share", "ratio", "ci_lower", "ci_upper",
             "ratio_min", "ratio_max", "parity_direction", extra)]
  rownames(out) <- NULL
  attr(out, "dataset") <- x$selection$dataset
  attr(out, "release") <- x$metadata$release
  out
}

#' Estimate how stable each force's rank is under sampling variability
#'
#' Ranks in a league table are far less certain than the ratios they order.
#' This function redraws the recorded group and White counts of every eligible
#' force from Poisson distributions with the recorded counts as means, re-ranks
#' the forces in each draw and summarises where each force's rank falls. The
#' draws use a fixed seed, so the result is reproducible, and the caller's
#' random number state is left untouched.
#'
#' @param x A force-level comparison dataset from [btg_get_data()]:
#'   `force_disparity` or `force_ethnicity_year`.
#' @param year Optional single calendar year to keep.
#' @param group Optional single ethnic group to keep.
#' @param draws Number of simulated tables per year and group, at least 200.
#' @param seed Seed for the simulation.
#' @param top Rank threshold for `prob_top`: the probability that a force
#'   ranks within the top `top` forces, which is the number the dashboard's
#'   ranking chart displays by default.
#' @return A data frame of the dashboard-eligible forces with their recorded
#'   `ratio` and `rank`, the 2.5th and 97.5th percentiles of the simulated
#'   rank (`rank_lower`, `rank_upper`) and `prob_top`. Ranks are among the
#'   eligible forces of the same year and group. The attributes `draws`,
#'   `seed`, `top`, `dataset` and `release` record the settings and evidence.
#' @details The simulation conditions on the fixed Census populations and on
#'   the recorded counts, which is the same model behind the Poisson intervals
#'   in the dataset. It describes sampling variability only: the allocation of
#'   unknown-ethnicity stops is examined separately by [btg_sensitivity()],
#'   and missing monthly returns, classification and exposure choices are not
#'   simulated. Results depend on R's default random number generator.
#' @export
#' @examples
#' r <- btg_rank_stability(btg_get_data(), draws = 500)
#' head(r[c("force_label", "ratio", "rank", "rank_lower", "rank_upper", "prob_top")])
btg_rank_stability <- function(x, year = NULL, group = NULL, draws = 2000L, seed = 1L, top = 10L) {
  .validate_dataset(x)
  if (!identical(.dataset_spec(x$metadata, x$selection$dataset)$level, "force")) {
    stop("Rank stability applies to force-level comparison datasets.", call. = FALSE)
  }
  draws <- .count_argument(draws, "draws", 200L)
  top <- .count_argument(top, "top", 1L)
  if (!is.numeric(seed) || length(seed) != 1L || is.na(seed)) {
    stop("seed must be one number.", call. = FALSE)
  }
  d <- .select_year_group(.comparison_rows(x), year, group)
  d <- d[d$eligible, , drop = FALSE]
  if (!nrow(d)) stop("No dashboard-eligible ratios in this selection.", call. = FALSE)
  d <- d[order(d$year, d$group, d$rank, d$force), , drop = FALSE]
  keys <- paste(d$year, d$group)
  tables <- split(d, factor(keys, levels = unique(keys)))
  summaries <- .with_seed(seed, lapply(tables, function(rows) {
    m <- nrow(rows)
    g <- matrix(stats::rpois(m * draws, rows$group_stops), nrow = m)
    w <- matrix(stats::rpois(m * draws, rows$white_stops), nrow = m)
    ratio <- (g / rows$group_population) / (w / rows$white_population)
    ranks <- matrix(apply(-ratio, 2, rank, ties.method = "min"), nrow = m)
    data.frame(force = rows$force, force_label = rows$force_label, year = rows$year,
               group = rows$group, ratio = rows$ratio, rank = rows$rank,
               rank_lower = as.integer(apply(ranks, 1, stats::quantile, probs = 0.025, type = 1, names = FALSE)),
               rank_upper = as.integer(apply(ranks, 1, stats::quantile, probs = 0.975, type = 1, names = FALSE)),
               prob_top = rowMeans(ranks <= top), stringsAsFactors = FALSE)
  }))
  out <- do.call(rbind, summaries)
  rownames(out) <- NULL
  attr(out, "draws") <- draws
  attr(out, "seed") <- seed
  attr(out, "top") <- top
  attr(out, "dataset") <- x$selection$dataset
  attr(out, "release") <- x$metadata$release
  out
}

#' Chart how robust each displayed force's comparison is
#'
#' Draws the forces the dashboard's ranking chart would display, with three
#' marks for each: the recorded stop-rate ratio, its 95% Poisson interval and
#' the range the ratio would take under every allocation of the stops whose
#' ethnicity was not recorded (see [btg_sensitivity()]). A force whose whole
#' range sits on one side of the parity line keeps its direction whatever the
#' unknown stops turn out to be.
#'
#' @inheritParams btg_plot_disparity
#' @return An editable `ggplot` with a saved evidence specification. The
#'   table behind it, including the bounds, is available with
#'   [btg_figure_data()], and the chart can be saved and replayed with
#'   [btg_save_view()] and [btg_from_view()]. It has no page on the dashboard
#'   website, so [btg_dashboard_url()] does not apply to it.
#' @details The selection of forces, their order and their ranks are exactly
#'   those of [btg_plot_disparity()] with the same arguments. The axis is
#'   logarithmic because ratios are multiplicative and the allocation range
#'   can span orders of magnitude where a group's resident population is
#'   small. Sampling intervals and allocation ranges are drawn as separate
#'   marks and are not combined. Display eligibility does not imply complete or comparable
#'   exposure, or establish discrimination.
#' @export
#' @examples
#' btg_plot_sensitivity(btg_get_data())
#'
#' y <- btg_get_data("force_ethnicity_year")
#' btg_plot_sensitivity(y, year = 2024, group = "Asian", highlight = "metropolitan")
btg_plot_sensitivity <- function(x = btg_get_data(), n = 10L,
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
  d <- .figure_rows(btg_sensitivity(x, year = chart$year, group = chart$group), n, ranking)
  col <- btg_colours()
  range_levels <- c("95% Poisson interval of the recorded ratio (sampling)",
                    "Ratio if every unknown-ethnicity stop were White or in the compared group (assumption)")
  fill_levels <- c("Recorded ratio", "Selected force")
  plotted <- d
  plotted$axis_label <- factor(plotted$axis_label, levels = rev(plotted$axis_label))
  plotted$fill_label <- fill_levels[1]
  if (!is.null(highlight)) plotted$fill_label[plotted$force == highlight] <- fill_levels[2]
  plotted$fill_label <- factor(plotted$fill_label, levels = fill_levels)
  plotted$label_x <- pmax(plotted$ratio_max, plotted$ci_upper, plotted$ratio, na.rm = TRUE)
  present <- fill_levels[fill_levels %in% plotted$fill_label]
  settled <- sum(plotted$parity_direction %in% c("above", "below"))
  subtitle <- switch(ranking, highest = "Highest displayed ratios",
                     lowest = "Lowest displayed ratios", closest = "Closest to parity")
  subtitle <- .wrap_caption(sprintf("%s: %d of %d eligible forces.\n%d of %d keep their side of parity under every allocation of unknown ethnicity.",
                                    subtitle, nrow(d), chart$n_eligible, settled, nrow(d)), 95)
  caption <- .chart_caption(
    "Sources: Police.uk; ONS Census 2021. Resident-based event rates; officer-defined ethnicity.",
    "Dots are recorded ratios; dark lines are 95% Poisson intervals on the recorded counts (sampling only).",
    "Light bands run from the ratio with every unknown-ethnicity stop counted as White to the ratio with every one counted in the compared group.",
    .coverage_note(d),
    "Ranks follow dashboard eligibility, not a measure of individual risk or causal discrimination.",
    paste("Fixed release:", x$metadata$release))
  # Ratios are multiplicative and the allocation bands can span orders of
  # magnitude where a group's resident population is small, so the axis is
  # logarithmic with parity at its centre of attention.
  lower <- min(c(plotted$ratio_min, plotted$ci_lower, plotted$ratio, 0.8), na.rm = TRUE) * 0.85
  upper <- max(c(plotted$label_x, 1.25), na.rm = TRUE) * 1.9
  breaks <- c(0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100, 200, 500)
  p <- ggplot2::ggplot(plotted, ggplot2::aes(y = axis_label)) +
    ggplot2::geom_vline(xintercept = 1, colour = col[["secondary"]], linewidth = 0.5) +
    ggplot2::geom_segment(ggplot2::aes(x = ratio_min, xend = ratio_max, yend = axis_label,
                                       colour = range_levels[2]),
                          linewidth = 4.5, lineend = "butt", na.rm = TRUE) +
    ggplot2::geom_linerange(ggplot2::aes(xmin = ci_lower, xmax = ci_upper, colour = range_levels[1]),
                            linewidth = 1.1, na.rm = TRUE) +
    ggplot2::geom_point(ggplot2::aes(x = ratio, fill = fill_label), shape = 21, size = 3.2,
                        colour = col[["surface"]], stroke = 0.7) +
    ggplot2::geom_text(ggplot2::aes(x = label_x, label = value_label), hjust = -0.25,
                       colour = col[["ink"]], size = 3.6) +
    ggplot2::annotate("text", x = 1, y = Inf, label = "parity", hjust = -0.15, vjust = 1.4,
                      colour = col[["secondary"]], size = 3) +
    ggplot2::scale_colour_manual(values = stats::setNames(c(col[["ink"]], col[["bar_partial"]]), range_levels),
                                 breaks = range_levels) +
    ggplot2::scale_fill_manual(values = stats::setNames(c(col[["bar"]], col[["ink"]]), fill_levels),
                               breaks = present,
                               guide = if (length(present) > 1L) "legend" else "none") +
    ggplot2::scale_x_log10(labels = function(z) paste0(z, "x"),
                           breaks = breaks[breaks >= lower & breaks <= upper],
                           limits = c(lower, upper),
                           expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.6, 1.1))) +
    ggplot2::labs(title = sprintf("How robust are the %s:White stop-rate ratios, %d?", chart$group, chart$year),
                  subtitle = subtitle,
                  x = "Recorded stop-rate ratio (1x = White baseline; logarithmic scale)",
                  y = NULL, colour = NULL, fill = NULL, caption = caption) +
    ggplot2::guides(colour = ggplot2::guide_legend(order = 1, nrow = 2),
                    fill = ggplot2::guide_legend(order = 2)) +
    btg_theme() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  attr(p, "btg_figure_data") <- d
  attr(p, "btg_view") <- list(
    schema_version = 2L, chart = "force_disparity_sensitivity", chart_version = 1L,
    dataset = x$selection$dataset, release = x$metadata$release,
    data_sha256 = spec$sha256,
    coverage_sha256 = if (!is.null(spec$coverage)) x$metadata$files[[spec$coverage]]$sha256 else "",
    force = x$selection$force, year = chart$year, group = chart$group,
    n = as.integer(n), ranking = ranking,
    highlight = if (is.null(highlight)) NA_character_ else highlight)
  p
}

#' Summarise robustness across every year and group
#'
#' One row per year and group of a force-level comparison dataset: how many
#' forces have counts, how many meet the display rule, how many of those keep
#' their side of parity under every allocation of unknown-ethnicity stops,
#' how large the unknown share typically is, how wide the sampling rank
#' intervals are and how many forces have full-year returns. It is the table
#' a study of robustness starts from, built from [btg_sensitivity()] and
#' [btg_rank_stability()].
#'
#' @inheritParams btg_rank_stability
#' @param certain The `prob_top` at or above which a force's place in the
#'   top `top` is counted as settled.
#' @return A data frame with `year`, `group`, `forces` (with counts),
#'   `eligible`, `above`, `below`, `sensitive`, `median_unknown_share`,
#'   `max_unknown_share`, `median_rank_interval` (upper minus lower),
#'   `settled_top` (forces whose `prob_top` is at least `certain`),
#'   `full_year_returns` (forces with all twelve months supplied) and
#'   `months_in_source`. The attributes `draws`, `seed`, `top`, `certain`,
#'   `dataset` and `release` record the settings and evidence.
#' @export
#' @examples
#' y <- btg_get_data("force_ethnicity_year", years = 2024:2025, groups = c("Black", "Asian"))
#' btg_robustness_summary(y, draws = 300)
btg_robustness_summary <- function(x, draws = 2000L, seed = 1L, top = 10L, certain = 0.9) {
  if (!is.numeric(certain) || length(certain) != 1L || is.na(certain) || certain < 0 || certain > 1) {
    stop("certain must be a probability between 0 and 1.", call. = FALSE)
  }
  s <- btg_sensitivity(x)
  if (!"eligible" %in% names(s)) stop("Robustness summaries apply to force-level comparison datasets.", call. = FALSE)
  r <- if (any(s$eligible)) btg_rank_stability(x, draws = draws, seed = seed, top = top) else NULL
  months <- if ("months_in_source" %in% names(x$data)) x$data$months_in_source else .months_in_source(x, x$data$year)
  keys <- unique(s[c("year", "group")])
  rows <- lapply(seq_len(nrow(keys)), function(i) {
    block <- s[s$year == keys$year[i] & s$group == keys$group[i], ]
    eligible <- block[block$eligible, ]
    ranks <- if (!is.null(r)) r[r$year == keys$year[i] & r$group == keys$group[i], ] else NULL
    data.frame(
      year = keys$year[i], group = keys$group[i],
      forces = sum(!is.na(block$group_stops)), eligible = nrow(eligible),
      above = sum(eligible$parity_direction %in% "above"),
      below = sum(eligible$parity_direction %in% "below"),
      sensitive = sum(eligible$parity_direction %in% "sensitive"),
      median_unknown_share = stats::median(block$unknown_share, na.rm = TRUE),
      max_unknown_share = if (any(!is.na(block$unknown_share))) max(block$unknown_share, na.rm = TRUE) else NA_real_,
      median_rank_interval = if (!is.null(ranks) && nrow(ranks)) stats::median(ranks$rank_upper - ranks$rank_lower) else NA_real_,
      settled_top = if (!is.null(ranks) && nrow(ranks)) sum(ranks$prob_top >= certain) else 0L,
      full_year_returns = sum(block$coverage_status == "all_months_supplied"),
      months_in_source = months[match(keys$year[i], x$data$year)],
      stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out <- out[order(out$year, out$group), ]
  rownames(out) <- NULL
  attr(out, "draws") <- draws
  attr(out, "seed") <- seed
  attr(out, "top") <- top
  attr(out, "certain") <- certain
  attr(out, "dataset") <- x$selection$dataset
  attr(out, "release") <- x$metadata$release
  out
}
