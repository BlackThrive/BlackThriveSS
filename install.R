# Source this file, then call install_blackthrivess().
# This installer is distributed beside the source package, not inside it.
install_blackthrivess <- function(bundle = if (file.exists("release.dcf")) "." else "artifacts/release",
                                  lib = file.path(getwd(), "artifacts", "library"),
                                  repos = "https://cloud.r-project.org", dependencies = TRUE) {
  if ("BlackThriveSS" %in% loadedNamespaces()) {
    stop("Restart R before installing BlackThriveSS; its namespace is already loaded.")
  }
  bundle <- normalizePath(bundle, winslash = "/", mustWork = TRUE)
  manifest_path <- file.path(bundle, "release.dcf")
  if (!file.exists(manifest_path)) stop("release.dcf is missing. Use a complete release bundle.")
  m <- read.dcf(manifest_path)
  required <- c("Package", "Version", "Archive", "MD5", "SHA256", "RMinimum")
  if (nrow(m) != 1L || !all(required %in% colnames(m)) ||
      m[1, "Package"] != "BlackThriveSS") stop("Invalid release manifest.")
  archive_name <- unname(m[1, "Archive"])
  if (!identical(archive_name, basename(archive_name)) ||
      !identical(archive_name, paste0("BlackThriveSS_", m[1, "Version"], ".tar.gz"))) {
    stop("Invalid archive filename in release manifest.")
  }
  archive <- file.path(bundle, archive_name)
  if (!file.exists(archive) || !identical(unname(tools::md5sum(archive)), unname(m[1, "MD5"]))) {
    stop("Source archive failed its integrity check. Obtain a complete release bundle.")
  }
  if (getRversion() < package_version(m[1, "RMinimum"])) {
    stop("This release needs R ", m[1, "RMinimum"], " or later.")
  }
  if (!is.logical(dependencies) || length(dependencies) != 1L || is.na(dependencies)) {
    stop("dependencies must be TRUE or FALSE.")
  }
  needs <- c(digest = "0.0.0", ggplot2 = "3.4.0", jsonlite = "0.0.0")
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  lib <- normalizePath(lib, winslash = "/", mustWork = TRUE)
  probe <- tempfile("write-test-", tmpdir = lib)
  if (!file.create(probe)) stop("Choose a writable library using lib = ...")
  unlink(probe)
  previous <- .libPaths()
  succeeded <- FALSE
  on.exit(if (!succeeded) .libPaths(previous), add = TRUE)
  .libPaths(c(lib, previous))
  satisfied <- function(pkg) {
    found <- tryCatch(utils::packageVersion(pkg), error = function(e) NULL)
    !is.null(found) && found >= package_version(needs[[pkg]])
  }
  missing <- names(needs)[!vapply(names(needs), satisfied, logical(1))]
  if (length(missing)) {
    if (!dependencies) stop("Missing/outdated dependencies: ", paste(missing, collapse = ", "))
    if (any(missing %in% loadedNamespaces())) stop("Restart R before updating loaded dependencies.")
    message("Installing required CRAN dependencies into ", lib, ": ", paste(missing, collapse = ", "))
    utils::install.packages(missing, lib = lib, repos = repos,
                            dependencies = c("Depends", "Imports", "LinkingTo"))
    if (!all(vapply(names(needs), satisfied, logical(1)))) stop("Dependency installation did not complete.")
  }
  if (!identical(digest::digest(file = archive, algo = "sha256"), unname(m[1, "SHA256"]))) {
    stop("Source archive failed its SHA-256 integrity check.")
  }
  message("Installing BlackThriveSS ", m[1, "Version"], " into ", lib)
  utils::install.packages(archive, repos = NULL, type = "source", lib = lib)
  installed <- tryCatch(as.character(utils::packageVersion("BlackThriveSS", lib.loc = lib)),
                         error = function(e) NA_character_)
  if (!identical(installed, unname(m[1, "Version"]))) stop("Package installation did not complete.")
  succeeded <- TRUE
  message("Installed. This session can now run library(BlackThriveSS).\n",
          "In a new session use .libPaths(c(", dQuote(lib), ", .libPaths())).")
  invisible(lib)
}
