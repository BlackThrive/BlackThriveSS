# BlackThriveSS: path to CRAN

Working version: **0.1.0**. Review date: **23 October 2026**.
Scope: two immutable data releases (the original 2025 `force_disparity`
dataset and a six-dataset catalogue from the same dashboard snapshot), the
force ranking chart for any year and group, saved views, and the URL round
trip with the dashboard website, plus, since 0.0.3: robustness analysis
(`btg_sensitivity()`, `btg_rank_stability()`, `btg_plot_sensitivity()`),
`btg_robustness_summary()`), trends and change (`btg_plot_trend()`,
`btg_change()`, `btg_plot_change()`), a live-source check
(`btg_source_status()`, the package's only network use, which fails
quietly and whose network test runs only when
`BLACKTHRIVESS_NETWORK_TESTS=true`),
profiles and HTML briefings (`btg_profile()`, `btg_report()`), exports and
the glossary, schema 3 saved views, two further vignettes and a pkgdown
configuration. The dashboard button is deferred. No CRAN submission or
hosted release is created by this work.

## Submission record

* 23 October 2026, 13:38 UTC: `BlackThriveSS_0.1.0.tar.gz` (SHA-256
  `1c9c7cb71c773d1836deea41c03621d75e947830c88028751c325a6a24181422`), built from commit `6ab7379`
  and tagged `v0.1.0`, was uploaded through CRAN's submission form with the
  text of `cran-comments.md` (submission id 359973). The final
  `R CMD check --as-cran` on that exact archive, with the online incoming
  checks enabled, reported 0 errors, 0 warnings and 2 notes: "New
  submission" and the local absence of HTML Tidy. The maintainer must
  confirm the submission from the email CRAN sends.

## Checks on 0.1.0

* Ubuntu 24.04 / R 4.6.1: `R CMD check --as-cran` on the built 0.1.0
  archive, with remote incoming checks disabled and `R_RD4PDF="times,hyper"`
  because the container lacks the LaTeX `inconsolata` package: 0 errors,
  0 warnings, 1 note (HTML Tidy not installed locally, so HTML manual
  validation was skipped). Examples, `\donttest` examples, tests, vignette
  rebuilds and the PDF manual are part of that run.
* GitHub Actions on the merged 0.1.0 source: see the row below.
* `urlchecker::url_check()` finds every URL valid; `spelling` is clean
  against `inst/WORDLIST`; every exported function documents its return
  value; console output is confined to print methods; `set.seed()` is used
  only inside a helper that restores the caller's random-number state; no
  example uses `\dontrun`; the slowest example (the briefing) renders a
  council briefing in about three seconds.
* Help pages are generated with roxygen2 8.1.1, which replaces the
  `RoxygenNote` field with `Config/roxygen2/version`.

## Verified local results

The 0.0.3 source archive has SHA-256
`4864d2a236b6f823e45a5f48db1bc0556bd490c9bd2eecbc902157f2e59df9ef`
(855 KB, of which about 0.8 MB is compressed data). The installation bundle
contains this same archive.

* Fresh-library installation passed, including a library path containing spaces.
  Existing dependency installations were reused; downloading dependencies onto
  a wholly fresh machine remains untested. A corrupted archive was rejected.
* The quickstart, installed HTML tutorial, package citation, the validation
  audit of every bundled dataset and exact saved-view replay passed without a
  dashboard session.
* All 210 packaged test assertions passed, with no failures, warnings or skips.
* Dashboard parity, from `dev/verify-dashboard.R` against the dashboard's own
  calculation functions and source-file hashes:
  * `force_disparity`: twelve fields across 42 rows, all 40 eligible ratios and
    three ordering modes matched; largest absolute numeric difference about
    4.8e-13.
  * `force_ethnicity_year`: 36 year-and-group tables (2018 to 2026, four
    groups), 1,500 rows and 1,125 eligible ratios matched on twelve fields;
    largest absolute difference about 4.2e-10, from storing derived doubles to
    twelve significant figures. Where the dashboard divides by a zero White
    count and shows `Inf`, the package withholds the ratio as `NA`; both sides
    treat the cell as ineligible (West Midlands, 2018 to 2020, Asian and
    Other).
  * The 2025 Black rows of the catalogue equal the original release; the build
    script asserts this and a packaged test re-asserts it.
