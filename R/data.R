.catalogue <- function() {
  file <- system.file("extdata", "catalogue.json", package = "BlackThriveSS")
  if (!nzchar(file)) stop("The bundled data catalogue is missing.", call. = FALSE)
  catalogue <- jsonlite::read_json(file, simplifyVector = TRUE)
  if (is.null(catalogue$default_releases)) {
    catalogue$default_releases <- list(force_disparity = catalogue$default_release)
  }
  catalogue
}

.scalar_string <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop(name, " must be one non-empty character string.", call. = FALSE)
  }
}

# A release manifest. Schema 1 holds the single 2025 force_disparity dataset;
# schema 2 holds a catalogue of datasets plus one monthly coverage table.
.release <- function(release = NULL, dataset = NULL) {
  catalogue <- .catalogue()
  if (is.null(release)) {
    release <- if (is.null(dataset)) catalogue$default_release else catalogue$default_releases[[dataset]]
    if (is.null(release)) stop("Unsupported dataset. Use btg_datasets() to list the catalogue.", call. = FALSE)
  }
  .scalar_string(release, "release")
  if (!release %in% catalogue$releases) {
    stop("Unknown release. Use btg_releases() to list bundled releases.", call. = FALSE)
  }
  path <- system.file("extdata", release, "manifest.json", package = "BlackThriveSS")
  manifest <- jsonlite::read_json(path, simplifyVector = TRUE)
  if (!identical(manifest$release, release) || !manifest$schema_version %in% c(1L, 2L)) {
    stop("Invalid bundled release manifest.", call. = FALSE)
  }
  manifest
}

# The datasets a manifest carries, each as a list with file, sha256 and
# descriptive fields; schema 1 is presented in the same shape.
.manifest_datasets <- function(manifest) {
  if (identical(manifest$schema_version, 1L)) {
    return(list(force_disparity = c(manifest$files$data, list(
      title = "Black to White stop-rate comparison by police force",
      level = "force", years = c(manifest$year, manifest$year), groups = "Black",
      coverage = "coverage", rows = NA_integer_,
      description = "The dashboard's 2025 officer-defined Black to White force comparison, the package's original fixed dataset."))))
  }
  manifest$datasets
}

.dataset_spec <- function(manifest, dataset) {
  spec <- .manifest_datasets(manifest)[[dataset]]
  if (is.null(spec)) stop("Release ", manifest$release, " does not contain dataset ", dataset, ".", call. = FALSE)
  spec
}

.read_payload <- function(manifest, item) {
  if (is.character(item)) item <- manifest$files[[item]]
  path <- system.file("extdata", manifest$release, item$file, package = "BlackThriveSS")
  if (!nzchar(path) || !identical(digest::digest(file = path, algo = "sha256"), item$sha256)) {
    stop("Bundled ", item$file, " failed its SHA-256 integrity check.", call. = FALSE)
  }
  con <- if (grepl("[.]gz$", item$file)) gzfile(path, "rt") else file(path, "rt")
  on.exit(close(con))
  utils::read.csv(con, stringsAsFactors = FALSE, na.strings = "NA", check.names = FALSE)
}

