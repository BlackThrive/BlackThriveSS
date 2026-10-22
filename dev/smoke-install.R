# Run in a fresh R process after dev/build-release.R.
run_smoke <- function() {
  root <- normalizePath(".", winslash = "/")
  source("install.R", local = TRUE)
  bundle <- normalizePath("artifacts/release", winslash = "/")
  m <- read.dcf(file.path(bundle, "release.dcf"))
  scratch <- tempfile("BlackThriveSS install test ")
  dir.create(scratch)
  scratch <- normalizePath(scratch, winslash = "/", mustWork = TRUE)
  stopifnot(identical(dirname(scratch), normalizePath(tempdir(), winslash = "/", mustWork = TRUE)))
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  bad_bundle <- file.path(scratch, "corrupted")
  dir.create(bad_bundle)
  file.copy(file.path(bundle, c("release.dcf", m[1, "Archive"])), bad_bundle)
  connection <- file(file.path(bad_bundle, m[1, "Archive"]), "ab")
  writeBin(charToRaw("corruption-test"), connection)
  close(connection)
  failed <- tryCatch({
    install_blackthrivess(bad_bundle, lib = file.path(scratch, "must-not-install"), dependencies = FALSE)
    FALSE
  }, error = function(e) grepl("integrity check", conditionMessage(e), fixed = TRUE))
  stopifnot(failed, !dir.exists(file.path(scratch, "must-not-install")))

  # Only BlackThriveSS is freshly installed; installed dependency packages are reused.
  lib <- file.path(scratch, "clean library")
  install_blackthrivess(bundle, lib = lib, dependencies = FALSE)
  library(BlackThriveSS, character.only = FALSE)
  stopifnot(identical(normalizePath(find.package("BlackThriveSS")),
                      normalizePath(file.path(lib, "BlackThriveSS"))))
  stopifnot(identical(as.character(packageVersion("BlackThriveSS")), unname(m[1, "Version"])))
  checks <- btg_validate()
  stopifnot(all(checks$passed))
  p <- btg_plot_disparity()
  json <- file.path(scratch, "view.json")
  btg_save_view(p, json)
  stopifnot(identical(btg_figure_data(p), btg_figure_data(btg_from_view(json))))
  tutorial <- system.file("doc", "getting-started.html", package = "BlackThriveSS")
  stopifnot(nzchar(tutorial), file.info(tutorial)$size > 10000)
  cite <- paste(format(citation("BlackThriveSS")), collapse = " ")
  stopifnot(grepl(m[1, "Version"], cite, fixed = TRUE))
  grDevices::pdf(file.path(scratch, "quickstart.pdf"), width = 11.5, height = 7.5)
  source(file.path(bundle, "quickstart.R"), local = TRUE)
  grDevices::dev.off()
  stopifnot(!"shiny" %in% loadedNamespaces())
  report <- list(status = "passed", package_version = m[1, "Version"],
                 archive_sha256 = m[1, "SHA256"], r_version = R.version.string,
                 clean_package_library = TRUE, dependency_libraries = "Existing installed dependencies reused",
                 dependency_download_tested = FALSE,
                 corrupt_archive_rejected = failed, offline_runtime_example = "passed",
                 validation = checks, installed_vignette = TRUE, json_replay = "identical",
                 shiny_loaded = FALSE)
  jsonlite::write_json(report, file.path(root, "artifacts", "installation-test.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  cat("Clean-library installation, corruption rejection, quickstart, vignette and replay passed.\n")
}
run_smoke()
