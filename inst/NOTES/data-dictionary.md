# First dataset: force_disparity, calendar year 2025

One row per force (43 territorial police forces plus British Transport Police).
The pinned snapshot comes from the local `btg_stop_search_v9` dashboard, whose
source archive is July 2026 and whose aggregates were built in September 2026.
This is not a claim about the currently deployed website or newest available data.

| Column | Meaning |
|---|---|
| force, force_label | Police.uk identifier and dashboard display name |
| pfa_code | Dashboard police force area code; missing for BTP |
| year | Calendar reporting year, 2025 |
| black_stops, white_stops | Recorded events with the respective officer-defined ethnicity |
| known_ethnicity_stops | Events mapped to one of the dashboard's five known categories |
| unknown_ethnicity_stops | Events not mapped to a known category, including unknown/inapplicable ethnicity |
| total_records | All available events, known plus unknown ethnicity |
| black_population, white_population | Fixed Census 2021 resident populations assigned by the dashboard to the force area |
| black_rate, white_rate | Available group events per 1,000 group residents; not annualised for reporting gaps |
| ratio | Black rate divided by White rate |
| ci_lower, ci_upper | Dashboard-style 95% Poisson log-ratio interval for positive counts |
| small_population | White resident population below 50,000, the dashboard exclusion threshold |
| comparable | Resident-rate denominators pass the dashboard's limited eligibility rules; not a general comparability certification |
| eligible | Finite positive ratio, at least 200 known-ethnicity events and resident-rate eligibility |
| rank | Descending ratio rank among all eligible forces, with minimum rank for ties |
| months_supplied, months_missing, months_unverified | Submission counts out of 12 |
| coverage_status | all_months_supplied, partial_year, no_months_supplied or unverified |

`coverage` contains force, force_label, month, status (supplied/missing/unverified)
and records. Missing returns have `NA` records, including whole-force missing
years. A group count can legitimately be zero within an available force-year;
this is different from a missing force-year. A supplied month is not a guarantee
of complete event recording. CI values are missing for zero group counts and
non-comparable populations. Zero Black counts can give a zero ratio, but this
initial chart follows the dashboard rule that omits nonpositive ratios.

The public aggregate retains vehicle-only searches in the source totals; these
cannot be separated from this table. Do not call the unknown count a pure
ethnicity non-response measure or treat event counts as unique people. Census
ethnicity is self-reported; the stop counts use officer-defined ethnicity.

The ratio is descriptive and unadjusted. Fixed 2021 residents are an exposure
proxy, not a 2025 population forecast or the population present on the street.
The Poisson intervals exclude uncertainty from non-reporting, classifications,
population estimates, repeated stops and choices of exposure. The software does
not infer discrimination from a ratio or interpret a ranking as police conduct.

## Catalogue datasets

The catalogue release (`dashboard-2026-07-catalogue-…`) holds six further
datasets from the same dashboard build. Group comparison tables use generic
column names so that every group is read the same way: `group`, `group_stops`,
`white_stops`, `group_population`, `white_population`, `group_rate`,
`white_rate`, `ratio`, `ci_lower`, `ci_upper`, `small_population` and
`comparable` mean what the equivalent Black columns mean above.

| Dataset | Level | Years | Rows | Notes |
|---|---|---|---|---|
| force_ethnicity_year | force | 2018 to 2026 | force × year × group (Asian, Black, Mixed, Other) | Adds `eligible` and `rank` within each year and group, `months_in_source` and the coverage columns. The 2025 Black rows equal `force_disparity`. |
| national_year | national | 2018 to 2026 | one per year | Totals of stops, arrests, no further action (`nfa`), Section 60, under-18s (`minors`), strip searches and outcome-linked searches, with the dashboard's derived rates as percentages. |
| national_month_ethnicity | national | 2018 to 2026 | month × group, including `Unknown` | Recorded stops across reporting forces by month. |
| council_ethnicity_year | council | 2018 to 2026 | council × year × group | Local authority (`council` is the ONS code) counts located by stop coordinates; no display rule, rank or coverage. Undercounts where coordinates are withheld. |
| hit_rate_ethnicity_year | national | 2018 to 2026 | year × group, including `Unknown` | `hit_rate` is the percentage of searches with a known outcome whose outcome was linked to the object of search; forces that machine-fill or omit the field are voided upstream. |
| section60_force_year | force | 2018 to 2026 | force × year × group, including `Unknown` | Searches under Section 60 of the Criminal Justice and Public Order Act 1994. |

