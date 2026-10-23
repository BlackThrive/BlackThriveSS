# Render an HTML briefing for one force or council

Writes a self-contained HTML briefing from the package's installed R
Markdown template: the headline statements of
[`btg_profile()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_profile.md),
the ranking, robustness, trend and change charts for the area, the
tables behind them, reporting coverage, the methods and their limits,
and the citation and release identifiers needed to reproduce every
figure.

## Usage

``` r
btg_report(
  force = NULL,
  council = NULL,
  year = NULL,
  release = NULL,
  file,
  format = NULL,
  overwrite = FALSE,
  draws = 2000L,
  seed = 1L
)
```

## Arguments

- force:

  A Police.uk force identifier such as `"metropolitan"`, or

- council:

  an ONS local-authority code such as `"E09000022"`. Name one of the
  two.

- year:

  The calendar year to profile. `NULL` uses the latest year the source
  covers in full.

- release:

  A value from
  [`btg_releases()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_releases.md);
  `NULL` uses the default catalogue release.

- file:

  Path of the file to write.

- format:

  `"html"` for a self-contained web page, or `"docx"` for a Word
  document with the same content. `NULL` takes the format from the
  file's extension.

- overwrite:

  Whether to replace an existing file.

- draws, seed:

  Simulation settings passed to
  [`btg_rank_stability()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_rank_stability.md).

## Value

The path of the written file, invisibly.

## Details

Rendering needs the `rmarkdown` package and Pandoc, which RStudio and
Positron supply; the function stops with a clear message when they are
missing. The template is also available in those editors as the R
Markdown template "BlackThriveSS briefing" for editing.

## Examples

``` r
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available("2.0")) {
  path <- tempfile(fileext = ".html")
  btg_report(force = "metropolitan", file = path, draws = 500)
  unlink(path)
}
# }
```
