# Inspect snapshot provenance

Inspect snapshot provenance

## Usage

``` r
btg_metadata(x)
```

## Arguments

- x:

  A dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).

## Value

An explicit list containing source attribution, checksums, definitions
and limitations. This is stored separately from table attributes.

## Examples

``` r
btg_metadata(btg_get_data())$source
#> $latest_month
#> [1] "2026-07"
#> 
#> $retrieved_at
#> [1] "2026-09-16T06:43:43.711698+00:00"
#> 
#> $availability_url
#> [1] "https://data.police.uk/api/crimes-street-dates"
#> 
#> $archive_url
#> [1] "https://policeuk-data.s3.amazonaws.com/archive/2026-07.zip"
#> 
#> $archive_sha256
#> [1] "312e3b1533ac953df07636781588578335113ef918584de4fcdfcb014a69ca16"
#> 
#> $source_last_modified
#> [1] "Thu, 03 Sep 2026 15:53:27 GMT"
#> 
```
