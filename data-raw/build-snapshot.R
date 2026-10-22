# Run from the BlackThriveSS folder:
# Rscript --vanilla data-raw/build-snapshot.R ../btg_stop_search_v9
# Creates an immutable, content-identified release; never updates dashboard data.
args <- commandArgs(trailingOnly = TRUE)
dashboard <- normalizePath(if (length(args)) args[[1]] else "../btg_stop_search_v9",
                           mustWork = TRUE)
stopifnot(file.exists("DESCRIPTION"), requireNamespace("digest", quietly = TRUE),
          requireNamespace("jsonlite", quietly = TRUE))
source("R/estimates.R")
files <- c("agg_force_yr_eth.rds", "pop_eth_pfa.rds", "police_refresh.rds", "manifest.rds")
paths <- file.path(dashboard, "data", files)
stopifnot(all(file.exists(paths)))
hashes <- vapply(paths, function(p) digest::digest(file = p, algo = "sha256"), character(1))
names(hashes) <- files
read <- function(name) readRDS(file.path(dashboard, "data", name))
annual <- as.data.frame(read("agg_force_yr_eth.rds"))
pop <- as.data.frame(read("pop_eth_pfa.rds"))
refresh <- read("police_refresh.rds")
source_manifest <- read("manifest.rds")
year <- 2025L
cov <- as.data.frame(refresh$force_month)
cov <- cov[substr(cov$month, 1, 4) == as.character(year), ]
stopifnot(nrow(cov) == 44L * 12L, !anyDuplicated(cov[c("force", "month")]))
stopifnot(!any(cov$records > 0 & !cov$supplied, na.rm = TRUE))
cov$status <- ifelse(is.na(cov$supplied), "unverified",
                     ifelse(cov$supplied, "supplied", "missing"))
cov$records[cov$status != "supplied"] <- NA_integer_
cov <- cov[order(cov$force, cov$month), c("force", "force_label", "month", "status", "records")]
rownames(cov) <- NULL
forces <- unique(cov[c("force", "force_label")])
lookup <- unique(annual[c("force", "PFA_CD")])
stopifnot(!anyDuplicated(lookup$force))
forces$pfa_code <- lookup$PFA_CD[match(forces$force, lookup$force)]
annual <- annual[annual$year == year, ]
rows <- lapply(seq_len(nrow(forces)), function(i) {
  d <- forces[i, ]
  a <- annual[annual$force == d$force, ]
  c <- cov[cov$force == d$force, ]
  p <- pop[!is.na(pop$PFA_CD) & !is.na(d$pfa_code) & pop$PFA_CD == d$pfa_code, ]
  count <- function(group) {
    if (!nrow(a)) return(NA_real_)
    sum(a$stops[!is.na(a$eth_5) & a$eth_5 == group])
  }
  population <- function(group) {
    value <- p$population[p$eth_5 == group]
    if (length(value) != 1L) NA_real_ else value
  }
  d$year <- year
  d$black_stops <- count("Black")
  d$white_stops <- count("White")
  d$known_ethnicity_stops <- if (nrow(a)) sum(a$stops[!is.na(a$eth_5)]) else NA_real_
  d$unknown_ethnicity_stops <- if (nrow(a)) sum(a$stops[is.na(a$eth_5)]) else NA_real_
  d$total_records <- if (nrow(a)) sum(a$stops) else NA_real_
  if (nrow(a)) stopifnot(d$total_records == sum(c$records, na.rm = TRUE))
  d$black_population <- population("Black")
  d$white_population <- population("White")
  d$months_supplied <- sum(c$status == "supplied")
  d$months_missing <- sum(c$status == "missing")
  d$months_unverified <- sum(c$status == "unverified")
  d$coverage_status <- if (d$months_unverified > 0) "unverified" else
    if (d$months_supplied == 12) "all_months_supplied" else
      if (d$months_supplied == 0) "no_months_supplied" else "partial_year"
  d
})
data <- .calculate_disparity(do.call(rbind, rows))
rownames(data) <- NULL
stopifnot(nrow(data) == 44L, !anyDuplicated(data$force))
source_fingerprint <- digest::digest(paste(files, hashes, collapse = "\n"),
                                     algo = "sha256", serialize = FALSE)
