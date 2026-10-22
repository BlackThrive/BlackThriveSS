# Checking the bundled snapshot against the live Police.uk source: has a
# newer month been published, and have any force-months been added or
# withdrawn since the snapshot was taken? The only function in the package
# that touches the network, and it fails quietly with a message.

.availability_url <- "https://data.police.uk/api/crimes-street-dates"

# Read the availability feed into one row per month and force. Returns NULL,
# with a message, when the resource cannot be read.
.read_availability <- function(url, timeout) {
  old <- options(timeout = timeout, warn = -1)
  on.exit(options(old), add = TRUE)
  con <- NULL
  on.exit(if (!is.null(con)) try(close(con), silent = TRUE), add = TRUE)
  text <- tryCatch({
    con <- url(url, open = "rb")
    readLines(con, warn = FALSE, encoding = "UTF-8")
  }, error = function(e) NULL)
  if (is.null(text)) {
    message("Could not read ", url, " within ", timeout, " seconds; the live source was not checked.")
    return(NULL)
  }
  parsed <- tryCatch(jsonlite::fromJSON(paste(text, collapse = "\n"), simplifyVector = FALSE),
                     error = function(e) NULL)
  if (!is.list(parsed) || !length(parsed) ||
      !all(vapply(parsed, function(m) is.list(m) && is.character(m$date), logical(1)))) {
    message("The availability feed at ", url, " was not in the expected form; the live source was not checked.")
    return(NULL)
  }
  rows <- lapply(parsed, function(m) {
    forces <- unlist(m[["stop-and-search"]])
    if (!length(forces)) return(NULL)
    data.frame(month = m$date, force = as.character(forces), stringsAsFactors = FALSE)
  })
  live <- do.call(rbind, rows)
  if (is.null(live) || !nrow(live)) return(data.frame(month = character(), force = character()))
  live <- live[grepl("^\\d{4}-\\d{2}$", live$month), ]
  live <- unique(live[order(live$month, live$force), ])
  rownames(live) <- NULL
  live
}

# Compare the live month-and-force availability with the bundled coverage.
.compare_availability <- function(live, coverage, snapshot_month) {
  window <- coverage[coverage$status != "unverified", ]
  shared <- sort(intersect(unique(window$month), unique(live$month)))
  per_month <- lapply(shared, function(m) {
    listed <- live$force[live$month == m]
    rows <- window[window$month == m, ]
    supplied <- rows$force[rows$status == "supplied"]
    missing <- rows$force[rows$status == "missing"]
    data.frame(month = m, forces_live = length(listed), forces_supplied = length(supplied),
               late_additions = sum(missing %in% listed), withdrawals = sum(!supplied %in% listed),
               stringsAsFactors = FALSE)
  })
  months <- do.call(rbind, per_month)
  if (is.null(months)) months <- data.frame(month = character(), forces_live = integer(), forces_supplied = integer(),
                                            late_additions = integer(), withdrawals = integer())
  changes <- lapply(shared, function(m) {
    listed <- live$force[live$month == m]
    rows <- window[window$month == m, ]
    late <- rows[rows$status == "missing" & rows$force %in% listed, ]
    gone <- rows[rows$status == "supplied" & !rows$force %in% listed, ]
    rbind(
      if (nrow(late)) data.frame(month = m, force = late$force, force_label = late$force_label,
                                 bundled_status = "missing", live_available = TRUE, stringsAsFactors = FALSE),
      if (nrow(gone)) data.frame(month = m, force = gone$force, force_label = gone$force_label,
                                 bundled_status = "supplied", live_available = FALSE, stringsAsFactors = FALSE))
  })
  changes <- do.call(rbind, changes)
  if (is.null(changes)) changes <- data.frame(month = character(), force = character(), force_label = character(),
                                              bundled_status = character(), live_available = logical())
  rownames(changes) <- NULL
  newer <- live[live$month > snapshot_month, ]
  newer_months <- if (nrow(newer)) {
    counts <- table(newer$month)
    data.frame(month = names(counts), forces_live = as.integer(counts), stringsAsFactors = FALSE)
  } else data.frame(month = character(), forces_live = integer())
  list(months = months, changes = changes, newer_months = newer_months,
       latest_month = if (nrow(live)) max(live$month) else NA_character_)
}

