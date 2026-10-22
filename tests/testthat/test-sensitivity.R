test_that("allocation bounds match an independent hand calculation", {
  s <- btg_sensitivity(btg_get_data())
  met <- s[s$force == "metropolitan", ]
  # Independently transcribed Metropolitan Police counts and Census populations.
  black <- 56116; white <- 48798; unknown <- 8826
  black_pop <- 1188137; white_pop <- 4725217
  expect_equal(met$ratio, (black / black_pop) / (white / white_pop))
  expect_equal(met$ratio_max, ((black + unknown) / black_pop) / (white / white_pop))
  expect_equal(met$ratio_min, (black / black_pop) / ((white + unknown) / white_pop))
  expect_equal(met$unknown_share, unknown / met$total_records)
  expect_equal(met$parity_direction, "above")
  expect_equal(attr(s, "dataset"), "force_disparity")
  expect_match(attr(s, "release"), "^dashboard-")
})

test_that("bounds contain the recorded ratio and keep missing returns missing", {
  y <- btg_get_data("force_ethnicity_year")
  s <- btg_sensitivity(y)
  expect_equal(nrow(s), nrow(y$data))
  finite <- is.finite(s$ratio)
  # stored ratios are rounded to 12 significant figures; the bounds are exact
  expect_true(all(s$ratio_min[finite] <= s$ratio[finite] * (1 + 1e-9)))
  expect_true(all(s$ratio_max[finite] >= s$ratio[finite] * (1 - 1e-9)))
  expect_true(all(is.na(s$ratio_min[!finite]) & is.na(s$ratio_max[!finite])))
  expect_true(all(s$unknown_share >= 0 & s$unknown_share <= 1, na.rm = TRUE))
  # proportional allocation leaves the ratio unchanged: the bounds bracket it only
  # because the extreme allocations move the two counts in opposite directions
  share <- s$unknown_ethnicity_stops / (s$group_stops + s$white_stops)
  same <- (s$group_stops * (1 + share) / s$white_stops / (1 + share))
  expect_equal(same[finite], (s$group_stops / s$white_stops)[finite])
  gm <- s[s$force == "greater-manchester" & s$year == 2025, ]
  expect_true(all(is.na(gm$ratio_min)) && all(is.na(gm$parity_direction)))
  above <- s$parity_direction %in% "above"
  expect_true(all(s$ratio_min[above] > 1))
  sensitive <- s$parity_direction %in% "sensitive"
  expect_true(all(s$ratio_min[sensitive] <= 1 & s$ratio_max[sensitive] >= 1))
  expect_true(all(is.na(s$parity_direction[!finite])))
  # the 2025 Black rows equal the original release's bounds
  old <- btg_sensitivity(btg_get_data())
  new <- s[s$year == 2025 & s$group == "Black", ]
  new <- new[match(old$force, new$force), ]
  expect_equal(new$ratio_min, old$ratio_min, tolerance = 1e-10)
  expect_equal(new$ratio_max, old$ratio_max, tolerance = 1e-10)
})

test_that("rank bounds bracket the recorded rank among eligible forces", {
  s <- btg_sensitivity(btg_get_data("force_ethnicity_year", years = 2024:2025))
  e <- s[s$eligible, ]
  expect_true(all(e$rank_best <= e$rank & e$rank <= e$rank_worst))
  expect_true(all(e$rank_best >= 1))
  expect_true(all(is.na(s$rank_best[!s$eligible]) & is.na(s$rank_worst[!s$eligible])))
  met <- e[e$force == "metropolitan" & e$year == 2025 & e$group == "Black", ]
  others <- e[e$year == 2025 & e$group == "Black" & e$force != "metropolitan", ]
  expect_equal(met$rank_best, 1L + sum(others$ratio_min > met$ratio_max))
  expect_equal(met$rank_worst, 1L + sum(others$ratio_max > met$ratio_min))
  # rows are ordered by year, group and rank with ineligible forces last
  block <- s[s$year == 2025 & s$group == "Black", ]
  expect_identical(block$rank[block$eligible], sort(block$rank[block$eligible]))
  expect_true(all(which(!block$eligible) > max(which(block$eligible))))
})

test_that("selections and unsupported datasets are handled explicitly", {
  y <- btg_get_data("force_ethnicity_year")
  one <- btg_sensitivity(y, year = 2023, group = "Mixed")
  expect_true(all(one$year == 2023 & one$group == "Mixed"))
  expect_equal(nrow(one), 44)
  expect_error(btg_sensitivity(y, year = 2017), "year must be")
  expect_error(btg_sensitivity(y, group = "White"), "group must be")
  expect_error(btg_sensitivity(btg_get_data("national_year")), "comparison datasets")
  expect_error(btg_sensitivity(y$data), "documented dataset")
  council <- btg_sensitivity(btg_get_data("council_ethnicity_year", council = "E09000022"))
  expect_true(all(c("council", "council_label", "ratio_min", "ratio_max") %in% names(council)))
  expect_false(any(c("rank", "rank_best", "eligible") %in% names(council)))
  finite <- is.finite(council$ratio)
  expect_true(all(council$ratio_min[finite] <= council$ratio[finite] * (1 + 1e-9) &
                    council$ratio[finite] <= council$ratio_max[finite] * (1 + 1e-9)))
  expect_true(all(is.na(council$ratio_min[!finite])))
})

