.audit_tables <- function(d, coverage) {
  results <- list()
  check <- function(name, condition, detail) {
    results[[length(results) + 1L]] <<- data.frame(
      check = name, passed = isTRUE(condition), detail = detail, stringsAsFactors = FALSE)
  }
  table_fields <- c("force", "force_label", "year", "black_stops", "white_stops",
    "known_ethnicity_stops", "unknown_ethnicity_stops", "total_records",
    "black_population", "white_population", "months_supplied", "months_missing",
    "months_unverified", "coverage_status", "black_rate", "white_rate", "ratio",
    "ci_lower", "ci_upper", "small_population", "comparable", "eligible", "rank")
  check("schema", is.data.frame(d) && is.data.frame(coverage) &&
          all(table_fields %in% names(d)) &&
          all(c("force", "month", "status", "records") %in% names(coverage)),
        "Required evidence and monthly coverage columns exist.")
  if (!results[[1]]$passed) return(do.call(rbind, results))
  numeric_fields <- setdiff(table_fields, c("force", "force_label", "coverage_status",
                                           "small_population", "comparable", "eligible"))
  check("types", all(vapply(d[numeric_fields], is.numeric, logical(1))) &&
          is.numeric(coverage$records) && is.character(d$force) &&
          is.character(coverage$month) && is.character(coverage$status) &&
          all(vapply(d[c("small_population", "comparable", "eligible")], is.logical, logical(1))),
        "Counts, rates, labels and flags use their documented types.")
  if (!results[[2]]$passed) return(do.call(rbind, results))
  check("keys", nrow(d) > 0 && !anyNA(d$force) && !anyDuplicated(d$force) &&
          !anyNA(coverage[c("force", "month")]) &&
          !anyDuplicated(coverage[c("force", "month")]) &&
          setequal(d$force, coverage$force), "One annual row and unique monthly keys per force.")
  if (!results[[3]]$passed) return(do.call(rbind, results))
  check("period", all(d$year == 2025L) &&
          all(coverage$month %in% sprintf("2025-%02d", 1:12)) &&
          all(table(factor(coverage$force, levels = d$force)) == 12L),
        "Every selected force has all 12 coverage entries for calendar year 2025.")
  whole <- function(v) all(is.na(v) | (is.finite(v) & v >= 0 & v == floor(v)))
  count_fields <- c("black_stops", "white_stops", "known_ethnicity_stops",
    "unknown_ethnicity_stops", "total_records", "black_population", "white_population",
    "months_supplied", "months_missing", "months_unverified")
  check("counts", all(vapply(d[count_fields], whole, logical(1))) && whole(coverage$records),
        "Counts and Census populations are nonnegative whole values or missing.")
  check("missing_returns", all(coverage$status %in% c("supplied", "missing", "unverified")) &&
          all(is.na(coverage$records[coverage$status != "supplied"])) &&
          all(!is.na(coverage$records[coverage$status == "supplied"])),
        "Missing or unverified returns have missing record counts, not zeros.")
  if (any(!vapply(results, function(z) z$passed, logical(1)))) return(do.call(rbind, results))
  same <- function(a, b) isTRUE(all.equal(a, b, tolerance = 1e-12, check.attributes = FALSE))
  monthly <- lapply(d$force, function(f) coverage[coverage$force == f, , drop = FALSE])
  supplied <- vapply(monthly, function(z) sum(z$status == "supplied"), integer(1))
  missing <- vapply(monthly, function(z) sum(z$status == "missing"), integer(1))
  unverified <- vapply(monthly, function(z) sum(z$status == "unverified"), integer(1))
  totals <- vapply(monthly, function(z) if (any(z$status == "supplied"))
    sum(z$records[z$status == "supplied"]) else NA_real_, numeric(1))
  status <- ifelse(unverified > 0, "unverified", ifelse(supplied == 12, "all_months_supplied",
    ifelse(supplied == 0, "no_months_supplied", "partial_year")))
  check("coverage_summary", same(d$months_supplied, supplied) && same(d$months_missing, missing) &&
          same(d$months_unverified, unverified) && identical(d$coverage_status, status),
        "Annual submission counts and coverage labels match the monthly table.")
  check("monthly_totals", same(d$total_records, totals),
        "Annual recorded events reconcile to supplied monthly returns.")
  check("ethnicity_totals", same(d$total_records, d$known_ethnicity_stops + d$unknown_ethnicity_stops) &&
          all(d$black_stops + d$white_stops <= d$known_ethnicity_stops, na.rm = TRUE) &&
          all(vapply(d[c("black_stops", "white_stops", "known_ethnicity_stops", "unknown_ethnicity_stops")],
                     function(z) identical(is.na(z), is.na(d$total_records)), logical(1))),
        "Known and unknown ethnicity reconcile; group counts do not exceed known counts.")
  calculated <- .calculate_disparity(d)
  derived <- c("black_rate", "white_rate", "ratio", "ci_lower", "ci_upper",
               "small_population", "comparable", "eligible")
  check("derived_estimates", all(vapply(derived, function(nm) same(d[[nm]], calculated[[nm]]), logical(1))),
        "Stored rates, approximate intervals and eligibility match the documented calculations.")
  check("rank_encoding", all(is.na(d$rank[!d$eligible])) &&
          all(!is.na(d$rank[d$eligible]) & d$rank[d$eligible] >= 1 &
              d$rank[d$eligible] == floor(d$rank[d$eligible])),
        "Only eligible rows carry positive integer ranks; subsets retain full-release ranks.")
  do.call(rbind, results)
}