* `R CMD check --as-cran` on Windows 11 / R 4.5.2 on this archive: see
  `artifacts/check-summary.json` and the section below. Remote incoming checks
  were explicitly disabled, as for 0.0.2, after the default attempt timed out
  retrieving CRAN's package index. The 0.0.2 logs are retained under
  `artifacts/checks/0.0.2` and `artifacts/checks/0.0.2-local`.

Machine-readable evidence is in `artifacts/check-summary.json`,
`artifacts/installation-test.json` and `artifacts/dashboard-parity.json`.
Run `Rscript --vanilla dev/check-release.R` with normal connectivity for the
remote checks. `--local-incoming` is an explicit local fallback, not a substitute
for the remaining pre-submission checks.

## Local package check

`R CMD check --as-cran` on Windows 11 / R 4.5.2 on the 0.0.3 archive completed
with **0 errors, 0 warnings and 1 note**, with
`_R_CHECK_CRAN_INCOMING_REMOTE_=false` explicitly set. The note was **unable to
verify current time**, an online time-check limitation that 0.0.2 also
produced. Examples (12 s), tests (90 s), vignette rebuilding (15 s) and the
PDF and HTML manuals passed. The full log is
`artifacts/checks/0.0.3-local/BlackThriveSS.Rcheck/00check.log`, and
`artifacts/check-summary.json` records the archive SHA-256, R version,
errors, warnings and notes.

The first run of `dev/check-release.R` on this archive reached `DONE` but its
R process was stopped by the script's own ten-minute `rcmdcheck` timeout
before it wrote the summary; the timeout is now 40 minutes. The check takes
about twelve minutes on this workstation because the test suite replays every
dataset through its checksum.

## Release gates

| Gate | Evidence or next action |
|---|---|
| Source installation | `install.R` and the installation ZIP resolve required dependencies, validate archive checksums and target a writable library. Record the fresh-session installation result. |
| User documentation | Executed vignettes: getting started (catalogue, chart, URL round trip, validation, troubleshooting), robustness (bounds, rank intervals, change, export) and briefing (profiles, charts, the HTML briefing); function help; data dictionary with catalogue and derived-table sections; glossary; package and data citations. The briefing test and example skip without rmarkdown and Pandoc. |
| Data integrity | Payload SHA-256 checks on every file, gzip payloads included, plus `btg_validate()` on every dataset: keys, whole counts, ethnicity accounting, coverage reconciliation and the documented calculations. Tests include deliberate corruption. |
| Mathematical correctness | Hand-calculated count/exposure fixtures, zero/missing-count cases, denominator exclusions and eligibility thresholds, shared by the generic group calculation. Allocation bounds, rank bounds and change intervals are checked against independent hand calculations on transcribed Metropolitan Police counts; rank intervals are checked for reproducibility, bracketing and the identity that top-n probabilities sum to n. |
| Dashboard parity | `dev/verify-dashboard.R` checks source hashes, the original 42-row table and three orderings, and all 36 year-and-group tables of the catalogue against the dashboard's own functions. |
| URL round trip | Tests cover both link forms the dashboard reads, all three orderings through the state form, legacy links with force labels, the dashboard's default year and group, and explicit failures for other pages, the expanded definition, unknown years and groups, and malformed state. The live base address is configurable and has not been fetched from this package. |
| Historical replay | The 2025 release and schema 1 views are unchanged and replay; schema 2 views carry year, group and highlight for both force ranking charts; schema 3 views carry a dataset selection and chart settings for trend and change charts, and settings are never evaluated. |
| Local package check | Passed on 23 October 2026 (see Checks on 0.1.0). Re-run `dev/check-release.R` on the exact archive intended for submission and record its SHA-256. |
| Current R and other systems | The R-CMD-check workflow runs `R CMD check --as-cran --no-manual` on Windows release, macOS release, Ubuntu release, devel, oldrel-1 and R 4.1, failing on any warning. Confirm a green run on the exact commit intended for submission before uploading. |
| Source-data review | Reconfirm Police.uk and ONS attributions, population construction and disclosure scope for the council table. No restricted survey records are bundled. Statistical review should distinguish faithful reproduction from sound inference. |
| Ownership and support | `DESCRIPTION` and the citation list five authors: Mustapha Mohammed (maintainer) and, at Black Thrive Global, Sarah Hamed, Souci Frissa, Aisha Mohamed and Nathan Stanley. Sarah Hamed and Souci Frissa carry ORCID identifiers; add identifiers for the other three if they hold them. **Open:** written agreement from every listed author to appear, and the maintainer's confirmation that the submission address stays monitored, since CRAN sends the confirmation and all later correspondence there. |
| Public distribution | The repository `https://github.com/BlackThrive/BlackThriveSS` is public, the documentation site is live at `https://blackthrive.github.io/BlackThriveSS/`, and `DESCRIPTION` carries both in `URL` with a matching `BugReports` field. Tag `v0.1.0` on the submitted commit and preserve supported historical releases. |
| Name and final scope | Check name availability immediately before submission; this document does not reserve the name. Keep the scope useful and adequately documented. |