test_that("rank stability is reproducible, bounded and leaves the RNG alone", {
  x <- btg_get_data()
  r <- btg_rank_stability(x, draws = 500)
  expect_equal(nrow(r), 40)
  expect_identical(r, btg_rank_stability(x, draws = 500))
  expect_false(identical(r$prob_top, btg_rank_stability(x, draws = 500, seed = 2)$prob_top))
  expect_true(all(r$rank_lower <= r$rank & r$rank <= r$rank_upper))
  expect_true(all(r$prob_top >= 0 & r$prob_top <= 1))
  expect_equal(sum(r$prob_top), 10)
  expect_equal(sum(btg_rank_stability(x, draws = 300, top = 3)$prob_top), 3)
  expect_identical(r$rank, sort(r$rank))
  expect_equal(attr(r, "draws"), 500L)
  expect_equal(attr(r, "seed"), 1L)
  set.seed(42)
  before <- stats::runif(1)
  set.seed(42)
  invisible(btg_rank_stability(x, draws = 200))
  expect_identical(stats::runif(1), before)
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    rm(".Random.seed", envir = globalenv())
  }
  invisible(btg_rank_stability(x, draws = 200))
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
  y <- btg_get_data("force_ethnicity_year", years = 2024:2025, groups = c("Black", "Asian"))
  multi <- btg_rank_stability(y, draws = 200)
  expect_equal(nrow(unique(multi[c("year", "group")])), 4)
  expect_error(btg_rank_stability(x, draws = 10), "draws must be")
  expect_error(btg_rank_stability(x, top = 0), "top must be")
  expect_error(btg_rank_stability(x, seed = "a"), "seed must be")
  expect_error(btg_rank_stability(btg_get_data("council_ethnicity_year")), "force-level")
  expect_error(btg_rank_stability(btg_get_data(force = "btp")), "No dashboard-eligible")
})

test_that("the sensitivity chart shows the ranking chart's forces with their bounds", {
  x <- btg_get_data()
  p <- btg_plot_sensitivity(x)
  expect_s3_class(p, "ggplot")
  expect_silent(ggplot2::ggplot_build(p))
  d <- btg_figure_data(p)
  expect_equal(nrow(d), 10)
  expect_identical(d$force, btg_figure_data(btg_plot_disparity(x))$force)
  expect_true(all(c("ratio_min", "ratio_max", "parity_direction") %in% names(d)))
  expect_match(p$labels$title, "How robust")
  expect_match(p$labels$subtitle, "keep their side of parity")
  for (ranking in c("lowest", "closest")) {
    expect_identical(btg_figure_data(btg_plot_sensitivity(x, n = 5, ranking = ranking))$force,
                     btg_figure_data(btg_plot_disparity(x, n = 5, ranking = ranking))$force)
  }
  y <- btg_get_data("force_ethnicity_year")
  q <- btg_plot_sensitivity(y, year = 2024, group = "Asian", highlight = "metropolitan")
  expect_silent(ggplot2::ggplot_build(q))
  view <- attr(q, "btg_view")
  expect_equal(view$chart, "force_disparity_sensitivity")
  expect_equal(view[c("year", "group", "highlight")], list(year = 2024L, group = "Asian", highlight = "metropolitan"))
  expect_error(btg_dashboard_url(q), "ranking chart")
  expect_error(btg_plot_sensitivity(y, year = 2017), "year must be")
  expect_error(btg_plot_sensitivity(y, highlight = "nowhere"), "highlight")
  expect_error(btg_plot_sensitivity(btg_get_data("national_year")), "force-level")
})

test_that("sensitivity views save and replay as the sensitivity chart", {
  y <- btg_get_data("force_ethnicity_year")
  p <- btg_plot_sensitivity(y, year = 2023, group = "Black", ranking = "closest", n = 6)
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  btg_save_view(p, path)
  replay <- btg_from_view(path)
  expect_identical(btg_figure_data(replay), btg_figure_data(p))
  expect_identical(attr(replay, "btg_view"), attr(p, "btg_view"))
  expect_match(replay$labels$title, "How robust")
  bad <- attr(p, "btg_view")
  bad$chart <- "force_disparity_other"
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "chart")
  bad <- attr(btg_plot_disparity(), "btg_view")
  bad$schema_version <- 1L
  bad$chart <- "force_disparity_sensitivity"
  bad$group <- NULL
  bad$highlight <- NULL
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "chart")
})