The catalogue coverage table spans every month from January of the first year
to the source month. The dashboard verifies submissions only from August 2023;
earlier months are `unverified`, never assumed supplied, so every force is
`unverified` for years before 2024 and `months_in_source` is below 12 for the
final year. Derived doubles are stored to 12 significant figures.

## Provenance and licence

The manifest records SHA-256 checksums of four dashboard input files and both
bundled CSV files. The build script is `data-raw/build-snapshot.R` in the source
project. Full source RDS files and private local paths are not distributed.

Contains public sector information licensed under the [Open Government Licence
v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
Sources: [Police.uk](https://data.police.uk/about/) and [ONS Census
2021](https://www.nomisweb.co.uk/sources/census_2021), via the dashboard's population
preparation. Package code is MIT-licensed; that does not replace source-data terms.

## Derived tables

These functions compute from the bundled datasets; they add nothing to a
release and carry `dataset` and `release` attributes naming their evidence.

### `btg_sensitivity()`

One row per area, year and group of a comparison dataset.

| Column | Meaning |
|---|---|
| unknown_share | Unknown-ethnicity stops as a share of all records |
| ratio, ci_lower, ci_upper | The recorded ratio and its Poisson interval, as in the dataset |
| ratio_min | The ratio if every unknown-ethnicity stop were counted as White |
| ratio_max | The ratio if every unknown-ethnicity stop were counted in the compared group |
| parity_direction | `above` or `below` when the whole range is on one side of 1; `sensitive` when the side depends on the unknown stops; missing where the ratio is withheld |
| rank_best, rank_worst | Force rows: the rank if every force's unknown stops were allocated in this force's favour, or against it, among the forces eligible in the recorded data |

Any allocation of the unknown stops between the groups gives a ratio inside
the range; allocating them in the recorded proportions leaves it unchanged.
Bounds are withheld wherever the recorded ratio is withheld.

### `btg_rank_stability()`

One row per dashboard-eligible force, year and group. `rank_lower` and
`rank_upper` are the 2.5th and 97.5th percentiles of the rank across seeded
Poisson redraws of the group and White counts; `prob_top` is the share of
draws in which the force ranks within the top `top`. The attributes `draws`,
`seed` and `top` record the settings. This is sampling variability only.

### `btg_robustness_summary()`

One row per year and group of a force-level dataset: `forces` (with
counts), `eligible`, `above`, `below`, `sensitive` (eligible forces by
`parity_direction`), `median_unknown_share`, `max_unknown_share`,
`median_rank_interval` (upper minus lower rank percentile),
`settled_top` (forces with `prob_top` at or above `certain`),
`full_year_returns` and `months_in_source`.

### `btg_source_status()`

A comparison of the bundled coverage with the live Police.uk availability
feed: `newer_months` (months published after the snapshot and the forces
listed), `months` (per shared month: forces listed live, forces supplied in
the snapshot, late additions, withdrawals) and `changes` (each force-month
whose availability differs, with its bundled status). The feed describes
availability, not counts, and covers a rolling window of recent months.

### `btg_change()`

One row per area and group: `ratio_from`, `ratio_to`, `change` (later
divided by earlier), `change_lower`, `change_upper` (treating the four counts
as independent Poisson counts), `change_direction` (`higher`, `lower`,
`unclear`), the months each year is covered in the source, the coverage
status of both years for forces, and `comparable_coverage`, which is `TRUE`
only when both years are covered in full by supplied or unverified returns.

### `btg_figure_data()` of a trend chart

One row per period and series: `period` (year or `YYYY-MM`), `series`
(group, `White` for rates, or `England and Wales`), `value`, `lower`, `upper`
(ratios only), `complete` and `months_in_source`. A period is incomplete when
the source month does not cover it in full or, for forces, when returns are
missing.

### `btg_profile()`

A list for one area and year: `comparisons` (one row per group with the
columns above plus rank, `n_eligible`, `rank_lower`, `rank_upper` and
`prob_top` for forces), `stability`, `change`, `coverage` (status, monthly
counts and the month table), `section60`, `national` (the national year row
and the outcome-linked search rates by group), `statements` and `caveats`.

## Notes on this release

The catalogue lists an `Unknown` group for `national_month_ethnicity` and
`hit_rate_ethnicity_year`, but the bundled tables of this release carry no
`Unknown` rows: stops with no recorded ethnicity were not present in the
dashboard's national monthly and outcome aggregates. `section60_force_year`
does carry `Unknown` rows. Officer-defined `Mixed` counts are small
everywhere, because the police classification rarely records that group.