#' Validate the integrity and internal consistency of a fixed dataset
#'
#' Checks the bundled checksums, unchanged provenance, record totals, monthly
#' coverage and stored calculations. This is not a certification that all police
#' events were reported or that the exposure assumptions are correct.
#' @param x A dataset returned by [btg_get_data()]. Every catalogue dataset is
#'   supported; the checks that apply depend on what the dataset holds.
#' @return A data frame with `check`, `passed` and `detail` columns. Changed data
#'   or provenance raises an error. Internal consistency checks return `FALSE`
#'   for failures; use `stopifnot(all(btg_validate(x)$passed))` in a workflow.
#' @export
#' @examples
#' checks <- btg_validate(btg_get_data())
#' checks
#' stopifnot(all(checks$passed))
#' btg_validate(btg_get_data("force_ethnicity_year", years = 2025))
btg_validate <- function(x = btg_get_data()) {
  .validate_dataset(x)
  audit <- if (identical(x$selection$dataset, "force_disparity")) {
    .audit_tables(x$data, x$coverage)
  } else {
    .audit_catalogue(x$selection$dataset, x$data, x$coverage)
  }
  rbind(data.frame(check = "release_integrity", passed = TRUE,
                   detail = "SHA-256 payloads and selected evidence match the bundled release."),
        audit)
}

