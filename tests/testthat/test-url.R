test_that("a chart links to the same view on the dashboard in both forms", {
  p <- btg_plot_disparity(btg_get_data("force_ethnicity_year"), year = 2024, group = "Asian",
                          ranking = "closest", highlight = "metropolitan")
  link <- btg_dashboard_url(p)
  expect_match(link, "^https://[^?]+/\\?tab=disparity&year=2024&eth=Asian&def=std&view=chart&force=Metropolitan%20Police$")
  state <- btg_dashboard_url(p, format = "state", base = "https://example.org/app")
  expect_match(state, "^https://example.org/app/\\?tab=disparity&v=1&state=")
  q <- BlackThriveSS:::.parse_query(state)
  decoded <- jsonlite::fromJSON(q$state)
  expect_equal(decoded$year, 2024)
  expect_equal(decoded$eth, "Asian")
  expect_equal(decoded$ranking_view, "closest")
  expect_equal(decoded[["_focus"]], "Metropolitan Police")
  expect_equal(q$release, "2026-07")
  # no selected force, no force parameter
  expect_false(grepl("force", btg_dashboard_url(btg_plot_disparity()), fixed = TRUE))
  expect_error(btg_dashboard_url(ggplot2::ggplot()), "No BlackThriveSS view")
  expect_equal(btg_dashboard_base(), "https://bgtresearch-stop-search-dashboard.share.connect.posit.cloud/")
  old <- options(BlackThriveSS.dashboard_url = "https://preview.example")
  on.exit(options(old))
  expect_match(btg_dashboard_url(p), "^https://preview[.]example/[?]tab=disparity")
})

test_that("dashboard links round-trip to the same evidence table", {
  y <- btg_get_data("force_ethnicity_year")
  for (ranking in c("highest", "lowest", "closest")) {
    p <- btg_plot_disparity(y, year = 2023, group = "Mixed", ranking = ranking, highlight = "dorset")
    back <- btg_from_url(btg_dashboard_url(p, format = "state"))
    expect_identical(btg_figure_data(back), btg_figure_data(p))
    expect_identical(attr(back, "btg_view"), attr(p, "btg_view"))
  }
  # the per-parameter form cannot carry the ranking order
  p <- btg_plot_disparity(y, year = 2022, highlight = "kent")
  back <- btg_from_url(btg_dashboard_url(p))
  expect_identical(btg_figure_data(back), btg_figure_data(p))
})

test_that("links from the live dashboard and older links are understood", {
  legacy <- btg_from_url("https://host/app/?tab=disparity&year=2024&def=std&eth=Asian&view=chart&force=West%20Midlands%20Police")
  d <- btg_figure_data(legacy)
  expect_true(all(d$year == 2024 & d$group == "Asian"))
  expect_equal(attr(legacy, "btg_view")$highlight, "west-midlands")
  # the dashboard's starting year and group when the link names none
  bare <- btg_from_url("?tab=disparity")
  expect_equal(attr(bare, "btg_view")$year, 2025L)
  expect_equal(attr(bare, "btg_view")$group, "Black")
  expect_identical(btg_figure_data(bare), btg_figure_data(btg_plot_disparity(btg_get_data("force_ethnicity_year"))))
  state <- paste0("?tab=disparity&v=1&state=", utils::URLencode(
    '{"year":2021,"eth":"Other","def":"std","view":"map","ranking_view":"lowest","_focus":"Kent"}', reserved = TRUE))
  p <- btg_from_url(state)
  expect_equal(attr(p, "btg_view")[c("year", "group", "ranking", "highlight")],
               list(year = 2021L, group = "Other", ranking = "lowest", highlight = "kent"))
  expect_equal(nrow(btg_figure_data(btg_from_url(state, n = 3))), 3)
})

test_that("links that cannot be reproduced fail or warn explicitly", {
  expect_error(btg_from_url("https://host/?tab=rankings&year=2024"), "tab=disparity")
  expect_error(btg_from_url("https://host/"), "tab=disparity")
  expect_error(btg_from_url("?tab=disparity&def=exp"), "self-defined")
  expect_error(btg_from_url("?tab=disparity&year=2017"), "does not hold")
  expect_error(btg_from_url("?tab=disparity&eth=White"), "Unknown group")
  expect_error(btg_from_url("?tab=disparity&v=2&state=%7B%7D"), "version")
  expect_error(btg_from_url("?tab=disparity&v=1&state=not-json"), "Invalid dashboard view state")
  expect_warning(btg_from_url("?tab=disparity&force=Nowhere%20Police"), "not a force")
  expect_warning(btg_from_url("?tab=disparity&v=1&state=%7B%22ranking_view%22%3A%22sideways%22%7D"), "ranking")
  expect_warning(btg_from_url("?tab=disparity&v=1&state=%7B%7D&release=2027-01"), "source month")
  expect_error(btg_from_url(strrep("x", 9000)), "too long")
})
