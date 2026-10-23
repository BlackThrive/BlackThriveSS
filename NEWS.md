# BlackThriveSS 0.1.0

* Robustness analysis. `btg_sensitivity()` bounds every ratio under the two
  extreme allocations of stops with no recorded ethnicity and reports
  `parity_direction` and the best and worst rank each force could hold;
  `btg_rank_stability()` gives seeded rank intervals and top-n probabilities
  from Poisson redraws of the recorded counts, leaving the caller's random
  number state untouched; `btg_plot_sensitivity()` draws the ranking chart's
  forces with their sampling interval and allocation range on a log axis.
  Sampling variability and assumption ranges are never combined.
* Time. `btg_plot_trend()` draws a force's or council's ratios or rates over
  the years, national monthly stops or shares, national totals and rates,
  outcome-linked search rates and Section 60 searches, with incomplete
  periods marked and never annualised; `btg_change()` compares two years with
  an interval and the coverage of both; `btg_plot_change()` is a dumbbell
  chart of the largest changes. `btg_group_colours()` gives every group a
  fixed colour.
* Briefings. `btg_profile()` gathers the evidence for one force or council
  as plain statements that carry their qualifications, grouped under topic
  headings, with the tables behind them; `btg_report()` renders the briefing
  from the installed R Markdown template "BlackThriveSS briefing", which the
  editors also list under new R Markdown templates, as a self-contained web
  page, a Word document or a PDF. The briefing opens with an at-a-glance
  panel and headline findings by topic, numbers its tables and figures, and
  sets tables with `btg_table()`: styled in HTML by the template's
  stylesheet, in Word by a reference document carrying the package's fonts,
  colours and table style, and in PDF with booktabs rules. Figures fill
  the text width of A4 pages, as vector graphics in PDF and at print
  resolution in Word, and carry only their coverage note inside the image
  because the briefing states sources and qualifications itself;
  `options(BlackThriveSS.caption = "short")` does the same for any chart.
* The package now lists its five authors, with ORCID identifiers where held,
  in `DESCRIPTION` and the citation.
* Documentation. The package has a logo, and its website opens with an
  overview for first-time users: what the package gives, a gallery of its
  charts, a quick start and who it is for, with a light and dark theme. The
  README is shorter and points to the site; the developer workflow moved to
  `CONTRIBUTING.md`, and the CRAN readiness notes to `dev/`. The citation
  names Black Thrive Global as the organisation and gives the site address.
* Sharing. `btg_export()` writes a dataset to CSV with a JSON provenance
  sidecar; `btg_glossary()` defines every term the package uses.
* Auditing the source. `btg_source_status()` reads the Police.uk
  availability feed and reports months published since the snapshot and any
  force-month inside the verified window that has been added or withdrawn;
  it is the package's only use of the network and fails quietly with a
  message. `btg_robustness_summary()` gives one row per year and group with
  the counts a study of robustness starts from.
* Saved views gain schema 3, which carries a dataset selection and a chart's
  settings, so trend and change charts replay like the ranking charts; the
  sensitivity chart replays through schema 2. Earlier views are unchanged.
  The default year for comparisons is now the latest year the source covers
  in full for every dataset, including councils.
* Two new vignettes, "How robust is a disparity estimate?" and "Brief a force
  or council", and a pkgdown site configuration.
* Help pages are now generated with roxygen2 8.1; the package help page lists
  the repository and issue tracker at
  <https://github.com/BlackThrive/BlackThriveSS>, which `DESCRIPTION` records.

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