release <- paste0("dashboard-", source_manifest$police_release$latest_month,
                   "-2025-", substr(source_fingerprint, 1, 12))
out <- file.path("inst", "extdata", release)
if (dir.exists(out)) stop("Release already exists: ", release,
                         ". Immutable releases are not overwritten.")
dir.create(out, recursive = TRUE)
options(digits = 17)
utils::write.csv(data, file.path(out, "force-disparity.csv"), row.names = FALSE, na = "NA")
utils::write.csv(cov, file.path(out, "coverage.csv"), row.names = FALSE, na = "NA")
payload <- function(name) list(file = name, sha256 =
  digest::digest(file = file.path(out, name), algo = "sha256"))
metadata <- list(
  schema_version = 1L, release = release, dataset = "force_disparity", year = year,
  dashboard = "btg_stop_search_v9", dashboard_built_at =
    format(source_manifest$built_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  source = source_manifest$police_release,
  source_files = lapply(seq_along(files), function(i) list(file = files[i], sha256 = hashes[i])),
  files = list(data = payload("force-disparity.csv"), coverage = payload("coverage.csv")),
  ethnicity = list(field = "Officer-defined ethnicity", comparison = "Black", reference = "White",
                   missing = "Unknown or unrecognised values excluded from ratio; counts retained separately"),
  population = list(year = 2021L, type = "Census residents",
                    source = "ONS Census 2021 TS021 via Ethnicity Facts and Figures",
                    construction = "Dashboard aggregates local-authority populations to police force areas using its LAD23/PFA23 lookup and documented historical-code assignments",
                    url = "https://www.nomisweb.co.uk/sources/census_2021"),
  calculation = list(rates = "1000 * recorded group events / group resident population",
                     ratio = "Black rate / White rate", interval = "95% Poisson log approximation; sqrt(1/Black events + 1/White events)",
                     exclusions = "Resident rates withheld for BTP, City of London, missing/zero population or White resident population below 50000",
                     display = "Finite positive ratio and at least 200 known-ethnicity events; no coverage exclusion"),
  coverage_note = "Supplied months are reported submissions, not proof of complete event recording. Missing months are not zero stops; partial-year counts are not annualised.",
  limitations = c(
    "This snapshot reproduces the local dashboard release; it is not asserted to be the latest live website or source release.",
    "Recorded events are not unique people. The source aggregate does not separate vehicle-only searches; unknown ethnicity is not necessarily item non-response.",
    "Officer-defined ethnicity is compared with Census self-reported ethnic categories; these classifications are not identical.",
    "Fixed 2021 resident populations are not measured 2025 exposure. Visitors and repeat stops are not accounted for.",
    "Intervals condition on recorded counts and denominators and do not quantify reporting, classification or exposure uncertainty.",
    "No adjustment, imputation, population forecast or causal interpretation is provided."),
  licence = list(data = "Open Government Licence v3.0", url = "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/",
                  attribution = "Contains public sector information licensed under the Open Government Licence v3.0. Police.uk; Office for National Statistics, Census 2021."))
jsonlite::write_json(metadata, file.path(out, "manifest.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
catalogue_path <- file.path("inst", "extdata", "catalogue.json")
old <- if (file.exists(catalogue_path)) jsonlite::read_json(catalogue_path, simplifyVector = TRUE)$releases else character()
jsonlite::write_json(list(default_release = release, releases = unique(c(old, release))),
                     catalogue_path, auto_unbox = TRUE, pretty = TRUE)
cat("Created ", release, ": ", nrow(data), " forces; ", sum(data$eligible),
    " dashboard-eligible ratios; ", nrow(cov), " force-months.\n", sep = "")
