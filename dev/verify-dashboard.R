# Run from the package directory after a local installation or pkgload::load_all().
# Rscript --vanilla dev/verify-dashboard.R ../btg_stop_search_v9
args <- commandArgs(trailingOnly = TRUE)
dashboard <- normalizePath(if (length(args)) args[[1]] else "../btg_stop_search_v9")
if (dir.exists("artifacts/library")) .libPaths(c(normalizePath("artifacts/library"), .libPaths()))
library(BlackThriveSS)
library(data.table)

# Evaluate only named calculation definitions. Do not start Shiny, load survey
# datasets, render maps, or mutate the dashboard's cache/data files.
env <- new.env(parent = globalenv())
env$.btg_perf_cache <- new.env(parent = emptyenv())
env$ETH_ORDER <- c("White", "Asian", "Black", "Mixed", "Other")
needed <- c("btg_cache_get", "btg_cache_set", "comparable_force_rates", "force_disparity",
            "ci_bounds", "ci_opacity", "disparity_force_estimates")
loaded <- character()
for (file in c("helpers.R", "helpers_rr.R", "mod_disparity.R")) {
  for (expr in parse(file.path(dashboard, "R", file))) {
    if (is.call(expr) && identical(expr[[1]], as.name("<-")) &&
        is.symbol(expr[[2]]) && as.character(expr[[2]]) %in% needed) {
      eval(expr, envir = env)
      loaded <- c(loaded, as.character(expr[[2]]))
    }
  }
}
stopifnot(setequal(loaded, needed))
env$dat <- list(
  force_yr_eth = as.data.table(readRDS(file.path(dashboard, "data", "agg_force_yr_eth.rds"))),
  pop_eth_pfa = readRDS(file.path(dashboard, "data", "pop_eth_pfa.rds")))
expected <- env$disparity_force_estimates(2025, "std", "Black")
actual <- btg_get_data()
source_hashes <- actual$metadata$source_files
for (i in seq_len(nrow(source_hashes))) {
  source_path <- file.path(dashboard, "data", source_hashes$file[i])
  stopifnot(identical(digest::digest(file = source_path, algo = "sha256"), source_hashes$sha256[i]))
}
stopifnot(all(btg_validate(actual)$passed))
matches <- match(expected$force_label, actual$data$force_label)
stopifnot(!anyNA(matches))
columns <- c(Black = "black_stops", White = "white_stops",
              Black_pop = "black_population", White_pop = "white_population",
              Black_rate = "black_rate", White_rate = "white_rate", ratio = "ratio",
              ci_lo = "ci_lower", ci_hi = "ci_upper", rank = "rank", eligible = "eligible",
              total_stops = "known_ethnicity_stops")
errors <- numeric()
for (dashboard_col in names(columns)) {
  ours <- actual$data[[columns[[dashboard_col]]]][matches]
  theirs <- expected[[dashboard_col]]
  stopifnot(isTRUE(all.equal(ours, theirs, tolerance = 1e-12, check.attributes = FALSE)))
  if (is.numeric(ours)) errors <- c(errors, abs(ours - theirs))
}
for (ranking in c("highest", "lowest", "closest")) {
  f <- expected[expected$eligible, ]
  f <- switch(ranking, highest = f[order(-f$ratio), ],
              lowest = f[order(f$ratio), ], closest = f[order(abs(f$ratio - 1)), ])
  f <- head(f, 10)
  plotted <- btg_figure_data(btg_plot_disparity(actual, ranking = ranking))
  stopifnot(identical(plotted$force_label, f$force_label),
            isTRUE(all.equal(plotted$ratio, f$ratio, tolerance = 1e-12)))
}
# The catalogue's force_ethnicity_year dataset against the dashboard's own
# estimate table for every year and every group it compares with White.
catalogue <- btg_get_data("force_ethnicity_year")
catalogue_hashes <- catalogue$metadata$source_files
for (i in seq_len(nrow(catalogue_hashes))) {
  source_path <- file.path(dashboard, "data", catalogue_hashes$file[i])
  stopifnot(identical(digest::digest(file = source_path, algo = "sha256"), catalogue_hashes$sha256[i]))
}
stopifnot(all(btg_validate(catalogue)$passed))
catalogue_columns <- c(selected = "group_stops", White = "white_stops",
                       selected_pop = "group_population", White_pop = "white_population",
                       selected_rate = "group_rate", white_rate = "white_rate", ratio = "ratio",
                       ci_lo = "ci_lower", ci_hi = "ci_upper", rank = "rank", eligible = "eligible",
                       total_stops = "known_ethnicity_stops")