# Checks for the catalogue datasets: keys, whole counts, accounting identities
# and, where the dataset carries them, coverage reconciliation and the
# documented calculations.
.audit_catalogue <- function(dataset, d, coverage) {
  results <- list()
  check <- function(name, condition, detail) {
    results[[length(results) + 1L]] <<- data.frame(
      check = name, passed = isTRUE(condition), detail = detail, stringsAsFactors = FALSE)
  }
  keys <- switch(dataset,
    force_ethnicity_year = c("force", "year", "group"),
    council_ethnicity_year = c("council", "year", "group"),
    national_year = "year",
    national_month_ethnicity = c("month", "group"),
    hit_rate_ethnicity_year = c("year", "group"),
    section60_force_year = c("force", "year", "group"),
    stop("No audit is defined for dataset ", dataset, ".", call. = FALSE))
  count_fields <- intersect(names(d), c("group_stops", "white_stops", "known_ethnicity_stops",
    "unknown_ethnicity_stops", "total_records", "group_population", "white_population",
    "months_supplied", "months_missing", "months_unverified", "months_in_source", "stops",
    "arrests", "nfa", "s60", "minors", "strip_known", "strip_yes", "hit_known", "hit_yes",
    "hit_total", "s60_stops", "ethnicity_recorded"))
  check("schema", is.data.frame(d) && all(keys %in% names(d)) && length(count_fields) > 0,
        "Key and count columns exist.")
  if (!results[[1]]$passed) return(do.call(rbind, results))
  check("keys", nrow(d) > 0 && !anyNA(d[keys]) && !anyDuplicated(d[keys]),
        "Every row has a unique, complete key.")
  whole <- function(v) all(is.na(v) | (is.finite(v) & v >= 0 & v == floor(v)))
  check("counts", all(vapply(d[count_fields], function(v) is.numeric(v) && whole(v), logical(1))),
        "Counts and Census populations are nonnegative whole values or missing.")
  same <- function(a, b) isTRUE(all.equal(a, b, tolerance = 1e-9, check.attributes = FALSE))
  if (all(c("known_ethnicity_stops", "unknown_ethnicity_stops", "total_records") %in% names(d))) {
    check("ethnicity_totals",
          same(d$total_records, d$known_ethnicity_stops + d$unknown_ethnicity_stops) &&
            all(d$group_stops + d$white_stops <= d$known_ethnicity_stops, na.rm = TRUE),
          "Known and unknown ethnicity reconcile; group counts do not exceed known counts.")
  }
  if (identical(dataset, "force_ethnicity_year")) {
    check("missing_returns", all(coverage$status %in% c("supplied", "missing", "unverified")) &&
            all(is.na(coverage$records[coverage$status != "supplied"])) &&
            all(!is.na(coverage$records[coverage$status == "supplied"])),
          "Missing or unverified returns have missing record counts, not zeros.")
    key <- paste(d$force, d$year)
    first <- !duplicated(key)
    cov_year <- as.integer(substr(coverage$month, 1, 4))
    summary <- lapply(which(first), function(i) {
      z <- coverage[coverage$force == d$force[i] & cov_year == d$year[i], , drop = FALSE]
      supplied <- sum(z$status == "supplied")
      unverified <- sum(z$status == "unverified") + (12L - nrow(z))
      c(supplied = supplied, missing = sum(z$status == "missing"), unverified = unverified,
        in_source = nrow(z),
        total = if (supplied) sum(z$records[z$status == "supplied"]) else NA_real_)
    })
    s <- do.call(rbind, summary)
    rows <- d[first, ]
    status <- ifelse(s[, "unverified"] > 0, "unverified", ifelse(s[, "supplied"] == 12,
      "all_months_supplied", ifelse(s[, "supplied"] == 0, "no_months_supplied", "partial_year")))
    check("coverage_summary", same(rows$months_supplied, s[, "supplied"]) &&
            same(rows$months_missing, s[, "missing"]) &&
            same(rows$months_unverified, s[, "unverified"]) &&
            same(rows$months_in_source, s[, "in_source"]) &&
            identical(rows$coverage_status, unname(status)),
          "Annual submission counts and coverage labels match the monthly table.")
    verified <- rows$coverage_status %in% c("all_months_supplied", "partial_year")
    check("monthly_totals", same(rows$total_records[verified], unname(s[verified, "total"])),
          "Annual recorded events reconcile to supplied monthly returns where the year is verified.")
    calculated <- .calculate_group_disparity(d)
    derived <- c("group_rate", "white_rate", "ratio", "ci_lower", "ci_upper",
                 "small_population", "comparable", "eligible")
    check("derived_estimates", all(vapply(derived, function(nm) same(d[[nm]], calculated[[nm]]), logical(1))),
          "Stored rates, approximate intervals and eligibility match the documented calculations.")
    check("rank_encoding", all(is.na(d$rank[!d$eligible])) &&
            all(!is.na(d$rank[d$eligible]) & d$rank[d$eligible] >= 1 &
                d$rank[d$eligible] == floor(d$rank[d$eligible])),
          "Only eligible rows carry positive integer ranks; subsets retain full-release ranks within each year and group.")
  }
  if (identical(dataset, "council_ethnicity_year")) {
    calculated <- .calculate_council_disparity(d)
    derived <- c("group_rate", "white_rate", "ratio", "ci_lower", "ci_upper", "small_population", "comparable")
    check("derived_estimates", all(vapply(derived, function(nm) same(d[[nm]], calculated[[nm]]), logical(1))),
          "Stored rates and approximate intervals match the documented calculations.")
  }
  if (identical(dataset, "hit_rate_ethnicity_year")) {
    check("derived_estimates", same(d$hit_rate, 100 * d$hit_yes / d$hit_total),
          "Stored hit rates are the percentage of searches with a known outcome whose outcome was linked to the object of search.")
  }
  do.call(rbind, results)
}
