test_that("charts expose their evidence and label incomplete returns", {
  p <- btg_plot_disparity()
  expect_s3_class(p, "ggplot")
  d <- btg_figure_data(p)
  expect_equal(nrow(d), 10)
  expect_true(all(diff(d$ratio) <= 0))
  expect_equal(d$rank, 1:10)
  expect_true(all(grepl("*", d$axis_label[d$coverage_status != "all_months_supplied"], fixed = TRUE)))
  expect_error(btg_plot_disparity(n = 0), "integer")
  expect_error(btg_plot_disparity(n = 1.5), "integer")
  expect_error(btg_plot_disparity(btg_get_data(force = "btp")), "No dashboard-eligible")
  expect_error(btg_figure_data(ggplot2::ggplot()), "No BlackThriveSS")
  for (ranking in c("highest", "lowest", "closest")) {
    expect_silent(ggplot2::ggplot_build(btg_plot_disparity(ranking = ranking)))
  }
})

test_that("saved views reproduce exact evidence including filtered selections", {
  for (forces in list(NULL, "metropolitan", c("dorset", "metropolitan"))) {
    for (ranking in c("highest", "lowest", "closest")) {
      path <- tempfile(fileext = ".json")
      on.exit(unlink(path), add = TRUE)
      p <- btg_plot_disparity(btg_get_data(force = forces), n = 5, ranking = ranking)
      btg_save_view(p, path)
      replay <- btg_from_view(path)
      expect_identical(btg_figure_data(replay), btg_figure_data(p))
      expect_identical(attr(replay, "btg_view"), attr(p, "btg_view"))
      expect_error(btg_save_view(p, path), "File exists")
    }
  }
})

test_that("invalid or incompatible views fail instead of silently falling forward", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  view <- attr(btg_plot_disparity(), "btg_view")
  bad <- view
  bad$release <- "future-release"
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "Unknown release")
  bad <- view
  bad$data_sha256 <- "wrong"
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "checksums")
  bad <- view
  bad$chart_version <- 99L
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "chart_version")
  bad <- view
  bad$code <- "stop('must never be evaluated')"
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "fields")
  bad <- view
  bad$force <- NULL
  jsonlite::write_json(bad, path, auto_unbox = TRUE)
  expect_error(btg_from_view(path), "fields")
  writeLines("not JSON", path)
  expect_error(btg_from_view(path), "JSON")
  writeLines(paste(rep("x", 65537), collapse = ""), path)
  expect_error(btg_from_view(path), "64 KiB")
})

test_that("the bundled view is self-contained", {
  path <- system.file("examples", "disparity-2025.json", package = "BlackThriveSS")
  expect_identical(btg_figure_data(btg_from_view(path)), btg_figure_data(btg_plot_disparity()))
})

test_that("the chart uses the shared theme and labels incomplete returns by fill", {
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", btg_colours())))
  expect_s3_class(btg_theme(), "theme")
  p <- btg_plot_disparity()
  expect_equal(p$theme$plot.title.position, "plot")
  built <- ggplot2::ggplot_build(p)
  fills <- unique(built$data[[1]]$fill)
  d <- btg_figure_data(p)
  expect_equal(length(fills), length(unique(d$coverage_status == "all_months_supplied")))
  # intervals are drawn for every displayed force with a finite interval
  ranges <- built$data[[3]]
  expect_equal(sum(is.finite(ranges$xmin)), sum(is.finite(d$ci_lower)))
  # a single-force selection has one fill and no legend
  one <- btg_plot_disparity(btg_get_data(force = "metropolitan"), n = 1)
  expect_silent(ggplot2::ggplot_build(one))
})
