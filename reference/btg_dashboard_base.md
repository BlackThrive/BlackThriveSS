# The public address of the dashboard

Returns the base URL that
[`btg_dashboard_url()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_dashboard_url.md)
links to. Set the option `BlackThriveSS.dashboard_url` to point at
another deployment, such as a preview build.

## Usage

``` r
btg_dashboard_base()
```

## Value

A single URL ending in a slash.

## Examples

``` r
btg_dashboard_base()
#> [1] "https://bgtresearch-stop-search-dashboard.share.connect.posit.cloud/"
```
