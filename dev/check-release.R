# Run from the project after dev/build-release.R.
# Uses installed rcmdcheck/jsonlite/digest; needs the normal R check tools.
# Does not submit the package to CRAN or another service.
version <- unname(read.dcf("DESCRIPTION")[1, "Version"])
local_incoming <- "--local-incoming" %in% commandArgs(trailingOnly = TRUE)
if (local_incoming) Sys.setenv("_R_CHECK_CRAN_INCOMING_REMOTE_" = "false")
archive <- file.path("artifacts", paste0("BlackThriveSS_", version, ".tar.gz"))
stopifnot(file.exists(archive))
dir.create("artifacts/checks", recursive = TRUE, showWarnings = FALSE)
result <- rcmdcheck::rcmdcheck(archive, args = "--as-cran", error_on = "never", timeout = 2400,
                              check_dir = file.path("artifacts/checks", paste0(version,
                                if (local_incoming) "-local" else "")))
summary <- list(
  package = "BlackThriveSS", version = version,
  archive_sha256 = digest::digest(file = archive, algo = "sha256"),
  r_version = R.version.string, platform = R.version$platform,
  args = "--as-cran", remote_incoming_enabled = !local_incoming,
  errors = result$errors, warnings = result$warnings,
  notes = result$notes,
  status = if (length(result$errors) || length(result$warnings)) "failed" else
    if (length(result$notes)) "passed_with_notes_to_review" else "passed",
  external_checks = "Current R release/devel and Linux/macOS checks remain pending until executed.")
jsonlite::write_json(summary, "artifacts/check-summary.json", pretty = TRUE, auto_unbox = TRUE)
writeLines(capture.output(sessionInfo()), "artifacts/check-session-info.txt")
if (length(result$errors) || length(result$warnings)) stop("Release check failed; inspect artifacts/check-summary.json.")
cat("Check complete. Review every note and outstanding platform before submission.\n")
