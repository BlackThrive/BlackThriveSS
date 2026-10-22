# Build a source package with its vignette and a portable installation bundle.
# Run from the project: Rscript --vanilla dev/build-release.R
stopifnot(file.exists("DESCRIPTION"))
root <- normalizePath(".", winslash = "/")
desc <- read.dcf("DESCRIPTION")
version <- unname(desc[1, "Version"])
bundle_only <- "--bundle-only" %in% commandArgs(trailingOnly = TRUE)
if (!bundle_only && !rmarkdown::pandoc_available()) stop("Pandoc is required to build the tutorial; set RSTUDIO_PANDOC to its directory.")
dir.create("artifacts", showWarnings = FALSE)
out <- normalizePath("artifacts", winslash = "/")
if (!bundle_only) {
old <- setwd(out)
r <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R")
build_log <- tempfile("BlackThriveSS-build-", fileext = ".log")
status <- system2(r, c("CMD", "build", shQuote(root), "--no-manual"),
                   stdout = build_log, stderr = build_log)
file.copy(build_log, paste0("build-", version, ".log"), overwrite = TRUE)
unlink(build_log)
setwd(old)
if (status != 0L) stop("Source build failed. Read artifacts/build-", version, ".log.")
}
archive_name <- paste0("BlackThriveSS_", version, ".tar.gz")
archive <- file.path(out, archive_name)
stopifnot(file.exists(archive))
bundle <- file.path(out, "release")
dir.create(bundle, showWarnings = FALSE)
stopifnot(file.copy(archive, file.path(bundle, archive_name), overwrite = TRUE),
          file.copy("install.R", file.path(bundle, "install.R"), overwrite = TRUE),
          file.copy("inst/examples/quickstart.R", file.path(bundle, "quickstart.R"), overwrite = TRUE))
manifest <- c(Package = "BlackThriveSS", Version = version, Archive = archive_name,
              MD5 = unname(tools::md5sum(archive)),
              SHA256 = digest::digest(file = archive, algo = "sha256"), RMinimum = "4.1.0",
              DataReleases = paste(unlist(jsonlite::read_json("inst/extdata/catalogue.json")$releases),
                                   collapse = ", "))
write.dcf(as.data.frame(as.list(manifest)), file.path(bundle, "release.dcf"))
writeLines(c(
  paste("BlackThriveSS", version, "- local development release"), "",
  "Extract all files into a folder. Set that folder as your R working directory.",
  "In a fresh R session run:", "", "  source('install.R')", "  install_blackthrivess()",
  "  library(BlackThriveSS)", "  source('quickstart.R')", "",
  "The installer verifies the archive and installs missing required dependencies from CRAN.",
  "Default installation is into artifacts/library inside your chosen working folder.",
  "Use install_blackthrivess(lib = '/your/writable/library') for another location.",
  "For an offline install with dependencies already present, set dependencies = FALSE.",
  "No devtools, Shiny, dashboard source files or private data are needed.", "",
  "Learn more: vignette('getting-started', package = 'BlackThriveSS')",
  "Check the evidence: btg_validate()", "",
  "This is not a CRAN release. Preserve release.dcf and the archive together."
), file.path(bundle, "START-HERE.txt"))
zipfile <- file.path(out, paste0("BlackThriveSS-", version, "-install.zip"))
bundle_files <- c(archive_name, "install.R", "quickstart.R", "release.dcf", "START-HERE.txt")
old <- setwd(bundle)
zip_status <- utils::zip(zipfile, bundle_files, flags = "-9X")
setwd(old)
if (!identical(zip_status, 0L) || !file.exists(zipfile)) stop("Installation bundle ZIP failed.")
cat("Built ", archive, "\nPortable bundle: ", zipfile, "\n", sep = "")
