# Run from the BlackThriveSS folder:
#   Rscript --vanilla data-raw/build-catalogue.R ../btg_stop_search_v9
# Creates one immutable, content-identified release holding every catalogue
# dataset except the original 2025 force_disparity release, which keeps its own
# directory so that saved views replay unchanged. Never updates dashboard data.
args <- commandArgs(trailingOnly = TRUE)
dashboard <- normalizePath(if (length(args)) args[[1]] else "../btg_stop_search_v9",
                           mustWork = TRUE)
stopifnot(file.exists("DESCRIPTION"), requireNamespace("digest", quietly = TRUE),
          requireNamespace("jsonlite", quietly = TRUE))
source("R/estimates.R")

files <- c("agg_force_yr_eth.rds", "pop_eth_pfa.rds", "police_refresh.rds", "manifest.rds",
           "agg_national_yr.rds", "v2_mon_national_eth.rds", "agg_lad_yr_eth.rds",
           "v2_pop_la.rds", "agg_hitrate_eth_yr.rds", "agg_s60.rds")
paths <- file.path(dashboard, "data", files)
stopifnot(all(file.exists(paths)))
hashes <- vapply(paths, function(p) digest::digest(file = p, algo = "sha256"), character(1))
names(hashes) <- files
read <- function(name) as.data.frame(readRDS(file.path(dashboard, "data", name)))
groups <- c("Asian", "Black", "Mixed", "Other")

annual <- read("agg_force_yr_eth.rds")
pop <- read("pop_eth_pfa.rds")
refresh <- readRDS(file.path(dashboard, "data", "police_refresh.rds"))
source_manifest <- readRDS(file.path(dashboard, "data", "manifest.rds"))
years <- sort(unique(annual$year))
source_month <- source_manifest$police_release$latest_month

# Monthly coverage: the dashboard verifies submissions from 2023-08; months
# outside its window are unverified, never assumed supplied.
cov <- as.data.frame(refresh$force_month)
cov$status <- ifelse(is.na(cov$supplied), "unverified",
                     ifelse(cov$supplied, "supplied", "missing"))
cov$records[cov$status != "supplied"] <- NA_integer_
cov <- cov[order(cov$force, cov$month), c("force", "force_label", "month", "status", "records")]
stopifnot(!anyDuplicated(cov[c("force", "month")]), !any(cov$records > 0 & cov$status != "supplied", na.rm = TRUE))
forces <- unique(cov[c("force", "force_label")])
forces <- forces[order(forces$force), ]
stopifnot(nrow(forces) == 44L)
lookup <- unique(annual[c("force", "PFA_CD")])
stopifnot(!anyDuplicated(lookup$force), all(forces$force %in% lookup$force))
forces$pfa_code <- lookup$PFA_CD[match(forces$force, lookup$force)]
all_months <- sprintf("%d-%02d", rep(years, each = 12L), 1:12)
all_months <- all_months[all_months <= source_month]
full_cov <- expand.grid(force = forces$force, month = all_months, stringsAsFactors = FALSE)
full_cov <- merge(full_cov, cov[c("force", "month", "status", "records")], all.x = TRUE)
full_cov$status[is.na(full_cov$status)] <- "unverified"
full_cov$force_label <- forces$force_label[match(full_cov$force, forces$force)]
full_cov <- full_cov[order(full_cov$force, full_cov$month),
                     c("force", "force_label", "month", "status", "records")]
rownames(full_cov) <- NULL

coverage_summary <- function(force, year) {
  c <- full_cov[full_cov$force == force & substr(full_cov$month, 1, 4) == as.character(year), ]
  months_in_year <- sum(startsWith(all_months, as.character(year)))
  supplied <- sum(c$status == "supplied")
  missing <- sum(c$status == "missing")
  unverified <- sum(c$status == "unverified") + (12L - months_in_year)
  status <- if (unverified > 0) "unverified" else if (supplied == 12) "all_months_supplied" else
    if (supplied == 0) "no_months_supplied" else "partial_year"
  list(months_supplied = supplied, months_missing = missing, months_unverified = unverified,
       months_in_source = months_in_year, coverage_status = status,
       supplied_records = if (supplied) sum(c$records[c$status == "supplied"]) else NA_real_)
}

