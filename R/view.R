.view_fields <- list(
  `1` = c("schema_version", "chart", "chart_version", "dataset", "release",
          "data_sha256", "coverage_sha256", "force", "year", "n", "ranking"),
  `2` = c("schema_version", "chart", "chart_version", "dataset", "release",
          "data_sha256", "coverage_sha256", "force", "year", "group", "n", "ranking", "highlight"),
  `3` = c("schema_version", "chart", "chart_version", "dataset", "release",
          "data_sha256", "coverage_sha256", "selection", "settings")
)

# The charts a saved view can describe. Schemas 1 and 2 describe the force
# ranking charts field by field; schema 3 carries the dataset selection and
# the chart's own settings, and names the settings each chart accepts.
.view_charts <- c("force_disparity_ranking", "force_disparity_sensitivity")
.view_settings <- list(
  trend = c("measure", "highlight"),
  change = c("from", "to", "group", "n", "order")
)
.selection_fields <- c("force", "years", "year", "groups", "council")

# A schema 3 view for a chart drawn from dataset x with the given settings.
.new_view <- function(x, chart, settings) {
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  selection <- x$selection[intersect(.selection_fields, names(x$selection))]
  list(schema_version = 3L, chart = chart, chart_version = 1L,
       dataset = x$selection$dataset, release = x$metadata$release,
       data_sha256 = spec$sha256,
       coverage_sha256 = if (!is.null(spec$coverage)) x$metadata$files[[spec$coverage]]$sha256 else "",
       selection = selection, settings = settings)
}

.validate_view <- function(view) {
  if (!is.list(view) || anyDuplicated(names(view)) ||
      !is.numeric(view$schema_version) || length(view$schema_version) != 1L ||
      is.na(view$schema_version) || !view$schema_version %in% c(1, 2, 3)) {
    stop("Unsupported saved-view schema_version.", call. = FALSE)
  }
  fields <- .view_fields[[as.character(as.integer(view$schema_version))]]
  if (!setequal(names(view), fields)) stop("Invalid saved-view fields.", call. = FALSE)
  if (!is.numeric(view$chart_version) || length(view$chart_version) != 1L ||
      is.na(view$chart_version) || view$chart_version != 1) {
    stop("Unsupported saved-view chart_version.", call. = FALSE)
  }
  for (field in c("chart", "dataset", "release", "data_sha256")) {
    .scalar_string(view[[field]], field)
  }
  # datasets without a monthly coverage table carry an empty coverage checksum
  if (!is.character(view$coverage_sha256) || length(view$coverage_sha256) != 1L || is.na(view$coverage_sha256)) {
    stop("coverage_sha256 must be one character string.", call. = FALSE)
  }
  if (view$schema_version == 3) {
    if (!view$chart %in% names(.view_settings)) stop("Unsupported saved-view chart.", call. = FALSE)
    selection <- view$selection
    settings <- view$settings
    if (!is.list(selection) || !length(selection) || is.null(names(selection)) ||
        anyDuplicated(names(selection)) || !all(names(selection) %in% .selection_fields)) {
      stop("Invalid saved-view selection.", call. = FALSE)
    }
    if (!is.list(settings) || !setequal(names(settings), .view_settings[[view$chart]])) {
      stop("Invalid saved-view settings.", call. = FALSE)
    }
    x <- btg_get_data(view$dataset, force = selection[["force"]],
                      years = selection[["years"]] %||% selection[["year"]],
                      groups = selection[["groups"]], council = selection[["council"]],
                      release = view$release)
  } else {
    .scalar_string(view$ranking, "ranking")
    if (!view$chart %in% .view_charts ||
        (view$schema_version == 1 && !identical(view$chart, "force_disparity_ranking"))) {
      stop("Unsupported saved-view chart.", call. = FALSE)
    }
    if (is.null(view$force)) stop("Saved view must identify its force selection.", call. = FALSE)
    .plot_args(view$n, view$ranking)
    if (view$schema_version == 1) {
      x <- btg_get_data(view$dataset, view$force, view$year, release = view$release)
    } else {
      .scalar_string(view$group, "group")
      if (!is.numeric(view$year) || length(view$year) != 1L || is.na(view$year)) {
        stop("Saved view must name one calendar year.", call. = FALSE)
      }
      x <- btg_get_data(view$dataset, view$force, as.integer(view$year), groups = view$group,
                        release = view$release)
      if (!is.null(view$highlight) && !is.na(view$highlight)) {
        .scalar_string(view$highlight, "highlight")
        if (!view$highlight %in% x$data$force) stop("Saved view highlights a force outside its selection.", call. = FALSE)
      }
    }
  }
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  coverage_sha <- if (!is.null(spec$coverage)) x$metadata$files[[spec$coverage]]$sha256 else ""
  if (!identical(view$data_sha256, spec$sha256) || !identical(view$coverage_sha256, coverage_sha)) {
    stop("Saved-view checksums do not match the pinned release.", call. = FALSE)
  }
  x
}

