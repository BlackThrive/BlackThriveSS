`%||%` <- function(x, y) if (is.null(x)) y else x

# Internal calculations accept aggregate event counts, never person outcomes.
# Shared arithmetic: rates per 1,000 residents, the rate ratio and a Poisson
# log-ratio interval, written with generic column names.
.rates_and_ratio <- function(d, comparable) {
  valid <- comparable & is.finite(d$group_stops) & is.finite(d$white_stops)
  d$group_rate <- d$white_rate <- d$ratio <- NA_real_
  d$group_rate[valid] <- 1000 * d$group_stops[valid] / d$group_population[valid]
  d$white_rate[valid] <- 1000 * d$white_stops[valid] / d$white_population[valid]
  positive_reference <- valid & d$white_stops > 0
  d$ratio[positive_reference] <- d$group_rate[positive_reference] / d$white_rate[positive_reference]
  d$ci_lower <- d$ci_upper <- NA_real_
  ci_ok <- positive_reference & d$group_stops > 0
  se <- sqrt(1 / d$group_stops[ci_ok] + 1 / d$white_stops[ci_ok])
  z <- stats::qnorm(0.975)
  d$ci_lower[ci_ok] <- exp(log(d$ratio[ci_ok]) - z * se)
  d$ci_upper[ci_ok] <- exp(log(d$ratio[ci_ok]) + z * se)
  d
}

# Force-level comparison of any group with White, by year: the dashboard's
# exclusions, display rule and ranks within each year and group.
.calculate_group_disparity <- function(d) {
  d$small_population <- !is.na(d$white_population) & d$white_population < 50000
  d$comparable <- !d$small_population &
    !d$force %in% c("btp", "city-of-london") &
    is.finite(d$group_population) & d$group_population > 0 &
    is.finite(d$white_population) & d$white_population > 0
  d <- .rates_and_ratio(d, d$comparable)
  d$eligible <- is.finite(d$ratio) & d$ratio > 0 &
    !is.na(d$known_ethnicity_stops) & d$known_ethnicity_stops >= 200 & d$comparable
  d$rank <- NA_integer_
  for (key in unique(paste(d$year, d$group))) {
    rows <- which(paste(d$year, d$group) == key & d$eligible)
    d$rank[rows] <- as.integer(rank(-d$ratio[rows], ties.method = "min"))
  }
  d
}

# Council-level comparison: counts depend on published coordinates, so no
# display rule or rank is applied; only the population exclusions.
.calculate_council_disparity <- function(d) {
  d$small_population <- !is.na(d$white_population) & d$white_population < 50000
  comparable <- is.finite(d$group_population) & d$group_population > 0 &
    is.finite(d$white_population) & d$white_population > 0
  d$comparable <- comparable
  .rates_and_ratio(d, comparable)
}

.calculate_disparity <- function(d) {
  d$small_population <- !is.na(d$white_population) & d$white_population < 50000
  d$comparable <- !d$small_population &
    !d$force %in% c("btp", "city-of-london") &
    is.finite(d$black_population) & d$black_population > 0 &
    is.finite(d$white_population) & d$white_population > 0
  valid <- d$comparable & is.finite(d$black_stops) &
    is.finite(d$white_stops)
  d$black_rate <- d$white_rate <- d$ratio <- NA_real_
  d$black_rate[valid] <- 1000 * d$black_stops[valid] / d$black_population[valid]
  d$white_rate[valid] <- 1000 * d$white_stops[valid] / d$white_population[valid]
  positive_reference <- valid & d$white_stops > 0
  d$ratio[positive_reference] <-
    d$black_rate[positive_reference] / d$white_rate[positive_reference]
  d$ci_lower <- d$ci_upper <- NA_real_
  ci_ok <- positive_reference & d$black_stops > 0
  se <- sqrt(1 / d$black_stops[ci_ok] + 1 / d$white_stops[ci_ok])
  z <- stats::qnorm(0.975)
  d$ci_lower[ci_ok] <- exp(log(d$ratio[ci_ok]) - z * se)
  d$ci_upper[ci_ok] <- exp(log(d$ratio[ci_ok]) + z * se)
  # Reproduce the dashboard's display rule, which is not a coverage criterion.
  d$eligible <- is.finite(d$ratio) & d$ratio > 0 &
    !is.na(d$known_ethnicity_stops) & d$known_ethnicity_stops >= 200 & d$comparable
  d$rank <- NA_integer_
  d$rank[d$eligible] <- as.integer(rank(-d$ratio[d$eligible], ties.method = "min"))
  d
}
