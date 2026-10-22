# Draft submission comments — not ready to upload

This is a first submission of BlackThriveSS. The package bundles fixed,
checksummed snapshots of public aggregate stop-and-search evidence from the
Black Thrive dashboard (force, council and national tables from 2018 onwards
with monthly reporting coverage), reproduces the dashboard's force ranking
chart, replays saved chart specifications, and exchanges links with the
dashboard website. It works offline and carries source attribution,
checksums and an executed tutorial.

## Test environments

Populate this section from actual checks on the exact submission archive:

* Local Windows 11 / R 4.5.2: see `artifacts/check-summary.json` for the
  result on archive SHA-256
  `4864d2a236b6f823e45a5f48db1bc0556bd490c9bd2eecbc902157f2e59df9ef`
  using `--as-cran` with remote incoming checks explicitly disabled, because
  the default attempt on 0.0.2 timed out retrieving CRAN's package index.
  Examples, tests, vignette rebuilds and HTML manuals are part of that run.
* GitHub Actions, 22 October 2026, on commit `3a7b890` (the 0.0.3 source plus
  `URL`/`BugReports` fields): Windows release, macOS release, Ubuntu release,
  R-devel, oldrel-1 and R 4.1 all returned status OK with no notes under
  `--as-cran --no-manual`. Repeat on the exact submission archive.

## Results

Repeat the online checks before submission; this draft does not claim the
remote incoming check passed. Do not submit with pending environments. Record
the remaining actual results and explain any notes on the final intended
submission archive.

## Data and runtime behaviour

Only small public aggregates (about 0.8 MB of compressed CSV) and submission
coverage are bundled. No network connection, credentials, dashboard session or
restricted survey data is required. Examples use temporary files and do not
open external viewers. `btg_dashboard_url()` only builds a URL string; nothing
in the package fetches it. Package code uses MIT; source-data attribution
identifies the Open Government Licence v3.0. No compiled code or non-CRAN
runtime dependencies are used.

## Maintainer review

Confirm authorship, rights, final package name and contact details. Add truthful
public URL/BugReports metadata after a repository exists. Review current CRAN
policy and replace this draft with the final reviewable submission comments.
