test_that("availability comparison finds late additions, withdrawals and newer months", {
  x <- btg_get_data("force_ethnicity_year")
  coverage <- x$coverage
  window <- coverage[coverage$status != "unverified", ]
  # a live feed built from the snapshot itself, with planted differences
  live <- window[window$status == "supplied", c("month", "force")]
  late <- window[window$status == "missing", ][1, ]
  live <- rbind(live, data.frame(month = late$month, force = late$force))
  gone <- window[window$status == "supplied" & window$month == "2025-06", ][1, ]
  live <- live[!(live$month == gone$month & live$force == gone$force), ]
  live <- rbind(live, data.frame(month = c("2026-08", "2026-08"), force = c("kent", "dorset")))
  cmp <- BlackThriveSS:::.compare_availability(live, coverage, x$metadata$source$latest_month)
  expect_equal(cmp$latest_month, "2026-08")
  expect_equal(cmp$newer_months, data.frame(month = "2026-08", forces_live = 2L, stringsAsFactors = FALSE))
  expect_equal(sum(cmp$months$late_additions), 1)
  expect_equal(sum(cmp$months$withdrawals), 1)
  expect_equal(nrow(cmp$changes), 2)
  expect_true(any(cmp$changes$force == late$force & cmp$changes$month == late$month & cmp$changes$live_available))
  expect_true(any(cmp$changes$force == gone$force & cmp$changes$month == gone$month & !cmp$changes$live_available))
  expect_equal(cmp$months$forces_supplied[cmp$months$month == "2025-06"],
               sum(window$status == "supplied" & window$month == "2025-06"))
  # an identical feed reports no change
  same <- BlackThriveSS:::.compare_availability(window[window$status == "supplied", c("month", "force")],
                                                coverage, x$metadata$source$latest_month)
  expect_equal(nrow(same$changes), 0)
  expect_equal(nrow(same$newer_months), 0)
  expect_equal(same$latest_month, x$metadata$source$latest_month)
  status <- structure(c(list(checked_at = "2026-10-22T00:00:00Z", release = x$metadata$release,
                             snapshot_month = x$metadata$source$latest_month, url = "test"), cmp),
                      class = "btg_source_status")
  expect_output(print(status), "1 newer month")
  expect_output(print(status), "1 late addition")
})

test_that("an unreadable feed fails quietly", {
  expect_message(result <- btg_source_status(url = "https://localhost:1/none", timeout = 1), "not checked")
  expect_null(result)
  expect_error(btg_source_status(timeout = 0), "timeout")
  bad <- tempfile(fileext = ".json")
  writeLines('{"not": "a feed"}', bad)
  expect_message(BlackThriveSS:::.read_availability(paste0("file://", bad), 1), "expected form")
  unlink(bad)
})

test_that("the live feed is consistent with the snapshot when network tests are enabled", {
  skip_if_not(identical(Sys.getenv("BLACKTHRIVESS_NETWORK_TESTS"), "true"), "network tests are off")
  status <- btg_source_status(timeout = 20)
  skip_if(is.null(status), "feed unavailable")
  expect_s3_class(status, "btg_source_status")
  expect_true(status$latest_month >= status$snapshot_month)
  expect_true(all(c("month", "forces_live", "forces_supplied", "late_additions", "withdrawals") %in% names(status$months)))
})

test_that("the robustness summary counts what each year and group rests on", {
  y <- btg_get_data("force_ethnicity_year", years = 2024:2025, groups = c("Black", "Asian"))
  s <- btg_robustness_summary(y, draws = 200)
  expect_equal(nrow(s), 4)
  expect_identical(s$year, c(2024L, 2024L, 2025L, 2025L))
  expect_true(all(s$above + s$below + s$sensitive == s$eligible))
  expect_true(all(s$eligible <= s$forces & s$forces <= 44))
  expect_true(all(s$settled_top <= 10))
  expect_true(all(s$median_rank_interval >= 0))
  expect_equal(unique(s$months_in_source), 12L)
  black25 <- s[s$year == 2025 & s$group == "Black", ]
  expect_equal(black25$eligible, 40)
  expect_equal(black25$above, 40)
  expect_equal(black25$full_year_returns, sum(btg_get_data(years = 2025)$data$coverage_status == "all_months_supplied"))
  expect_equal(attr(s, "draws"), 200L)
  expect_error(btg_robustness_summary(y, certain = 2), "probability")
  expect_error(btg_robustness_summary(btg_get_data("council_ethnicity_year")), "force-level")
  partial <- btg_robustness_summary(btg_get_data("force_ethnicity_year", years = 2026, groups = "Black"), draws = 200)
  expect_equal(partial$months_in_source, 7L)
})
