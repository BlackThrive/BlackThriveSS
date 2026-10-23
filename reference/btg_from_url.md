# Reproduce the chart behind a dashboard link

Reads a link copied from the dashboard's Share view button, or any
address of its Disparity page, and draws the same comparison from the
bundled snapshot: the year, the group compared with White, the ranking
order and the selected force. Both link forms the dashboard has used are
understood.

## Usage

``` r
btg_from_url(url, n = 10L)
```

## Arguments

- url:

  A dashboard link. Only the Disparity page (`tab=disparity`) is
  supported; the expanded Black definition (`def=exp`) is not, because
  it rests on self-defined ethnicity the package does not bundle.

- n:

  Maximum number of displayed forces, as in
  [`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md).

## Value

A ggplot with its evidence table and saved view, exactly as
[`btg_plot_disparity()`](https://blackthrive.github.io/BlackThriveSS/reference/btg_plot_disparity.md)
returns. The source month named in the link, if any, is compared with
the snapshot's and a warning is raised when they differ.

## Details

Fields the dashboard would ignore are ignored here too, with a warning
where that changes what is drawn. Links never execute code or trigger
downloads.

## Examples

``` r
btg_from_url("https://example.org/?tab=disparity&year=2024&eth=Asian&view=chart")

link <- btg_dashboard_url(btg_plot_disparity(ranking = "closest"), format = "state")
btg_from_url(link)
```
