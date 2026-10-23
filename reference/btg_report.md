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

  `"html"` for a self-contained web page, `"docx"` for a Word document
  or `"pdf"` for a PDF, all with the same content. `NULL` takes the
  format from the file's extension.

- overwrite:

  Whether to replace an existing file.

- draws, seed:

  Simulation settings passed to
  [`btg_rank_stability()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_rank_stability.md).

## Value

The path of the written file, invisibly.

## Details

Rendering needs the `rmarkdown` package and Pandoc, which RStudio and
Positron supply, and a PDF additionally needs a LaTeX installation such
as TinyTeX
([`tinytex::install_tinytex()`](https://rdrr.io/pkg/tinytex/man/install_tinytex.html));
the function stops with a clear message when any is missing. Paragraphs
are justified and the body text is 12-point Calibri in HTML and Word;
the PDF uses Calibri too, through XeLaTeX, when the machine has that
font or its open counterpart Carlito, and LaTeX's default face
otherwise. Tables are set with
[`btg_table()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_table.md),
Word output uses the styled reference document installed with the
template, and PDF output uses booktabs tables. Charts in a briefing
carry only their coverage note, because the briefing states the sources
and qualifications itself; the option `BlackThriveSS.caption = "short"`
does the same for any chart. Figures are drawn at page width, as vector
graphics in PDF and at print resolution in Word, on A4 pages. The
template is also available in those editors as the R Markdown template
"BlackThriveSS briefing" for editing, where Knit to HTML, Word or PDF
gives the same three outputs.

## Examples

``` r
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available("2.0")) {
  path <- tempfile(fileext = ".html")
  btg_report(council = "E09000022", file = path, draws = 200)   # Lambeth
  unlink(path)
}
# }
```