catalogue_rows <- 0L
catalogue_eligible <- 0L
catalogue_errors <- numeric()
catalogue_cells <- character()
for (yr in sort(unique(catalogue$data$year))) {
  for (group in c("Black", "Asian", "Mixed", "Other")) {
    theirs <- env$disparity_force_estimates(yr, "std", group)
    theirs$selected <- theirs[[group]]
    theirs$selected_pop <- theirs[[paste0(group, "_pop")]]
    ours <- catalogue$data[catalogue$data$year == yr & catalogue$data$group == group, ]
    m <- match(theirs$force_label, ours$force_label)
    stopifnot(!anyNA(m))
    for (dashboard_col in names(catalogue_columns)) {
      a <- ours[[catalogue_columns[[dashboard_col]]]][m]
      b <- theirs[[dashboard_col]]
      # A zero White count divides to Inf in the dashboard and is withheld as NA
      # here; both are non-comparable and ineligible, so they are treated alike.
      if (is.numeric(b)) b[!is.finite(b)] <- NA
      if (is.numeric(a)) a[!is.finite(a)] <- NA
      if (!isTRUE(all.equal(a, b, tolerance = 1e-9, check.attributes = FALSE))) {
        stop("Catalogue parity failed for ", yr, " ", group, " ", dashboard_col)
      }
      if (is.numeric(a)) catalogue_errors <- c(catalogue_errors, abs(a - b))
    }
    catalogue_rows <- catalogue_rows + nrow(theirs)
    catalogue_eligible <- catalogue_eligible + sum(theirs$eligible)
    catalogue_cells <- c(catalogue_cells, paste(yr, group))
  }
}

dir.create("artifacts", showWarnings = FALSE)
result <- list(status = "passed", package_version = as.character(packageVersion("BlackThriveSS")),
               release = actual$metadata$release, source_checksums_match = TRUE,
               dashboard_rows_compared = nrow(expected), fields_compared = names(columns),
               dashboard_eligible_ratios = sum(expected$eligible),
               max_absolute_numerical_difference = max(errors, na.rm = TRUE),
               chart_orders_compared = c("highest", "lowest", "closest"),
               catalogue = list(release = catalogue$metadata$release, dataset = "force_ethnicity_year",
                                source_checksums_match = TRUE,
                                year_group_tables_compared = length(catalogue_cells),
                                dashboard_rows_compared = catalogue_rows,
                                dashboard_eligible_ratios = catalogue_eligible,
                                fields_compared = names(catalogue_columns),
                                max_absolute_numerical_difference = max(catalogue_errors, na.rm = TRUE)),
               note = "Parity with local dashboard calculations; not independent validation of source completeness or statistical assumptions.")
jsonlite::write_json(result, "artifacts/dashboard-parity.json", pretty = TRUE, auto_unbox = TRUE, digits = NA)
cat("Dashboard parity passed: ", nrow(expected), " source rows, ", sum(expected$eligible),
    " eligible ratios, three chart orderings; catalogue: ", length(catalogue_cells),
    " year-group tables, ", catalogue_rows, " rows, ", catalogue_eligible, " eligible ratios.\n", sep = "")
