# BlackThriveSS (development version)

* The package now records its repository and issue tracker at
  <https://github.com/BlackThrive/BlackThriveSS> in `DESCRIPTION`.

# BlackThriveSS 0.0.3

* A dataset catalogue. A second immutable release adds six datasets built from
  the same dashboard snapshot: `force_ethnicity_year` (every year from 2018 and
  all four groups compared with White, reproducing the 2025 Black rows of
  `force_disparity` exactly), `national_year`, `national_month_ethnicity`,
  `council_ethnicity_year`, `hit_rate_ethnicity_year` and
  `section60_force_year`. `btg_datasets()` and `btg_releases()` describe them;
  `btg_get_data()` gains `groups` and `council` arguments and accepts several
  `years`; `btg_validate()` audits every dataset. The original 2025 release and
  its saved views are unchanged. Months outside the dashboard's verification
  window are `unverified`, never assumed supplied.
* A round trip with the dashboard website. `btg_dashboard_url()` turns a chart
  into the link that opens the Disparity page at the same year, group and
  selected force, in either link form the dashboard reads; `btg_from_url()`
  reproduces the chart behind a link copied from the website, warning when the
  link was made from a different source month. `btg_dashboard_base()` and the
  option `BlackThriveSS.dashboard_url` choose the deployment.
* `btg_plot_disparity()` draws any year and group from `force_ethnicity_year`
  and can `highlight` one force as the dashboard's selected force. Saved views
  move to schema 2 to carry the year, group and highlight; schema 1 files
  still replay.

* Redrew the ranking chart with a shared visual system. New exported
  `btg_theme()` and `btg_colours()` carry the dashboard's amber and navy into a
  quiet ggplot2 theme: hairline grid, titles aligned with the plot edge, thinner
  bars, a labelled parity line and finer axis breaks. Each bar now carries its
  95% Poisson interval, forces with incomplete or unverified returns are drawn in
  a lighter fill with a legend as well as the asterisk, and the subtitle states
  how many of the eligible forces are shown. The evidence table and saved-view
  format are unchanged.

# BlackThriveSS 0.0.2

* Added a portable installation bundle with dependency resolution and archive checksums.
* Added an installed, executable getting-started vignette and standard package citation.
* Added btg_validate() for accounting, reporting-coverage and estimate consistency.
* Added corrupt-data regression tests and source-checksum checks for dashboard parity.
* Added a multi-platform CI configuration, release scripts and a CRAN readiness checklist.
* Explicitly deferred the dashboard Use in R button.
* Preserved the existing fixed dataset release and saved-view format.

# BlackThriveSS 0.0.1

Initial development slice:

* One offline, immutable 2025 force-disparity dataset derived from the local dashboard.
* Black:White ranking chart returned as an editable ggplot, with chart data export.
* Monthly submission coverage, original counts and populations, source checksums,
  explicit limitations and dataset citation.
* Strict JSON saved views pin the release, selection, payload checksums and chart version.
* Dashboard parity and independent known-answer validation.

This is a local development package, not a CRAN release or hosted data service.
