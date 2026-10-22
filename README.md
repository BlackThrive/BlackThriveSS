# BlackThriveSS

An R package for reusing Black Thrive dashboard evidence. It bundles a
**catalogue of fixed, checksummed datasets** extracted from the dashboard
(force, council and national tables from 2018 onwards, with monthly reporting
coverage), reproduces the dashboard's **force ranking chart** for any year and
group as an editable ggplot, and **exchanges links with the dashboard website**
so that a chart in R and a view on the site describe the same thing.

The snapshots were extracted from `btg_stop_search_v9`. They use the local
dashboard's July 2026 Police.uk source release, built in September 2026, and
Census 2021 populations. The package does not query the live website; it and
its examples run offline without Shiny, Python or a database.

## The catalogue

```r
library(BlackThriveSS)
btg_datasets()
#   dataset                   level    from   to   groups                      coverage
#   force_disparity           force    2025 2025   Black                       TRUE
#   force_ethnicity_year      force    2018 2026   Asian, Black, Mixed, Other  TRUE
#   national_year             national 2018 2026                               FALSE
#   national_month_ethnicity  national 2018 2026   Asian, ..., White, Unknown  FALSE
#   council_ethnicity_year    council  2018 2026   Asian, Black, Mixed, Other  FALSE
#   hit_rate_ethnicity_year   national 2018 2026   Asian, ..., White, Unknown  FALSE
#   section60_force_year      force    2018 2026   Asian, ..., White, Unknown  TRUE

y <- btg_get_data("force_ethnicity_year", groups = "Black", years = 2022:2025)
y$data[c("force_label", "year", "ratio", "rank", "coverage_status")]
btg_get_data("council_ethnicity_year", council = "E09000022")$data   # Lambeth
btg_get_data("national_year")$data
```

Every dataset is read the same way, verified against its SHA-256 checksum,
and carries the release's provenance in `$metadata`. The 2025 Black rows of
`force_ethnicity_year` reproduce `force_disparity` exactly, which the tests
assert. The dashboard verifies monthly submissions only inside a recent window,
so earlier years are `unverified`, which is not the same as missing; a missing
return is always `NA`, never zero.

## Round-trip with the dashboard website

```r
p <- btg_plot_disparity(btg_get_data("force_ethnicity_year"),
                        year = 2024, group = "Asian", highlight = "metropolitan")
btg_dashboard_url(p)
#> https://.../?tab=disparity&year=2024&eth=Asian&def=std&view=chart&force=Metropolitan%20Police

back <- btg_from_url("https://.../?tab=disparity&year=2024&eth=Asian&view=chart&force=Metropolitan%20Police")
identical(btg_figure_data(back), btg_figure_data(p))
#> TRUE
```

`btg_dashboard_url()` opens the Disparity page at the chart's year, group and
selected force. `btg_from_url()` reproduces the chart behind any link copied
from the website's Share view button, in either link form the dashboard has
used, and warns when the link was made from a different source month than the
snapshot. A link selects a view; the website recomputes from its current
release, while the chart in R stays pinned to the bundled snapshot.

## Try it in R

Open `BlackThriveSS.Rproj` and run the following in a fresh R session. The
installer verifies the source archive, installs missing required dependencies
from CRAN, and puts the package into this project's `artifacts/library` folder.
It does not require devtools or a running dashboard.

```r
source("install.R")
install_blackthrivess()
library(BlackThriveSS)

x <- btg_get_data()
p <- btg_plot_disparity(x)
p

x$data                      # Ordinary data frame: all 44 forces
btg_figure_data(p)           # Original chart table, in display order
btg_coverage(x)              # 528 monthly reporting observations
btg_metadata(x)$source      # Source release, retrieval time and checksum
btg_citation(x)
btg_validate(x)              # Integrity, coverage and accounting checks
```

To share this development build for testing, use
`artifacts/BlackThriveSS-0.0.3-install.zip`. Extract it into a folder and follow
`START-HERE.txt`; the full development project is not needed. The archive and
manifest must stay together. This is a local release, not a published CRAN
package. Do not use `install.packages("BlackThriveSS")` yet.

For a different writable library, supply `lib = "/your/library"`. With all
required dependencies already available, `dependencies = FALSE` performs an
offline installation. The package itself contains no compiled code; source
installation of dependencies can need build tools. Prefer available CRAN binary
dependencies on Windows and macOS. No development packages are installed by the
installer.

When reopening R, enable the local library and load the package:

```r
.libPaths(c(normalizePath("artifacts/library"), .libPaths()))
library(BlackThriveSS)
vignette("getting-started", package = "BlackThriveSS")
```

The tutorial includes discovery, chart customisation, missing returns, a saved
view round trip, validation and troubleshooting. Full function help is available
with `help(package = "BlackThriveSS")`. Developers can instead use
`pkgload::load_all()` from the project folder.

Customise the returned ggplot or inspect one force:

```r
p + ggplot2::labs(title = "Recorded Black:White stop-rate comparison")
ggplot2::ggsave("disparity.png", p, width = 11.5, height = 7.5, dpi = 160)

met <- btg_get_data(force = "metropolitan")
met$data[c("black_stops", "white_stops", "black_population",
           "white_population", "ratio", "coverage_status")]

btg_plot_disparity(x, ranking = "lowest")
btg_plot_disparity(x, ranking = "closest")
```

The data object stores `data`, `coverage`, `metadata` and `selection` explicitly.
Analyse or transform `x$data` freely in your own workflow. The reproduction
functions reject altered evidence or provenance so custom calculations cannot
accidentally claim to be the fixed dashboard result.

## Save and reproduce the chart

```r
btg_save_view(p, "my-disparity-view.json")
recreated <- btg_from_view("my-disparity-view.json")
stopifnot(identical(btg_figure_data(p), btg_figure_data(recreated)))
recreated

# This example is installed with the package:
view <- system.file("examples", "disparity-2025.json", package = "BlackThriveSS")
btg_from_view(view)
```

The JSON file pins the data release, payload checksums, chart version and
selection. Unknown releases, schemas or checksums fail explicitly. Files never
execute R code or trigger downloads. Numerical reproduction is supported;
pixel-identical rendering requires the same graphics environment. Custom ggplot
styling and layers are not stored in the view.

## What is reproduced

The chart reproduces the force selection, ratios and ordering from the dashboard
Disparity page's **2025 / Standard groups / Black / Compare the distribution**
view. Highest, lowest and closest-to-parity orderings are supported. The output
uses the dashboard's colours in an editable static ggplot, with additional
coverage labels. It does not reproduce Plotly interactions, selected-force
highlighting or previous-year change annotations.

Forty forces have ratios eligible under the dashboard's display rules. British
Transport Police and City of London have no displayed resident-based rate.
Greater Manchester and Gwent have no submitted 2025 months in this snapshot;
their counts remain `NA`, not zero. Partial returns remain visible and are
marked with `*`; eligibility is not proof of complete reporting.

These are event rates using fixed 2021 resident populations, not probabilities
that an individual will be stopped. Officer-defined ethnicity and Census
self-reported ethnicity are different classifications. The table does not
separate vehicle-only searches, so unknown ethnicity is not a pure non-response
measure. These ratios do not establish discrimination. See the installed
`NOTES/data-dictionary.md` and the explicit metadata for definitions and limits.

## Development and verification

```r
roxygen2::roxygenise()
testthat::test_local()
```

From a shell, with R available:

```text
Rscript --vanilla dev/verify-dashboard.R ../btg_stop_search_v9
Rscript --vanilla dev/reproduce.R
R CMD build .
R CMD check --no-manual BlackThriveSS_0.0.3.tar.gz
```

`dev/verify-dashboard.R` compares 12 fields over the 42 dashboard source rows,
including all 40 eligible ratios, and all three ranking orders. It evaluates
only the dashboard's calculation functions and does not start the website or
alter its data. Tests also use hand-calculated fixtures, cover missing returns,
zero counts and excluded denominators, reject changed provenance, and exercise
saved-view replay. Parity validates reproduction, not the original data's
completeness or all of the dashboard's statistical assumptions.

`btg_validate()` checks the release checksums, monthly-to-annual totals, ethnicity
subtotals and stored estimates. These checks establish internal consistency, not
complete police reporting or the validity of every statistical assumption.

`data-raw/build-snapshot.R` creates a content-identified snapshot from four
dashboard files. Existing release directories are never overwritten. Input and
output checksums are recorded in the manifest. Updating the source or method
requires a new release; it must not silently change an archived chart.

## Build, validate and prepare for CRAN

The maintainer workflow is:

```text
Rscript --vanilla dev/build-release.R
Rscript --vanilla dev/check-release.R
```

Building the executed HTML tutorial needs knitr, rmarkdown and Pandoc. The local
check uses rcmdcheck and the R toolchain, including LaTeX for the PDF manual.
Those are maintainer tools, not runtime requirements for users. The build writes
a source archive, checksummed manifest and installation ZIP. The check records
the exact archive SHA-256, R version, errors, warnings and notes.

See `CRAN-READINESS.md` for the evidence and remaining release gates, and
`CONTRIBUTING.md` for development rules. `.github/workflows/R-CMD-check.yaml`
defines Windows, macOS, Linux and R-version checks; it is prepared but has not
run on an external repository. There are no claimed CI passes or CRAN acceptance.

The **Use in R dashboard button is deferred**. The current priorities are
installation, documentation, validation, release ownership and a supported
distribution route. A larger dataset catalogue and public release store can
follow once their contracts and maintenance arrangements are established.

This is a local development package. It has not been submitted to CRAN or
published, and it does not change the dashboard deployment.

## Attribution

Code: MIT, Black Thrive Global. Public aggregate data: Police.uk and Office for
National Statistics, Census 2021, via the dashboard preparation pipeline.
Contains public sector information licensed under the [Open Government Licence
v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).

Source documentation: [Police.uk](https://data.police.uk/about/) and
[Census 2021](https://www.nomisweb.co.uk/sources/census_2021).
