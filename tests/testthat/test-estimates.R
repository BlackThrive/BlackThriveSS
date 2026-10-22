test_that("event rates match an independent hand calculation", {
  fixture <- data.frame(force = "example", black_stops = 20, white_stops = 100,
                        black_population = 10000, white_population = 100000,
                        known_ethnicity_stops = 200)
  d <- BlackThriveSS:::.calculate_disparity(fixture)
  expect_equal(d$black_rate, 2)
  expect_equal(d$white_rate, 1)
  expect_equal(d$ratio, 2)
  expect_equal(d$ci_lower, 2 * exp(-qnorm(.975) * sqrt(.06)))
  expect_equal(d$ci_upper, 2 * exp(qnorm(.975) * sqrt(.06)))
  expect_true(d$eligible)
})

test_that("zeros, missing returns and non-comparable populations stay distinct", {
  fixture <- data.frame(
    force = c("zero-black", "zero-white", "no-return", "btp", "city-of-london", "small", "no-pop"),
    black_stops = c(0, 20, NA, 20, 20, 20, 20),
    white_stops = c(100, 0, NA, 100, 100, 100, 100),
    black_population = c(10000, 10000, 10000, NA, 10000, 10000, 0),
    white_population = c(100000, 100000, 100000, NA, 100000, 49999, 100000),
    known_ethnicity_stops = c(200, 200, NA, 200, 200, 200, 200))
  d <- BlackThriveSS:::.calculate_disparity(fixture)
  expect_equal(d$ratio[1], 0)
  expect_true(all(is.na(d$ratio[-1])))
  expect_true(all(is.na(d$ci_lower)))
  expect_false(any(d$eligible))
  expect_true(is.na(d$black_stops[3]))
})

test_that("the dashboard count threshold and tied ranks are respected", {
  d <- data.frame(force = c("a", "b", "c"), black_stops = c(20, 20, 20),
                  white_stops = 100, black_population = 10000,
                  white_population = 100000, known_ethnicity_stops = c(199, 200, 201))
  result <- BlackThriveSS:::.calculate_disparity(d)
  expect_identical(result$eligible, c(FALSE, TRUE, TRUE))
  expect_identical(result$rank, c(NA_integer_, 1L, 1L))
})
