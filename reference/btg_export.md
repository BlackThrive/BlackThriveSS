# Export a dataset with its provenance

Writes the rows of a dataset to a CSV file and, beside it, a JSON
sidecar that records the release, the source month, the SHA-256
checksums of the bundled payloads, the selection, the citation and the
documented limitations, so that a file passed on by email or attached to
a report still says exactly where its numbers came from.

## Usage

``` r
btg_export(x, path, overwrite = FALSE)
```

## Arguments

- x:

  A dataset from
  [`btg_get_data()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_get_data.md).

- path:

  Path of the CSV file to write. The sidecar takes the same name with
  the extension `.json`, and the monthly coverage table, when the
  dataset has one, the suffix `-coverage.csv`.

- overwrite:

  Whether to replace existing files.

## Value

A character vector of the written paths, invisibly.

## Examples

``` r
path <- tempfile(fileext = ".csv")
btg_export(btg_get_data(force = c("metropolitan", "kent")), path)
list.files(dirname(path), basename(sub("[.]csv$", "", path)))
#> [1] "file1ab35aa83601-coverage.csv" "file1ab35aa83601.csv"         
#> [3] "file1ab35aa83601.json"        
unlink(list.files(dirname(path), basename(sub("[.]csv$", "", path)), full.names = TRUE))
```
