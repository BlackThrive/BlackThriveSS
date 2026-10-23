# Submission comments for BlackThriveSS 0.1.0

This is a first submission. BlackThriveSS bundles fixed, checksummed snapshots
of public aggregate stop and search evidence used by the Black Thrive
dashboard (force, council and national tables from 2018 onwards with monthly
reporting coverage), reproduces the dashboard's charts as editable ggplots,
bounds every ratio under the allocation of stops with unknown ethnicity,
reports rank intervals, trends and year-on-year change, writes plain-language
profiles and briefings in HTML, Word or PDF, replays saved chart
specifications and exchanges links with the dashboard website. It works
offline after installation.

## Test environments

* Ubuntu 24.04, R 4.6.1: `R CMD check --as-cran` on the submission archive,
  with examples including `\donttest`, tests, vignette rebuilds and the PDF
  manual. Result: 0 errors, 0 warnings, 1 note. The note reports that HTML
  Tidy is not installed on that machine, so HTML manual validation was
  skipped; it does not concern the package.
* GitHub Actions on the same source: Windows (R release), macOS (R release),
  Ubuntu (R devel, R release, R oldrel-1 and R 4.1), each running
  `R CMD check --as-cran --no-manual` with the workflow set to fail on any
  warning. Result: status OK on every platform.
* `urlchecker::url_check()`: every URL in the package resolves.
* `spelling::spell_check_package()`: clean against the package word list,
  which records technical terms such as Poisson, Pandoc and ggplot.

## R CMD check results

0 errors, 0 warnings, 0 notes attributable to the package.

## Examples, tests and size

* Every example runs in under five seconds. The briefing example, which
  renders an HTML document with Pandoc, is wrapped in `\donttest` and is
  skipped when rmarkdown or Pandoc is unavailable.
* Tests take about 45 seconds. One network test runs only when the
  maintainer sets `BLACKTHRIVESS_NETWORK_TESTS=true`; nothing in the
  package's examples, tests or vignettes uses the network otherwise.
* The source archive is 2.6 MB: about 0.8 MB of compressed CSV holding
  public aggregates, plus five PNG figures used by the README and
  documentation site.

## Data and runtime behaviour

Only public aggregates and their monthly reporting coverage are bundled; no
credentials, dashboard session or restricted records are needed or used.
Examples and tests write only to `tempfile()` paths and remove them. The
package changes no global options or graphics parameters without restoring
them on exit, and `btg_rank_stability()` restores the caller's random-number
state after its seeded draws. `btg_dashboard_url()` builds a URL string
without fetching it; `btg_source_status()` is the only function that reads
from the network, it is never called by examples or tests, and it returns
`NULL` with a message when the feed cannot be read.

Package code is released under MIT. The bundled data are derived from
Police.uk stop and search records and Office for National Statistics Census
2021 populations, which contain public sector information licensed under the
Open Government Licence v3.0, as stated in `DESCRIPTION`, the data dictionary
and `btg_citation()`.

## Authors

The five authors are named in `DESCRIPTION` and `inst/CITATION`, with ORCID
identifiers where held. Black Thrive Global is the copyright holder and
funder. The maintainer's address is the one that will confirm the
submission.
