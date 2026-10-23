# Check the bundled snapshot against the live Police.uk source

Reads the Police.uk availability feed, which lists for each published
month the forces whose stop and search data are present, and compares it
with the bundled release: whether newer months have been published since
the snapshot's source month, and whether any force-month inside the
snapshot's verified coverage window has since been added (a late
submission) or withdrawn. This is the package's only use of the network;
it changes nothing and, when the feed cannot be read, returns `NULL`
with a message rather than an error.

## Usage

``` r
btg_source_status(release = NULL, timeout = 10, url = .availability_url)
```

## Arguments

- release:

  A value from
  [`btg_releases()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_releases.md);
  `NULL` uses the default catalogue release.

- timeout:

  Seconds to wait for the feed.

- url:

  The feed address, which the manifest also records.

## Value

`NULL` when the feed could not be read; otherwise a list of class
`btg_source_status` with `checked_at`, `snapshot_month`, `latest_month`,
`newer_months` (one row per month published after the snapshot with the
number of forces listed), `months` (one row per shared month: forces
listed live, forces supplied in the snapshot, late additions and
withdrawals) and `changes` (one row per force-month whose availability
differs, with the bundled status). Printing it summarises these.

## Details

The feed describes availability, not counts: a force listed for a month
has published some stop and search records for it. A late addition means
the source now holds a return the snapshot recorded as missing; a
withdrawal means the snapshot recorded a supplied return that the feed
no longer lists. Either is a reason to build a new release rather than
to edit this one. The feed covers a rolling window of recent months, so
months the snapshot verified before that window cannot be compared and
are not counted.

## Examples

``` r
# \donttest{
status <- btg_source_status(timeout = 5)
if (!is.null(status)) status
#> Police.uk source checked 2026-10-23T13:27:40Z
#> Bundled release dashboard-2026-07-catalogue-bacf49c2a48d holds source month 2026-07; the feed lists months to 2026-08.
#> 1 newer month(s): 2026-08 (28 forces).
#> Across 35 month(s) both describe (2023-09 to 2026-07): 3 late addition(s) and 0 withdrawal(s); see $changes.
# }
```