#' Discover bundled dashboard datasets
#'
#' One row per dataset in the bundled catalogue, with the release that
#' [btg_get_data()] reads by default.
#' @return A data frame with `dataset`, `title`, `level` (`force`, `council`
#'   or `national`), `from`, `to` (calendar years), `groups` (comma-separated
#'   ethnic groups, empty when the dataset has none), `coverage` (whether a
#'   monthly submission table accompanies it) and `release`.
#' @export
#' @examples
#' btg_datasets()
btg_datasets <- function() {
  catalogue <- .catalogue()
  rows <- lapply(names(catalogue$default_releases), function(dataset) {
    release <- catalogue$default_releases[[dataset]]
    spec <- .dataset_spec(.release(release), dataset)
    data.frame(dataset = dataset, title = spec$title, level = spec$level,
               from = as.integer(spec$years[1]), to = as.integer(spec$years[2]),
               groups = paste(spec$groups, collapse = ", "),
               coverage = !is.null(spec$coverage), release = release,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' List fixed releases available offline
#' @return A data frame with one row per bundled release: its identifier, the
#'   Police.uk source month, when the dashboard built its aggregates, and the
#'   datasets the release contains.
#' @export
#' @examples
#' btg_releases()
btg_releases <- function() {
  rows <- lapply(.catalogue()$releases, function(id) {
    m <- .release(id)
    data.frame(release = id, source_month = m$source$latest_month,
               dashboard_built_at = m$dashboard_built_at,
               datasets = paste(names(.manifest_datasets(m)), collapse = ", "),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

.check_subset <- function(value, allowed, name, what) {
  if (!is.character(value) || !length(value) || anyNA(value) || anyDuplicated(value) ||
      any(!value %in% allowed)) {
    stop(name, " must contain unique, supported ", what, ".", call. = FALSE)
  }
  sort(value, method = "radix")
}

.check_years <- function(years, available) {
  if (!is.numeric(years) || !length(years) || anyNA(years) || any(years != floor(years)) ||
      anyDuplicated(years) || any(!years %in% available)) {
    stop("years must be distinct calendar years between ", min(available), " and ",
         max(available), ".", call. = FALSE)
  }
  sort(as.integer(years))
}

#' Read a fixed dashboard dataset with coverage and provenance
#'
#' Reads one dataset from the bundled catalogue, verifies its checksum, applies
#' the requested selection and returns the rows with their monthly coverage and
#' provenance. Rates divide recorded events by Census 2021 residents. They are
#' not individual stop probabilities or causal estimates.
#'
#' @param dataset A dataset name from [btg_datasets()]. The default,
#'   `"force_disparity"`, is the original 2025 Black to White force comparison.
#' @param force Optional character vector of exact Police.uk identifiers, such
#'   as `"metropolitan"`, for force-level datasets. See `x$data$force`.
#' @param years Calendar years to keep. `NULL` keeps every year the dataset
#'   holds; `force_disparity` holds 2025 only.
#' @param groups Ethnic groups to keep, for datasets with a `group` column.
#'   `NULL` keeps all of them.
#' @param council Optional character vector of ONS local-authority codes, such
#'   as `"E09000022"`, for the council-level dataset. See `x$data$council`.
#' @param release A value from [btg_releases()]. `NULL` selects the dataset's
#'   default release; saved views always carry an explicit release identifier.
#' @return A `btg_dataset` list containing an ordinary data frame `data`, a
#'   `coverage` data frame of force-month submission statuses (`NULL` for
#'   datasets without one), an explicit `metadata` list and a `selection` list.
#'   Missing force returns remain missing; they are never imputed as zero stops.
#' @details Force-level comparison datasets hold group and White counts, known
#'   and unknown ethnicity counts, Census populations, rates per 1,000, the
#'   rate ratio, approximate Poisson log-ratio intervals, display eligibility,
#'   ranks within each year and group, and submission coverage. The intervals
#'   condition on recorded counts and fixed denominators: they do not capture
#'   missing-return, classification or exposure uncertainty. `eligible`
#'   reproduces the dashboard's rule (positive finite ratio and at least 200
#'   records with known ethnicity, with resident-rate exclusions). It does not
#'   imply complete reporting. The dashboard verifies monthly submissions only
#'   inside a recent window; earlier months are `unverified`, never assumed
#'   supplied. See `system.file("NOTES", "data-dictionary.md", package =
#'   "BlackThriveSS")` for every column.
#' @export
#' @examples
#' x <- btg_get_data()
#' head(x$data)
#' btg_get_data(force = "metropolitan")$data
#'
#' y <- btg_get_data("force_ethnicity_year", groups = "Black", years = 2023:2025)
#' head(y$data[c("force_label", "year", "ratio", "coverage_status")])
#' btg_get_data("national_year")$data[c("year", "stops", "arrest_rate")]
btg_get_data <- function(dataset = "force_disparity", force = NULL, years = NULL,
                         groups = NULL, council = NULL, release = NULL) {
  .scalar_string(dataset, "dataset")
  catalogue <- .catalogue()
  if (!dataset %in% names(catalogue$default_releases)) {
    stop("Unsupported dataset. Use btg_datasets() to list the catalogue.", call. = FALSE)
  }
  m <- .release(release, dataset)
  spec <- .dataset_spec(m, dataset)
  d <- .read_payload(m, spec)
  coverage <- if (!is.null(spec$coverage)) .read_payload(m, spec$coverage) else NULL
  selection <- list(dataset = dataset)

  if (identical(dataset, "force_disparity")) {
    years <- years %||% 2025L
    if (!is.numeric(years) || length(years) != 1L || is.na(years) || years != 2025) {
      stop("This release supports only calendar year 2025.", call. = FALSE)
    }
    if (!is.null(groups) && !identical(groups, "Black")) {
      stop("force_disparity holds the Black to White comparison only.", call. = FALSE)
    }
    if (!is.null(council)) stop("council applies to the council-level dataset only.", call. = FALSE)
    force <- .check_subset(force %||% d$force, d$force, "force", "Police.uk force identifiers")
    d <- d[match(force, d$force), , drop = FALSE]
    coverage <- coverage[coverage$force %in% force, , drop = FALSE]
    selection$force <- force
    selection$year <- 2025L
  } else {
    available_years <- seq.int(spec$years[1], spec$years[2])
    years <- if (is.null(years)) available_years else .check_years(years, available_years)
    if ("year" %in% names(d)) {
      d <- d[d$year %in% years, , drop = FALSE]
    } else if ("month" %in% names(d)) {
      d <- d[as.integer(substr(d$month, 1, 4)) %in% years, , drop = FALSE]
    }
    selection$years <- years
    if (identical(spec$level, "force")) {
      force <- .check_subset(force %||% unique(d$force), unique(d$force), "force",
                             "Police.uk force identifiers")
      d <- d[d$force %in% force, , drop = FALSE]
      selection$force <- force
    } else if (!is.null(force)) {
      stop("force applies to force-level datasets only.", call. = FALSE)
    }
    if (identical(spec$level, "council")) {
      council <- .check_subset(council %||% unique(d$council), unique(d$council), "council",
                               "ONS local-authority codes")
      d <- d[d$council %in% council, , drop = FALSE]
      selection$council <- council
    } else if (!is.null(council)) {
      stop("council applies to the council-level dataset only.", call. = FALSE)
    }
    if ("group" %in% names(d)) {
      groups <- .check_subset(groups %||% spec$groups, spec$groups, "groups", "ethnic groups")
      d <- d[d$group %in% groups, , drop = FALSE]
      selection$groups <- groups
    } else if (!is.null(groups)) {
      stop("groups applies to datasets with a group column only.", call. = FALSE)
    }
    if (!is.null(coverage)) {
      coverage <- coverage[coverage$force %in% selection$force &
                             as.integer(substr(coverage$month, 1, 4)) %in% years, , drop = FALSE]
    }
    if (!nrow(d)) stop("The selection matches no rows.", call. = FALSE)
  }
  rownames(d) <- NULL
  if (!is.null(coverage)) rownames(coverage) <- NULL
  structure(list(data = d, coverage = coverage, metadata = m, selection = selection),
            class = "btg_dataset")
}

.validate_dataset <- function(x) {
  if (!inherits(x, "btg_dataset") || !is.list(x$metadata) || !is.list(x$selection)) {
    stop("Use btg_get_data() to supply a documented dataset.", call. = FALSE)
  }
  .scalar_string(x$metadata$release, "release")
  s <- x$selection
  if (is.null(s$dataset)) stop("The dataset selection is missing.", call. = FALSE)
  canonical <- btg_get_data(s$dataset, force = s[["force"]], years = s[["years"]] %||% s[["year"]],
                            groups = s[["groups"]], council = s[["council"]], release = x$metadata$release)
  if (!identical(x, canonical)) {
    stop("Dataset or provenance has changed. Reload with btg_get_data(); analyse a copy of x$data for custom work.", call. = FALSE)
  }
  invisible(x)
}

#' Inspect snapshot provenance
#' @param x A dataset from [btg_get_data()].
#' @return An explicit list containing source attribution, checksums, definitions
#'   and limitations. This is stored separately from table attributes.
#' @export
#' @examples
#' btg_metadata(btg_get_data())$source
btg_metadata <- function(x) {
  .validate_dataset(x)
  x$metadata
}

#' Inspect monthly submission coverage
#' @param x A dataset from [btg_get_data()].
#' @return A data frame of force-month submission statuses and available records,
#'   or `NULL` with a message for datasets without a coverage table. A supplied
#'   return does not certify that every event was recorded; an `unverified`
#'   month lies outside the window the dashboard checks.
#' @export
#' @examples
#' btg_coverage(btg_get_data(force = "metropolitan"))
btg_coverage <- function(x) {
  .validate_dataset(x)
  if (is.null(x$coverage)) {
    message("Dataset ", x$selection$dataset, " has no monthly coverage table.")
    return(invisible(NULL))
  }
  x$coverage
}

#' @export
print.btg_dataset <- function(x, ...) {
  s <- x$selection
  spec <- .dataset_spec(x$metadata, s$dataset)
  # [[ ]] rather than $: a selection with only `years` must not partially match `year`
  period <- if (!is.null(s[["year"]])) s[["year"]] else paste(range(s[["years"]]), collapse = " to ")
  cat("BlackThriveSS: ", s$dataset, " (", period, ")\n",
      "Release: ", x$metadata$release, "\n",
      nrow(x$data), " rows at ", spec$level, " level",
      if ("eligible" %in% names(x$data)) paste0("; ", sum(x$data$eligible), " with dashboard-eligible ratios"),
      "\n", "Tables: $data", if (!is.null(x$coverage)) " and $coverage", "; provenance: $metadata\n",
      sep = "")
  invisible(x)
}

#' Cite a fixed evidence release
#' @param x A dataset from [btg_get_data()].
#' @return A character string identifying the package, data release and sources.
#' @export
#' @examples
#' btg_citation(btg_get_data())
btg_citation <- function(x) {
  .validate_dataset(x)
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  paste0("Black Thrive Global (2026). BlackThriveSS development snapshot, release ",
         x$metadata$release, ", dataset ", x$selection$dataset, " (", spec$title, "). ",
         "Police.uk stop-and-search records and ONS Census 2021 resident populations. ",
         "Contains public sector information licensed under the Open Government Licence v3.0. ",
         "https://data.police.uk/about/ ; https://www.nomisweb.co.uk/sources/census_2021")
}
