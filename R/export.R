# Taking the evidence out of R with its provenance attached, and the words
# the package uses.

#' Export a dataset with its provenance
#'
#' Writes the rows of a dataset to a CSV file and, beside it, a JSON sidecar
#' that records the release, the source month, the SHA-256 checksums of the
#' bundled payloads, the selection, the citation and the documented
#' limitations, so that a file passed on by email or attached to a report
#' still says exactly where its numbers came from.
#'
#' @param x A dataset from [btg_get_data()].
#' @param path Path of the CSV file to write. The sidecar takes the same
#'   name with the extension `.json`, and the monthly coverage table, when
#'   the dataset has one, the suffix `-coverage.csv`.
#' @param overwrite Whether to replace existing files.
#' @return A character vector of the written paths, invisibly.
#' @export
#' @examples
#' path <- tempfile(fileext = ".csv")
#' btg_export(btg_get_data(force = c("metropolitan", "kent")), path)
#' list.files(dirname(path), basename(sub("[.]csv$", "", path)))
#' unlink(list.files(dirname(path), basename(sub("[.]csv$", "", path)), full.names = TRUE))
btg_export <- function(x, path, overwrite = FALSE) {
  .validate_dataset(x)
  .scalar_string(path, "path")
  if (!grepl("[.]csv$", path, ignore.case = TRUE)) stop("path must end in .csv.", call. = FALSE)
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("overwrite must be TRUE or FALSE.", call. = FALSE)
  }
  stem <- sub("[.]csv$", "", path, ignore.case = TRUE)
  files <- c(data = path, provenance = paste0(stem, ".json"))
  if (!is.null(x$coverage)) files[["coverage"]] <- paste0(stem, "-coverage.csv")
  existing <- files[file.exists(files)]
  if (length(existing) && !overwrite) {
    stop("File exists; use overwrite = TRUE: ", paste(existing, collapse = ", "), call. = FALSE)
  }
  spec <- .dataset_spec(x$metadata, x$selection$dataset)
  utils::write.csv(x$data, files[["data"]], row.names = FALSE, na = "NA")
  if (!is.null(x$coverage)) utils::write.csv(x$coverage, files[["coverage"]], row.names = FALSE, na = "NA")
  provenance <- list(
    package = "BlackThriveSS", package_version = as.character(utils::packageVersion("BlackThriveSS")),
    exported_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    dataset = x$selection$dataset, title = spec$title, release = x$metadata$release,
    source = x$metadata$source, dashboard_built_at = x$metadata$dashboard_built_at,
    payload_sha256 = list(data = spec$sha256,
                          coverage = if (!is.null(spec$coverage)) x$metadata$files[[spec$coverage]]$sha256 else NULL),
    selection = x$selection, rows = nrow(x$data), files = as.list(basename(files)),
    citation = btg_citation(x), licence = x$metadata$licence,
    calculation = x$metadata$calculation, limitations = x$metadata$limitations)
  jsonlite::write_json(provenance, files[["provenance"]], auto_unbox = TRUE, pretty = TRUE, digits = NA, null = "null")
  invisible(unname(files))
}

#' The terms BlackThriveSS uses
#'
#' Definitions of the measures and labels that appear in the package's
#' datasets, charts and briefings, for readers who need to know exactly what
#' a word means before they quote a number.
#'
#' @return A data frame with `term` and `definition`.
#' @export
#' @examples
#' btg_glossary()
#' btg_glossary()[btg_glossary()$term == "ratio", "definition"]
btg_glossary <- function() {
  terms <- c(
    "recorded stops" = "Stop and search events recorded by a force and published by Police.uk. Events, not people: one person stopped twice is two events.",
    "officer-defined ethnicity" = "The ethnic group the officer recorded for the person stopped. It is compared with Census ethnicity, which people report for themselves; the two classifications differ.",
    "unknown ethnicity" = "Recorded stops with no officer-defined ethnic group. They are left out of ratios but counted separately, and the allocation range shows how far they could move a ratio.",
    "rate per 1,000 residents" = "Recorded stops of a group divided by the group's Census 2021 resident population, times 1,000. Residents are a proxy for the people present in an area, not a measure of who was there.",
    "ratio" = "A group's rate per 1,000 residents divided by the White rate. 1x is parity; 4x means four times the recorded rate of White residents. It is descriptive and does not establish discrimination.",
    "95% interval" = "An approximate Poisson interval on the recorded counts. It describes sampling variability only, not missing returns, classification or the choice of denominator.",
    "allocation range" = "The ratio if every stop with unknown ethnicity were counted as White (lower end) or as the compared group (upper end). Any allocation of those stops gives a ratio inside the range.",
    "eligible" = "The dashboard's display rule: a positive, finite ratio from at least 200 stops with known ethnicity and comparable resident populations. It is not a measure of complete reporting.",
    "rank" = "Position among the eligible forces of the same year and group, ordered by ratio, with ties sharing the lower number. Rank intervals show how far sampling variability alone could move it.",
    "coverage" = "Whether a force's monthly return for a month is supplied, missing or unverified. Supplied is not proof of complete recording; missing is never treated as zero.",
    "unverified" = "A month outside the window in which the dashboard checks submissions. Its counts are as published and its completeness is not known.",
    "partial year" = "A year with at least one supplied and at least one missing month. Counts cover the supplied months only and are not annualised; a ratio of two counts from the same months is not affected under uniform reporting.",
    "months in source" = "How many months of a calendar year the Police.uk source month covers. The final source year is incomplete.",
    "Section 60" = "A search under Section 60 of the Criminal Justice and Public Order Act 1994, authorised for an area and time without individual suspicion.",
    "outcome linked to object of search" = "The share of searches with a known outcome whose outcome was linked to what the search was looking for, sometimes called the find rate. Forces that omit or machine-fill the field are voided upstream.",
    "release" = "An immutable, checksummed snapshot of the dashboard's aggregates. A new source month or method produces a new release identifier; existing releases are never overwritten.",
    "saved view" = "A JSON file that pins a chart to a release, a selection and settings so that it replays with identical numbers. It carries no code.")
  data.frame(term = names(terms), definition = unname(terms), stringsAsFactors = FALSE)
}