# 1. force_ethnicity_year ---------------------------------------------------------------
rows <- list()
for (i in seq_len(nrow(forces))) {
  d <- forces[i, ]
  p <- pop[!is.na(pop$PFA_CD) & !is.na(d$pfa_code) & pop$PFA_CD == d$pfa_code, ]
  population <- function(group) {
    value <- p$population[p$eth_5 == group]
    if (length(value) != 1L) NA_real_ else value
  }
  for (yr in years) {
    a <- annual[annual$force == d$force & annual$year == yr, ]
    cs <- coverage_summary(d$force, yr)
    count <- function(group) if (!nrow(a)) NA_real_ else sum(a$stops[!is.na(a$eth_5) & a$eth_5 == group])
    known <- if (nrow(a)) sum(a$stops[!is.na(a$eth_5)]) else NA_real_
    unknown <- if (nrow(a)) sum(a$stops[is.na(a$eth_5)]) else NA_real_
    total <- if (nrow(a)) sum(a$stops) else NA_real_
    if (nrow(a) && cs$coverage_status %in% c("all_months_supplied", "partial_year")) {
      stopifnot(total == cs$supplied_records)
    }
    for (g in groups) {
      rows[[length(rows) + 1L]] <- data.frame(
        force = d$force, force_label = d$force_label, pfa_code = d$pfa_code, year = yr, group = g,
        group_stops = count(g), white_stops = count("White"),
        known_ethnicity_stops = known, unknown_ethnicity_stops = unknown, total_records = total,
        group_population = population(g), white_population = population("White"),
        months_supplied = cs$months_supplied, months_missing = cs$months_missing,
        months_unverified = cs$months_unverified, months_in_source = cs$months_in_source,
        coverage_status = cs$coverage_status, stringsAsFactors = FALSE)
    }
  }
}
fey <- do.call(rbind, rows)
fey <- .calculate_group_disparity(fey)
fey <- fey[order(fey$year, fey$group, fey$force), ]
rownames(fey) <- NULL
stopifnot(nrow(fey) == 44L * length(years) * length(groups), !anyDuplicated(fey[c("force", "year", "group")]))

# Parity with the original 2025 force_disparity release.
old <- utils::read.csv("inst/extdata/dashboard-2026-07-2025-99a88b69f2d6/force-disparity.csv",
                       stringsAsFactors = FALSE)
new25 <- fey[fey$year == 2025L & fey$group == "Black", ]
new25 <- new25[match(old$force, new25$force), ]
for (pair in list(c("black_stops", "group_stops"), c("white_stops", "white_stops"),
                  c("black_population", "group_population"), c("ratio", "ratio"),
                  c("ci_lower", "ci_lower"), c("rank", "rank"), c("eligible", "eligible"),
                  c("coverage_status", "coverage_status"))) {
  stopifnot(isTRUE(all.equal(old[[pair[1]]], new25[[pair[2]]], tolerance = 1e-12)))
}

# 2. national_year ------------------------------------------------------------------
national <- read("agg_national_yr.rds")
national <- national[order(national$year), ]
rownames(national) <- NULL

# 3. national_month_ethnicity -------------------------------------------------------
monthly <- read("v2_mon_national_eth.rds")
names(monthly)[names(monthly) == "mon"] <- "month"
names(monthly)[names(monthly) == "eth_5"] <- "group"
monthly$month <- substr(as.character(monthly$month), 1, 7)
monthly$group[is.na(monthly$group)] <- "Unknown"
monthly <- monthly[order(monthly$month, monthly$group), c("month", "group", "stops")]
rownames(monthly) <- NULL

# 4. council_ethnicity_year ---------------------------------------------------------
lad <- read("agg_lad_yr_eth.rds")
lad_pop <- read("v2_pop_la.rds")
lad_pop <- lad_pop[lad_pop$LAD_CD != "K04000001", ]
council <- list()
keys <- unique(lad[c("LAD_CD", "LAD_NM", "year")])
for (k in seq_len(nrow(keys))) {
  key <- keys[k, ]
  a <- lad[lad$LAD_CD == key$LAD_CD & lad$year == key$year, ]
  pp <- lad_pop[lad_pop$LAD_CD == key$LAD_CD, ]
  population <- function(group) if (nrow(pp) != 1L) NA_real_ else as.numeric(pp[[group]])
  count <- function(group) sum(a$stops[!is.na(a$eth_5) & a$eth_5 == group])
  known <- sum(a$stops[!is.na(a$eth_5)])
  for (g in groups) {
    council[[length(council) + 1L]] <- data.frame(
      council = key$LAD_CD, council_label = key$LAD_NM, year = key$year, group = g,
      group_stops = count(g), white_stops = count("White"), known_ethnicity_stops = known,
      unknown_ethnicity_stops = sum(a$stops[is.na(a$eth_5)]), total_records = sum(a$stops),
      group_population = population(g), white_population = population("White"),
      stringsAsFactors = FALSE)
  }
}
council <- do.call(rbind, council)
council <- .calculate_council_disparity(council)
council <- council[order(council$year, council$group, council$council), ]
rownames(council) <- NULL
stopifnot(!anyDuplicated(council[c("council", "year", "group")]))

