An R package from Black Thrive Global

Stop and search evidence you can reproduce

Fixed, checksummed releases of public Police.uk and Census data for
every police force and council in England and Wales, with the charts,
robustness checks and briefings that turn them into evidence that stands
up to scrutiny.

[Get
started](https://blackthrive.github.io/BlackThriveSS/articles/getting-started.md)
[Install](#install) [Open the
dashboard](https://bgtresearch-stop-search-dashboard.share.connect.posit.cloud/)

![BlackThriveSS logo](reference/figures/logo.png)

44police forces

355councils

9years of monthly data, 2018 to 2026

7datasets, one citation each

## What it gives you

### Data that stays put

Seven datasets, pinned to a named release with SHA-256 checksums,
monthly reporting coverage and a ready-made citation. A chart made today
matches the same chart made next year.

### The dashboard’s charts, editable

Recreate the force ranking for any year and group as an ordinary ggplot,
with intervals, coverage marks and a highlighted force. Every chart
carries its own table.

### Robustness, kept honest

Sampling intervals, bounds under every allocation of unknown ethnicity
and rank intervals are reported side by side and never combined, so a
reader can see what a comparison rests on.

### Nine years of change

Ratios and rates over time for any force or council, national monthly
series and Section 60 searches, with incomplete periods marked and
nothing annualised.

### A briefing in one call

Plain statements that carry their own qualifications, and a styled HTML,
Word or PDF briefing for one force or council, with numbered tables,
page-width figures and the code to reproduce them.

### Replay and share

Saved views replay a chart with identical numbers. Links round-trip to
the dashboard website. Exports carry a provenance sidecar so a CSV still
says where its numbers came from.

## See it

[![Bar chart of the ten highest Black to White stop-rate ratios by
police force in 2025, with intervals and coverage
marks](reference/figures/home-ranking.png)](https://blackthrive.github.io/BlackThriveSS/reference/figures/home-ranking.png)

The dashboard’s ranking chart for any year and group, with 95% intervals
and marks for incomplete returns.

[![Chart of the same ten forces showing the sampling interval and the
range of each ratio under every allocation of unknown-ethnicity
stops](reference/figures/home-sensitivity.png)](https://blackthrive.github.io/BlackThriveSS/reference/figures/home-sensitivity.png)

How robust each ratio is: the sampling interval beside the range it
could take if every unknown-ethnicity stop were reassigned.

[![Line chart of stop-rate ratios for the Metropolitan Police from 2018
to 2026 for four ethnic groups compared with White
residents](reference/figures/home-trend.png)](https://blackthrive.github.io/BlackThriveSS/reference/figures/home-trend.png)

Ratios over nine years for one force, with hollow markers where the year
is incomplete.

[![Dumbbell chart of the ten largest changes in Black to White stop-rate
ratios between 2024 and 2025 by police
force](reference/figures/home-change.png)](https://blackthrive.github.io/BlackThriveSS/reference/figures/home-change.png)

The largest year-on-year changes, each with an interval and the coverage
of both years.

## Install

BlackThriveSS is not on CRAN yet. Install the current release from
GitHub with R 4.1 or newer:

``` r

install.packages("remotes")
remotes::install_github("BlackThrive/BlackThriveSS")
```

The package contains no compiled code and runs offline after
installation. Briefings in HTML and Word need Pandoc, which RStudio and
Positron include; PDF briefings also need a LaTeX installation such as
TinyTeX.

## Quick start

``` r

library(BlackThriveSS)

x <- btg_get_data("force_disparity", years = 2025)   # the fixed 2025 Black:White comparison
p <- btg_plot_disparity(x, n = 10)                    # the dashboard's ranking chart
btg_figure_data(p)                                    # the table behind it
btg_sensitivity(x)                                    # bounds under unknown ethnicity
btg_report(force = "metropolitan", file = "metropolitan-2025.docx")   # a Word briefing
```

Three guides take it from there: [reproduce and validate a
chart](https://blackthrive.github.io/BlackThriveSS/articles/getting-started.md),
[test how robust a comparison
is](https://blackthrive.github.io/BlackThriveSS/articles/robustness.md)
and [brief a force or
council](https://blackthrive.github.io/BlackThriveSS/articles/briefing.md).
The [function
reference](https://blackthrive.github.io/BlackThriveSS/reference/index.md)
documents every call.

## Who it is for

### Researchers

Tidy data frames with provenance, documented calculations behind every
number, and views and exports that let someone else reproduce a result
exactly.

### Policy and scrutiny

One call writes the evidence for an area as careful plain statements,
with the methods and their limits attached, ready for a scrutiny panel
or a consultation response.

### Community organisations

Charts with your force or council highlighted, a glossary with one
definition per term, and a link that opens the same view on the
dashboard website.

## Read the numbers with care

The ratios compare recorded stops with Census 2021 resident populations.
They are descriptive event rates, not the probability that a person will
be stopped, and they do not on their own establish discrimination.
Officer-defined ethnicity differs from Census self-reported ethnicity,
the aggregate cannot separate vehicle-only searches, and some forces
supply incomplete monthly returns, which the package marks rather than
hides. The
[glossary](https://blackthrive.github.io/BlackThriveSS/reference/btg_glossary.md),
the [robustness
guide](https://blackthrive.github.io/BlackThriveSS/articles/robustness.md)
and every dataset’s metadata set out these limits.

## Cite it

``` r

citation("BlackThriveSS")   # the package
btg_citation(x)             # the data release behind an object
```

Code: MIT, Black Thrive Global. Data: Police.uk stop and search records
and Office for National Statistics Census 2021 populations, which
contain public sector information licensed under the [Open Government
Licence
v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
