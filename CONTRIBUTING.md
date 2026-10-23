# Developing BlackThriveSS

Use a fresh R session. Open the project and install maintainer tools as needed:

```r
install.packages(c("roxygen2", "testthat", "pkgload", "rcmdcheck", "knitr", "rmarkdown"))
pkgload::load_all()
roxygen2::roxygenise()
testthat::test_local()
```

Never modify `NAMESPACE` or `man/*.Rd` by hand. Change the roxygen comments in
`R/` and regenerate them. Installation users need only the package's Imports;
the additional tools above are for maintainers.

## Evidence and compatibility

* Preserve existing release CSV bytes and identifiers. `.gitattributes` disables
  line-ending conversion for checksummed payloads.
* Never replace an old release with a new extract under the same identifier.
  Preserve the 0.0.1 example view as a compatibility fixture.
* Keep observed counts distinct from missing returns. Unknown ethnicity is not
  necessarily item non-response; the dashboard aggregates include vehicle-only
  searches that cannot be separated in this table.
* A source-data change needs a new data release. A calculation or interpretation
  change needs a new method/release identity, a documented comparison and new
  validation. The current builder fingerprints source inputs; it deliberately
  refuses to overwrite them. Extend its identity scheme before releasing changed
  methods on identical inputs.
* For a new chart algorithm, increment `chart_version` and preserve replay for
  existing supported versions, or fail explicitly. Do not silently reinterpret
  a saved specification.
* A new chart attaches `btg_figure_data` and a `btg_view` built with
  `.new_view()` (schema 3), and registers its settings in `.view_settings` and
  its drawing call in `.draw_view()` in `R/view.R`. Settings are passed as
  arguments and never evaluated. The force ranking charts keep schema 2.
* Groups keep the colours in `btg_group_colours()` in every chart; reference
  and de-emphasis colours come from `btg_colours()`. Do not assign colours by
  rank or value.
* Statements written by `btg_profile()` must carry their qualification in the
  same sentence: the interval with the ratio, the coverage with a change, the
  allocation range with the unknown share. The briefing template in
  `inst/rmarkdown/templates/briefing` draws only from the profile and the
  exported chart functions.
* Keep sampling intervals separate from assumption uncertainty. Do not infer
  discrimination from the descriptive ratio.

## Tests

Use hand-calculated fixtures for mathematical correctness, corruption cases for
data contracts, and saved-view round trips for compatibility. Test examples and
vignettes offline. Do not access live police services in tests, examples or load
hooks. Do not write to user files from examples; use `tempfile()` and clean up.

Dashboard parity is a separate developer check requiring the local public
aggregate files and `data.table`. The packaged unit tests do not require that
workspace, Shiny or any restricted dataset. `dev/verify-dashboard.R` verifies
the four source-file hashes before comparing results.

## Verification

```r
roxygen2::roxygenise()
testthat::test_local()
```

From a shell, with R available:

```text
Rscript --vanilla dev/verify-dashboard.R <path to the dashboard workspace>
Rscript --vanilla dev/reproduce.R
R CMD build .
R CMD check --as-cran BlackThriveSS_*.tar.gz
```

`dev/verify-dashboard.R` compares the package's tables with the dashboard's
own calculation functions, including all eligible ratios and all three
ranking orders. It evaluates only the dashboard's calculation functions and
does not start the website or alter its data. The packaged tests use
hand-calculated fixtures, cover missing returns, zero counts and excluded
denominators, reject changed provenance, and exercise saved-view replay,
bounds, rank intervals, change, trends, profiles, exports and the briefing.
Parity validates reproduction, not the original data's completeness or all
of the dashboard's statistical assumptions.

`data-raw/build-snapshot.R` and `data-raw/build-catalogue.R` create
content-identified releases from the dashboard files. Existing release
directories are never overwritten, and input and output checksums are
recorded in the manifest. Updating the source or method requires a new
release; it must not silently change an archived chart.

The [GitHub Actions checks](https://github.com/BlackThrive/BlackThriveSS/actions/workflows/R-CMD-check.yaml)
cover Windows, macOS, Linux and several R versions, and the pkgdown workflow
rebuilds the documentation site from `main`.

## Release workflow

1. Update version and NEWS, regenerate help and run tests.
2. Build with `dev/build-release.R`; this executes the vignettes and creates the
   source archive plus installation ZIP under `artifacts/`. Run
   `dev/check-release.R` for the local check, which needs rcmdcheck and, for
   the PDF manual, LaTeX.
3. In a fresh process, test `install.R` into a new writable library. Exercise
   quickstart, package citation, validation, and the installed vignette.
4. Run `dev/check-release.R` and review its complete log and every note. Associate
   all evidence with the archive SHA-256 in `release.dcf`.
5. Run the CI matrix once a repository is established. Current R-devel and
   release checks are separate from the workstation's installed R version.
6. Complete the release gates in `dev/CRAN-READINESS.md` and finalise
   `cran-comments.md`. Submission is a separate deliberate maintainer action.

The development bundle is a convenience installer; it is not part of the CRAN
source package. No upload or public publication occurs in the build/check scripts.