# 5. hit_rate_ethnicity_year --------------------------------------------------------
hit <- read("agg_hitrate_eth_yr.rds")
names(hit)[names(hit) == "eth_5"] <- "group"
hit$group[is.na(hit$group)] <- "Unknown"
hit <- hit[order(hit$year, hit$group), c("year", "group", "hit_yes", "hit_total", "hit_rate")]
rownames(hit) <- NULL

# 6. section60_force_year -----------------------------------------------------------
s60 <- read("agg_s60.rds")
names(s60)[names(s60) == "eth_5"] <- "group"
s60$group[is.na(s60$group)] <- "Unknown"
s60$force <- forces$force[match(s60$PFA_CD, forces$pfa_code)]
s60$force[is.na(s60$force)] <- forces$force[match(s60$force_label, forces$force_label)]
stopifnot(!anyNA(s60$force))
s60 <- s60[order(s60$year, s60$force, s60$group),
           c("force", "force_label", "year", "group", "s60_stops")]
rownames(s60) <- NULL

# Write the release ---------------------------------------------------------------
source_fingerprint <- digest::digest(paste(files, hashes, collapse = "\n"),
                                     algo = "sha256", serialize = FALSE)
release <- paste0("dashboard-", source_month, "-catalogue-", substr(source_fingerprint, 1, 12))
out <- file.path("inst", "extdata", release)
if (dir.exists(out)) stop("Release already exists: ", release,
                         ". Immutable releases are not overwritten.")
