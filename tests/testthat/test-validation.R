test_that("the full snapshot and meaningful subsets pass the public audit", {
  for (forces in list(NULL, "metropolitan", "btp", "gwent", c("norfolk", "suffolk"))) {
    checks <- btg_validate(btg_get_data(force = forces))
    expect_true(all(checks$passed), info = paste(checks$check[!checks$passed], collapse = ", "))
    expect_true(all(c("monthly_totals", "missing_returns", "derived_estimates") %in% checks$check))
  }
})

test_that("the audit identifies structural and accounting failures", {
  x <- btg_get_data()
  audit <- BlackThriveSS:::.audit_tables
  failed <- function(result, name) expect_false(result$passed[match(name, result$check)])
  d <- x$data
  d$ratio <- NULL
  failed(audit(d, x$coverage), "schema")
  d <- x$data
  d$black_stops <- as.character(d$black_stops)
  failed(audit(d, x$coverage), "types")
  failed(audit(rbind(x$data, x$data[1, ]), x$coverage), "keys")
  c <- x$coverage
  c$month[1] <- "2024-12"
  failed(audit(x$data, c), "period")
  d <- x$data
  d$black_stops[1] <- -1
  failed(audit(d, x$coverage), "counts")
  c <- x$coverage
  c$records[which(c$status == "missing")[1]] <- 0
  failed(audit(x$data, c), "missing_returns")
  d <- x$data
  d$months_supplied[1] <- 11
  failed(audit(d, x$coverage), "coverage_summary")
  c <- x$coverage
  c$records[1] <- c$records[1] + 1
  failed(audit(x$data, c), "monthly_totals")
  d <- x$data
  d$unknown_ethnicity_stops[1] <- d$unknown_ethnicity_stops[1] + 1
  failed(audit(d, x$coverage), "ethnicity_totals")
  d <- x$data
  d$ratio[1] <- d$ratio[1] + 1
  failed(audit(d, x$coverage), "derived_estimates")
  d <- x$data
  d$rank[which(d$eligible)[1]] <- 0
  failed(audit(d, x$coverage), "rank_encoding")
})

test_that("audit rejects altered evidence and package citation identifies this version", {
  x <- btg_get_data()
  x$coverage$records[1] <- 0
  expect_error(btg_validate(x), "changed")
  cite <- paste(format(utils::citation("BlackThriveSS")), collapse = " ")
  expect_match(cite, as.character(utils::packageVersion("BlackThriveSS")), fixed = TRUE)
})
