test_that("the catalogue lists every dataset with a bundled default release", {
  cat <- btg_datasets()
  expect_true(all(c("force_disparity", "force_ethnicity_year", "national_year",
                    "national_month_ethnicity", "council_ethnicity_year",
                    "hit_rate_ethnicity_year", "section60_force_year") %in% cat$dataset))
  expect_true(all(cat$release %in% btg_releases()$release))
  expect_true(all(cat$from <= cat$to))
  rel <- btg_releases()
  expect_equal(nrow(rel), 2)
  expect_true(all(grepl("force_disparity", rel$datasets[1], fixed = TRUE)))
})

test_that("the multi-year force dataset reproduces the original 2025 release exactly", {
  old <- btg_get_data()$data
  new <- btg_get_data("force_ethnicity_year", years = 2025, groups = "Black")$data
  new <- new[match(old$force, new$force), ]
  expect_equal(new$group_stops, old$black_stops)
  expect_equal(new$white_stops, old$white_stops)
  expect_equal(new$group_population, old$black_population)
  expect_equal(new$ratio, old$ratio, tolerance = 1e-10)
  expect_equal(new$ci_lower, old$ci_lower, tolerance = 1e-10)
  expect_identical(new$eligible, old$eligible)
  expect_identical(new$rank, old$rank)
  expect_identical(new$coverage_status, old$coverage_status)
})

test_that("selections filter years, groups, forces and councils and are canonical", {
  y <- btg_get_data("force_ethnicity_year", force = c("norfolk", "metropolitan"),
                    years = c(2024, 2023), groups = c("Other", "Black"))
  expect_equal(sort(unique(y$data$year)), c(2023L, 2024L))
  expect_equal(sort(unique(y$data$group)), c("Black", "Other"))
  expect_equal(y$selection$force, c("metropolitan", "norfolk"))
  expect_equal(y$selection$years, c(2023L, 2024L))
  expect_equal(nrow(y$data), 2 * 2 * 2)
  expect_true(all(y$coverage$force %in% c("metropolitan", "norfolk")))
  expect_true(all(substr(y$coverage$month, 1, 4) %in% c("2023", "2024")))
  expect_true(all(btg_validate(y)$passed))

  c <- btg_get_data("council_ethnicity_year", council = "E09000022", years = 2025)
  expect_equal(unique(c$data$council_label), "Lambeth")
  expect_equal(nrow(c$data), 4)
  expect_null(c$coverage)
  expect_message(btg_coverage(c), "no monthly coverage")
  expect_true(all(btg_validate(c)$passed))

  n <- btg_get_data("national_year")
  expect_equal(n$data$year, sort(n$data$year))
  expect_true(all(btg_validate(n)$passed))
  m <- btg_get_data("national_month_ethnicity", years = 2025, groups = c("Black", "White"))
  expect_true(all(substr(m$data$month, 1, 4) == "2025"))
  expect_true(all(btg_validate(m)$passed))
  expect_true(all(btg_validate(btg_get_data("hit_rate_ethnicity_year"))$passed))
  expect_true(all(btg_validate(btg_get_data("section60_force_year", force = "metropolitan"))$passed))
})

test_that("unsupported selections fail explicitly", {
  expect_error(btg_get_data("force_ethnicity_year", years = 2017), "years must be")
  expect_error(btg_get_data("force_ethnicity_year", groups = "White"), "ethnic groups")
  expect_error(btg_get_data("national_year", force = "metropolitan"), "force-level")
  expect_error(btg_get_data("national_year", groups = "Black"), "group column")
  expect_error(btg_get_data("force_ethnicity_year", council = "E09000022"), "council-level")
  expect_error(btg_get_data("council_ethnicity_year", council = "Lambeth"), "local-authority codes")
  expect_error(btg_get_data(groups = "Asian"), "Black to White")
  expect_error(btg_get_data("force_ethnicity_year", release = "dashboard-2026-07-2025-99a88b69f2d6"),
               "does not contain")
})

test_that("coverage is unverified outside the dashboard's window and never zero", {
  y <- btg_get_data("force_ethnicity_year", groups = "Black")
  early <- y$data[y$data$year == 2020, ]
  expect_true(all(early$coverage_status == "unverified"))
  expect_true(all(early$months_unverified == 12))
  last <- y$data[y$data$year == max(y$data$year), ]
  expect_true(all(last$months_in_source < 12))
  expect_true(all(is.na(y$coverage$records[y$coverage$status != "supplied"])))
  gm <- y$data[y$data$force == "greater-manchester" & y$data$year == 2025, ]
  expect_true(is.na(gm$total_records))
  expect_equal(gm$coverage_status, "no_months_supplied")
})

test_that("the chart draws any year and group and can highlight a force", {
  y <- btg_get_data("force_ethnicity_year")
  p <- btg_plot_disparity(y, year = 2024, group = "Asian", highlight = "metropolitan")
  expect_s3_class(p, "ggplot")
  d <- btg_figure_data(p)
  expect_true(all(d$year == 2024 & d$group == "Asian"))
  expect_equal(p$labels$title, "Asian:White stop-rate ratios, 2024")
  view <- attr(p, "btg_view")
  expect_equal(view$schema_version, 2L)
  expect_equal(view$highlight, "metropolitan")
  expect_equal(btg_plot_disparity(y)$labels$title, "Black:White stop-rate ratios, 2025")
  expect_error(btg_plot_disparity(y, year = 2017), "year must be")
  expect_error(btg_plot_disparity(y, highlight = "nowhere"), "highlight")
  expect_error(btg_plot_disparity(btg_get_data("national_year")), "force-level")

  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  btg_save_view(p, path)
  replay <- btg_from_view(path)
  expect_identical(btg_figure_data(replay), d)
  expect_identical(attr(replay, "btg_view"), view)
  plain <- btg_plot_disparity(y, year = 2019)
  btg_save_view(plain, path, overwrite = TRUE)
  expect_identical(btg_figure_data(btg_from_view(path)), btg_figure_data(plain))
})