dir.create(out, recursive = TRUE)
options(digits = 17)
# Derived doubles are written to 12 significant figures, which reproduces the
# documented calculations to within 1e-12 and keeps the bundled files small.
round_derived <- function(df) {
  for (nm in intersect(names(df), c("group_rate", "white_rate", "ratio", "ci_lower", "ci_upper",
                                    "arrest_rate", "nfa_rate", "hit_rate", "strip_rate",
                                    "eth_recorded_rate"))) {
    df[[nm]] <- signif(df[[nm]], 12)
  }
  df
}
write_payload <- function(df, name) {
  df <- round_derived(df)
  path <- file.path(out, name)
  if (grepl("[.]gz$", name)) {
    con <- gzfile(path, "w")
    utils::write.csv(df, con, row.names = FALSE, na = "NA")
    close(con)  # flush before hashing
  } else {
    utils::write.csv(df, path, row.names = FALSE, na = "NA")
  }
  list(file = name, sha256 = digest::digest(file = path, algo = "sha256"), rows = nrow(df))
}
datasets <- list(
  force_ethnicity_year = c(write_payload(fey, "force-ethnicity-year.csv.gz"), list(
    title = "Group to White stop-rate comparison by police force and year",
    level = "force", years = range(years), groups = groups, coverage = "coverage",
    description = "Recorded events, Census 2021 residents, rates per 1,000, rate ratios against White, Poisson intervals, the dashboard display rule and ranks within each year and group.")),
  national_year = c(write_payload(national, "national-year.csv"), list(
    title = "National totals and outcome rates by year",
    level = "national", years = range(national$year), groups = character(),
    description = "England and Wales totals of recorded stops, arrests, no further action, Section 60, under-18s, strip searches and outcome-linked searches, with the derived rates the dashboard shows.")),
  national_month_ethnicity = c(write_payload(monthly, "national-month-ethnicity.csv"), list(
    title = "National monthly stops by officer-defined ethnicity",
    level = "national", years = range(as.integer(substr(monthly$month, 1, 4))),
    groups = c("Asian", "Black", "Mixed", "Other", "White", "Unknown"),
    description = "Monthly recorded stops across all reporting forces, by officer-defined ethnic group, with unknown ethnicity kept as its own row.")),
  council_ethnicity_year = c(write_payload(council, "council-ethnicity-year.csv.gz"), list(
    title = "Group to White stop-rate comparison by council and year",
    level = "council", years = range(council$year), groups = groups,
    description = "Local-authority counts located by stop coordinates, Census 2021 residents, rates per 1,000 and rate ratios against White. Coordinates are missing for some forces, so council counts undercount; no display rule or rank is applied.")),
  hit_rate_ethnicity_year = c(write_payload(hit, "hit-rate-ethnicity-year.csv"), list(
    title = "National outcome-linked search rate by ethnicity and year",
    level = "national", years = range(hit$year),
    groups = c("Asian", "Black", "Mixed", "Other", "White", "Unknown"),
    description = "Percentage of searches with a known outcome whose outcome was linked to the object of search, by officer-defined ethnic group. Forces that machine-fill or omit the field are voided in the dashboard's preparation.")),
  section60_force_year = c(write_payload(s60, "section60-force-year.csv"), list(
    title = "Section 60 searches by police force, year and ethnicity",
    level = "force", years = range(s60$year),
    groups = c("Asian", "Black", "Mixed", "Other", "White", "Unknown"), coverage = "coverage",
    description = "Searches recorded under Section 60 of the Criminal Justice and Public Order Act 1994, which need no individual suspicion."))
)
coverage_payload <- write_payload(full_cov, "coverage.csv.gz")
metadata <- list(
  schema_version = 2L, release = release, dashboard = "btg_stop_search_v9",
  dashboard_built_at = format(source_manifest$built_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  source = source_manifest$police_release,
  source_files = lapply(seq_along(files), function(i) list(file = files[i], sha256 = hashes[[i]])),
  files = list(coverage = coverage_payload),
  datasets = datasets,
  coverage_window = list(from = min(cov$month), to = max(cov$month),
    note = "The dashboard verifies monthly submissions inside this window; months outside it are unverified, never assumed supplied."),
  ethnicity = list(field = "Officer-defined ethnicity", groups = groups, reference = "White",
                   missing = "Unknown or unrecognised values excluded from ratios; counts retained separately"),
  population = list(year = 2021L, type = "Census residents",
                    source = "ONS Census 2021 TS021 via Ethnicity Facts and Figures",
                    construction = "Dashboard aggregates local-authority populations to police force areas using its LAD23/PFA23 lookup and documented historical-code assignments; council populations are the local authority's own Census residents",
                    url = "https://www.nomisweb.co.uk/sources/census_2021"),
  calculation = list(rates = "1000 * recorded group events / group resident population",
                     ratio = "group rate / White rate",
                     interval = "95% Poisson log approximation; sqrt(1/group events + 1/White events)",
                     exclusions = "Force resident rates withheld for BTP, City of London, missing/zero population or White resident population below 50000",
                     display = "Force display rule: finite positive ratio and at least 200 known-ethnicity events; ranks within year and group; no coverage exclusion"),
  coverage_note = "Supplied months are reported submissions, not proof of complete event recording. Missing months are not zero stops; partial-year counts are not annualised.",
  limitations = c(
    "This snapshot reproduces the local dashboard release; it is not asserted to be the latest live website or source release.",
    "Recorded events are not unique people. The source aggregate does not separate vehicle-only searches; unknown ethnicity is not necessarily item non-response.",
    "Officer-defined ethnicity is compared with Census self-reported ethnic categories; these classifications are not identical.",
    "Fixed 2021 resident populations are not measured exposure in any year. Visitors and repeat stops are not accounted for.",
    "Intervals condition on recorded counts and denominators and do not quantify reporting, classification or exposure uncertainty.",
    "Council counts depend on stop coordinates, which some forces do not publish; they undercount and are not comparable across forces.",
    "The final source year is incomplete; its counts cover only the months published by the source month.",
    "No adjustment, imputation, population forecast or causal interpretation is provided."),
  licence = list(data = "Open Government Licence v3.0", url = "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/",
                 attribution = "Contains public sector information licensed under the Open Government Licence v3.0. Police.uk; Office for National Statistics, Census 2021."))
jsonlite::write_json(metadata, file.path(out, "manifest.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

catalogue_path <- file.path("inst", "extdata", "catalogue.json")
catalogue <- jsonlite::read_json(catalogue_path, simplifyVector = TRUE)
releases <- unique(c(catalogue$releases, release))
defaults <- as.list(catalogue$default_releases %||% list(force_disparity = catalogue$default_release))
for (nm in names(datasets)) defaults[[nm]] <- release
jsonlite::write_json(list(schema_version = 2L, default_release = catalogue$default_release,
                          default_releases = defaults, releases = releases),
                     catalogue_path, auto_unbox = TRUE, pretty = TRUE)
cat("Created ", release, " with ", length(datasets), " datasets and ", nrow(full_cov), " force-months.\n", sep = "")
