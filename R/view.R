.view_fields <- list(
  `1` = c("schema_version", "chart", "chart_version", "dataset", "release",
          "data_sha256", "coverage_sha256", "force", "year", "n", "ranking"),
  `2` = c("schema_version", "chart", "chart_version", "dataset", "release",
          "data_sha256", "coverage_sha256", "force", "year", "group", "n", "ranking", "highlight")
)

.validate_view <- function(view) {
  if (!is.list(view) || anyDuplicated(names(view)) ||
      !is.numeric(view$schema_version) || length(view$schema_version) != 1L ||
      is.na(view$schema_version) || !view$schema_version %in% c(1, 2)) {
    stop("Unsupported saved-view schema_version.", call. = FALSE)
  }
  fields <- .view_fields[[as.character(as.integer(view$schema_version))]]
  if (!setequal(names(view), fields)) stop("Invalid saved-view fields.", call. = FALSE)
  if (!is.numeric(view$chart_version) || length(view$chart_version) != 1L ||
      is.na(view$chart_version) || view$chart_version != 1) {
    stop("Unsupported saved-view chart_version.", call. = FALSE)
  }
  for (field in c("chart", "dataset", "release", "data_sha256", "coverage_sha256", "ranking")) {
    .scalar_string(view[[field]], field)
  }
  if (!identical(view$chart, "force_disparity_ranking")) {
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
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  coverage_sha <- if (!is.null(spec$coverage)) x$metadata$files[[spec$coverage]]$sha256 else ""
  if (!identical(view$data_sha256, spec$sha256) || !identical(view$coverage_sha256, coverage_sha)) {
    stop("Saved-view checksums do not match the pinned release.", call. = FALSE)
  }
  x
}

#' Save the evidence specification for a reproducible chart
#' @param p A plot from [btg_plot_disparity()], [btg_from_view()] or [btg_from_url()].
#' @param path Path for the JSON view file.
#' @param overwrite Whether to replace an existing file. Defaults to `FALSE`.
#' @return The file path, invisibly.
#' @details Saves release identifiers, SHA-256 checksums, selection, year,
#'   group, highlighted force and chart version. User-added ggplot styling is
#'   not serialised. Numerical replay is guaranteed for supported versions;
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
#'   package versions (schema 1) replay unchanged. A dashboard link is not a
#'   view file; use [btg_from_url()] for links.
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
  if (view$schema_version == 1) {
    btg_plot_disparity(x, n = view$n, ranking = view$ranking)
  } else {
    highlight <- if (is.null(view$highlight) || is.na(view$highlight)) NULL else view$highlight
    btg_plot_disparity(x, n = view$n, ranking = view$ranking, year = as.integer(view$year),
                       group = view$group, highlight = highlight)
  }
}