# Draw a schema 3 view: settings are passed as arguments, never evaluated.
.draw_view <- function(view, x) {
  s <- view$settings
  optional <- function(v) if (is.null(v) || (length(v) == 1L && is.na(v))) NULL else v
  switch(view$chart,
    trend = btg_plot_trend(x, measure = s[["measure"]], highlight = optional(s[["highlight"]])),
    change = btg_plot_change(x, from = s[["from"]], to = s[["to"]], group = optional(s[["group"]]),
                             n = s[["n"]], order = s[["order"]]))
}

#' Save the evidence specification for a reproducible chart
#' @param p A plot from [btg_plot_disparity()], [btg_from_view()] or [btg_from_url()].
#' @param path Path for the JSON view file.
#' @param overwrite Whether to replace an existing file. Defaults to `FALSE`.
#' @return The file path, invisibly.
#' @details Saves release identifiers, SHA-256 checksums, the dataset
#'   selection, the chart's settings and its chart version. User-added ggplot
#'   styling is not serialised. Numerical replay is guaranteed for supported versions;
#'   pixel identity requires the same fonts, graphics dependencies and
#'   rendering settings. No R code is stored or run.
#' @export
#' @examples
#' path <- tempfile(fileext = ".json")
#' btg_save_view(btg_plot_disparity(), path)
#' btg_from_view(path)
#' unlink(path)
btg_save_view <- function(p, path, overwrite = FALSE) {
  .scalar_string(path, "path")
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("overwrite must be TRUE or FALSE.", call. = FALSE)
  }
  if (file.exists(path) && !overwrite) stop("File exists; use overwrite = TRUE.", call. = FALSE)
  view <- attr(p, "btg_view", exact = TRUE)
  if (is.null(view)) stop("No BlackThriveSS view on this plot.", call. = FALSE)
  .validate_view(view)
  jsonlite::write_json(view, path, auto_unbox = TRUE, pretty = TRUE, digits = NA, na = "null")
  invisible(path)
}

#' Reproduce a chart from a pinned view file
#' @param path A local JSON file created by [btg_save_view()].
#' @return A ggplot with the original evidence table and saved specification.
#' @details Unknown releases, checksums, fields or chart versions fail explicitly.
#'   Files cannot trigger downloads or execute code. Views written by earlier
#'   package versions (schema 1) replay unchanged. A view names its chart, so
#'   a view saved from [btg_plot_sensitivity()], [btg_plot_trend()] or
#'   [btg_plot_change()] replays that chart with its settings. A dashboard
#'   link is not a view file; use [btg_from_url()] for links.
#' @export
#' @examples
#' file <- system.file("examples", "disparity-2025.json", package = "BlackThriveSS")
#' btg_from_view(file)
btg_from_view <- function(path) {
  .scalar_string(path, "path")
  if (!file.exists(path) || dir.exists(path)) stop("View file does not exist.", call. = FALSE)
  if (file.info(path)$size > 65536) stop("View file exceeds 64 KiB.", call. = FALSE)
  view <- tryCatch(jsonlite::read_json(path, simplifyVector = TRUE),
                   error = function(e) stop("Invalid saved-view JSON.", call. = FALSE))
  x <- .validate_view(view)
  if (view$schema_version == 3) return(.draw_view(view, x))
  draw <- if (identical(view$chart, "force_disparity_sensitivity")) btg_plot_sensitivity else btg_plot_disparity
  if (view$schema_version == 1) {
    draw(x, n = view$n, ranking = view$ranking)
  } else {
    highlight <- if (is.null(view$highlight) || is.na(view$highlight)) NULL else view$highlight
    draw(x, n = view$n, ranking = view$ranking, year = as.integer(view$year),
         group = view$group, highlight = highlight)
  }
}