#' Check the bundled snapshot against the live Police.uk source
#'
#' Reads the Police.uk availability feed, which lists for each published
#' month the forces whose stop and search data are present, and compares it
#' with the bundled release: whether newer months have been published since
#' the snapshot's source month, and whether any force-month inside the
#' snapshot's verified coverage window has since been added (a late
#' submission) or withdrawn. This is the package's only use of the network;
#' it changes nothing and, when the feed cannot be read, returns `NULL` with
#' a message rather than an error.
#'
#' @param release A value from [btg_releases()]; `NULL` uses the default
#'   catalogue release.
#' @param timeout Seconds to wait for the feed.
#' @param url The feed address, which the manifest also records.
#' @return `NULL` when the feed could not be read; otherwise a list of class
#'   `btg_source_status` with `checked_at`, `snapshot_month`,
#'   `latest_month`, `newer_months` (one row per month published after the
#'   snapshot with the number of forces listed), `months` (one row per shared
#'   month: forces listed live, forces supplied in the snapshot, late
#'   additions and withdrawals) and `changes` (one row per force-month whose
#'   availability differs, with the bundled status). Printing it summarises
#'   these.
#' @details The feed describes availability, not counts: a force listed for
#'   a month has published some stop and search records for it. A late
#'   addition means the source now holds a return the snapshot recorded as
#'   missing; a withdrawal means the snapshot recorded a supplied return that
#'   the feed no longer lists. Either is a reason to build a new release
#'   rather than to edit this one. The feed covers a rolling window of recent
#'   months, so months the snapshot verified before that window cannot be
#'   compared and are not counted.
#' @export
#' @examples
#' \donttest{
#' status <- btg_source_status(timeout = 5)
#' if (!is.null(status)) status
#' }
btg_source_status <- function(release = NULL, timeout = 10, url = .availability_url) {
  .scalar_string(url, "url")
  if (!is.numeric(timeout) || length(timeout) != 1L || is.na(timeout) || timeout <= 0) {
    stop("timeout must be a positive number of seconds.", call. = FALSE)
  }
  x <- btg_get_data("force_ethnicity_year", release = release)
  live <- .read_availability(url, timeout)
  if (is.null(live)) return(invisible(NULL))
  checked_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  comparison <- .compare_availability(live, x$coverage, x$metadata$source$latest_month)
  structure(c(list(checked_at = checked_at, release = x$metadata$release,
                   snapshot_month = x$metadata$source$latest_month, url = url), comparison),
            class = "btg_source_status")
}

#' @export
print.btg_source_status <- function(x, ...) {
  cat("Police.uk source checked ", x$checked_at, "\n",
      "Bundled release ", x$release, " holds source month ", x$snapshot_month,
      "; the feed lists months to ", x$latest_month, ".\n", sep = "")
  if (nrow(x$newer_months)) {
    cat(nrow(x$newer_months), " newer month(s): ",
        paste(sprintf("%s (%d forces)", x$newer_months$month, x$newer_months$forces_live), collapse = ", "),
        ".\n", sep = "")
  } else cat("No newer month has been published.\n")
  if (nrow(x$months)) {
    cat("Across ", nrow(x$months), " month(s) both describe (", x$months$month[1], " to ",
        x$months$month[nrow(x$months)], "): ", sum(x$months$late_additions), " late addition(s) and ",
        sum(x$months$withdrawals), " withdrawal(s); see $changes.\n", sep = "")
  } else cat("The feed and the snapshot's verified window share no months.\n")
  invisible(x)
}
