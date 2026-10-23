# BlackThriveSS <img src="https://blackthrive.github.io/BlackThriveSS/reference/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/BlackThrive/BlackThriveSS/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/BlackThrive/BlackThriveSS/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/BlackThrive/BlackThriveSS/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/BlackThrive/BlackThriveSS/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**Stop and search evidence for England and Wales that you can reproduce,
check and share, in R.**

BlackThriveSS packages the public evidence behind the Black Thrive stop and
search dashboard: fixed, checksummed datasets for every police force and
council from 2018 onwards, the dashboard's charts as editable ggplots,
robustness checks that keep sampling variability apart from assumptions,
and one-call briefings in HTML, Word or PDF. Everything runs offline after
installation, and every number says where it came from.

Documentation, guides and the function reference are at
**<https://blackthrive.github.io/BlackThriveSS/>**.

## Install

BlackThriveSS is not on CRAN yet. Install the current release from GitHub
with R 4.1 or newer:

```r
install.packages("remotes")
remotes::install_github("BlackThrive/BlackThriveSS")
```

The package contains no compiled code. Briefings in HTML and Word need
Pandoc, which RStudio and Positron include; PDF briefings also need a LaTeX
installation such as TinyTeX.

## Quick start

```r
library(BlackThriveSS)

x <- btg_get_data("force_disparity", years = 2025)   # the fixed 2025 Black:White comparison
p <- btg_plot_disparity(x, n = 10)                    # the dashboard's ranking chart
btg_figure_data(p)                                    # the table behind it
btg_sensitivity(x)                                    # bounds under unknown ethnicity
btg_report(force = "metropolitan", file = "metropolitan-2025.docx")   # a Word briefing
```

<img src="https://blackthrive.github.io/BlackThriveSS/reference/figures/home-ranking.png" alt="Bar chart of the ten highest Black to White stop-rate ratios by police force in 2025, with intervals and coverage marks" width="100%">

## What it gives you

| | |
|---|---|
| **Data that stays put** | Seven datasets, pinned to a named release with SHA-256 checksums, monthly reporting coverage and a ready-made citation: `btg_datasets()`, `btg_get_data()`, `btg_validate()`, `btg_citation()`. |
| **The dashboard's charts, editable** | The force ranking for any year and group as an ordinary ggplot, with intervals, coverage marks and a highlighted force: `btg_plot_disparity()`, `btg_figure_data()`. |
| **Robustness, kept honest** | Sampling intervals, bounds under every allocation of unknown ethnicity and rank intervals, reported side by side and never combined: `btg_sensitivity()`, `btg_rank_stability()`, `btg_plot_sensitivity()`, `btg_robustness_summary()`. |
| **Nine years of change** | Ratios and rates over time for any force or council, national monthly series and Section 60 searches, with incomplete periods marked: `btg_plot_trend()`, `btg_change()`, `btg_plot_change()`. |
| **A briefing in one call** | Plain statements that carry their qualifications, and a styled HTML, Word or PDF briefing with numbered tables and page-width figures: `btg_profile()`, `btg_report()`, `btg_table()`. |
| **Replay and share** | Saved views that replay a chart exactly, links that round-trip to the dashboard website, and exports with a provenance sidecar: `btg_save_view()`, `btg_from_view()`, `btg_dashboard_url()`, `btg_from_url()`, `btg_export()`. |

<img src="https://blackthrive.github.io/BlackThriveSS/reference/figures/home-sensitivity.png" alt="Chart of ten forces showing the sampling interval and the range of each ratio under every allocation of unknown-ethnicity stops" width="100%">

## Learn more

* [Reproduce and validate a dashboard chart](https://blackthrive.github.io/BlackThriveSS/articles/getting-started.html):
  discover the datasets, draw and customise the ranking chart, save and
  replay a view, and validate a release.
* [How robust is a disparity estimate?](https://blackthrive.github.io/BlackThriveSS/articles/robustness.html):
  bounds under unknown ethnicity, rank intervals, change with coverage, and
  the methods in one place.
* [Brief a force or council](https://blackthrive.github.io/BlackThriveSS/articles/briefing.html):
  plain statements, the briefing in three formats, and exports.
* [Function reference](https://blackthrive.github.io/BlackThriveSS/reference/index.html).

## Read the numbers with care

The ratios compare recorded stops with Census 2021 resident populations.
They are descriptive event rates, not the probability that a person will be
stopped, and they do not on their own establish discrimination.
Officer-defined ethnicity differs from Census self-reported ethnicity, the
aggregate cannot separate vehicle-only searches, and some forces supply
incomplete monthly returns, which the package marks rather than hides.
`btg_glossary()`, the robustness guide and every dataset's metadata set out
these limits.

## Cite

```r
citation("BlackThriveSS")   # the package
btg_citation(x)             # the data release behind an object
```

## Contributing

Bug reports and suggestions are welcome through
[GitHub issues](https://github.com/BlackThrive/BlackThriveSS/issues); please
include your R version, the package version and a small reproducible
example. [CONTRIBUTING.md](CONTRIBUTING.md) describes the development
workflow and the rules that keep the evidence reproducible.

## Attribution

Code: MIT, Black Thrive Global. Data: Police.uk stop and search records and
Office for National Statistics Census 2021 populations, prepared by the
dashboard pipeline from the July 2026 Police.uk source release. Contains
public sector information licensed under the [Open Government Licence
v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
