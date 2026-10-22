test_that("the fixed release retains coverage and missing-force rows", {
  x <- btg_get_data()
  expect_s3_class(x, "btg_dataset")
  expect_equal(nrow(x$data), 44)
  expect_equal(nrow(x$coverage), 528)
  expect_equal(sum(x$data$eligible), 40)
  absent <- x$data[x$data$force %in% c("greater-manchester", "gwent"), ]
  expect_true(all(is.na(absent$total_records)))
  expect_true(all(absent$months_missing == 12))
  expect_true(all(is.na(x$coverage$records[x$coverage$status == "missing"])))
  expect_true(all(rowSums(x$data[c("months_supplied", "months_missing", "months_unverified")]) == 12))
  met <- btg_get_data(force = "metropolitan")
  # Independently transcribed source counts and Census populations.
  expect_equal(met$data$black_stops, 56116)
  expect_equal(met$data$white_stops, 48798)
  expect_equal(met$data$black_population, 1188137)
  expect_equal(met$data$white_population, 4725217)
  expect_equal(met$data$ratio, (56116 / 1188137) / (48798 / 4725217))
  expect_equal(met$data$unknown_ethnicity_stops, 8826)
  expect_equal(met$data$months_supplied, 12)
  expect_equal(btg_metadata(x)$source$latest_month, "2026-07")
})

test_that("unsupported selections and altered evidence cannot claim a release", {
  expect_error(btg_get_data(years = 2026), "2025")
  expect_error(btg_get_data(years = c(2024, 2025)), "2025")
  expect_error(btg_get_data(dataset = "private"), "Unsupported dataset")
  expect_error(btg_get_data(release = "latest"), "Unknown release")
  expect_error(btg_get_data(force = "Metropolitan Police"), "identifiers")
  expect_error(btg_get_data(force = character()), "identifiers")
  expect_error(btg_get_data(force = c("metropolitan", "metropolitan")), "identifiers")
  x <- btg_get_data()
  x$data$ratio[1] <- 100
  expect_error(btg_plot_disparity(x), "changed")
  x <- btg_get_data()
  x$metadata$ethnicity$field <- "Self-defined"
  expect_error(btg_metadata(x), "changed")
  expect_error(btg_plot_disparity(btg_get_data()$data), "documented dataset")
})

test_that("payload checksum validation detects corrupted files", {
  m <- BlackThriveSS:::.release()
  m$files$data$sha256 <- paste(rep("0", 64), collapse = "")
  expect_error(BlackThriveSS:::.read_payload(m, "data"), "integrity")
})