## Package checks and submission

CRAN's submission checklist asks for `R CMD check --as-cran` using current
R-devel. It also identifies Win-builder and R-hub as supplementary services.
Our multi-platform matrix is a project validation choice, not a claim that CRAN
requires every matrix cell. [CRAN submission checklist](https://cran.r-project.org/web/packages/submission_checklist.html)

The local check ran on R 4.6.1, the current release; R-devel compatibility
is established by the GitHub Actions matrix. [Writing R Extensions](https://cran.r-project.org/doc/manuals/r-release/R-exts.html)

Keep package code and bundled data rights explicit; maintain examples that work
without network access or writes outside temporary files. Review current policies
again before submitting. CRAN acceptance also involves human review and ongoing
maintenance. [CRAN policies](https://cran.r-project.org/web/packages/policies.html)

After technical and ownership gates pass, freeze an intended submission archive,
record its SHA-256, and complete `cran-comments.md` with actual environments and
explanations of notes. Submit that archive through CRAN and complete the
maintainer-email confirmation. Do not describe a submission as acceptance.

## Exact artifact discipline

The build script produces `artifacts/BlackThriveSS_0.0.3.tar.gz`,
`artifacts/release/release.dcf`, and the installation ZIP. Check the same source
archive that will be distributed. If any included source, documentation or data
changes, rebuild and re-check; do not carry forward an earlier pass. Earlier
archives (0.0.1, 0.0.2) and their check directories are kept as history and are
not the distributed build.

The data releases are `dashboard-2026-07-2025-99a88b69f2d6` and
`dashboard-2026-07-catalogue-bacf49c2a48d`, both from the same dashboard build
of the July 2026 source month. A release directory is never overwritten; a
changed source or method produces a new release identifier. Updating the
package's installation or help does not change a data release. Runtime users
receive the aggregate snapshots with the package, so a hosted API is not a
prerequisite for this first release.

## External services

The CI workflow is based on the official [r-lib/actions example](https://github.com/r-lib/actions/blob/v2/examples/check-standard.yaml)
and runs on every push to `main` of `BlackThrive/BlackThriveSS`. The first
two runs failed before checking anything because the `error-on` input was
passed unquoted and evaluated as an R symbol; the input is now `'"warning"'`
as in the upstream example, and the matrix passes (see the release gates).

Win-builder sends results to the maintainer address and is a separate upload.
Record any such result before claiming it passed. [Win-builder](https://win-builder.r-project.org/)

The dashboard link functions build and parse URL strings only. The default
base address is the dashboard's published share link; confirm it resolves
before advertising the round trip, and set `BlackThriveSS.dashboard_url` for
any other deployment.
