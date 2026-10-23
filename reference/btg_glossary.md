# The terms BlackThriveSS uses

Definitions of the measures and labels that appear in the package's
datasets, charts and briefings, for readers who need to know exactly
what a word means before they quote a number.

## Usage

``` r
btg_glossary()
```

## Value

A data frame with `term` and `definition`.

## Examples

``` r
btg_glossary()
#>                                  term
#> 1                      recorded stops
#> 2           officer-defined ethnicity
#> 3                   unknown ethnicity
#> 4            rate per 1,000 residents
#> 5                               ratio
#> 6                        95% interval
#> 7                    allocation range
#> 8                            eligible
#> 9                                rank
#> 10                           coverage
#> 11                         unverified
#> 12                       partial year
#> 13                   months in source
#> 14                         Section 60
#> 15 outcome linked to object of search
#> 16                            release
#> 17                         saved view
#>                                                                                                                                                                                                             definition
#> 1                                                                                   Stop and search events recorded by a force and published by Police.uk. Events, not people: one person stopped twice is two events.
#> 2                                              The ethnic group the officer recorded for the person stopped. It is compared with Census ethnicity, which people report for themselves; the two classifications differ.
#> 3                                             Recorded stops with no officer-defined ethnic group. They are left out of ratios but counted separately, and the allocation range shows how far they could move a ratio.
#> 4                              Recorded stops of a group divided by the group's Census 2021 resident population, times 1,000. Residents are a proxy for the people present in an area, not a measure of who was there.
#> 5                       A group's rate per 1,000 residents divided by the White rate. 1x is parity; 4x means four times the recorded rate of White residents. It is descriptive and does not establish discrimination.
#> 6                                                    An approximate Poisson interval on the recorded counts. It describes sampling variability only, not missing returns, classification or the choice of denominator.
#> 7                                 The ratio if every stop with unknown ethnicity were counted as White (lower end) or as the compared group (upper end). Any allocation of those stops gives a ratio inside the range.
#> 8                                  The dashboard's display rule: a positive, finite ratio from at least 200 stops with known ethnicity and comparable resident populations. It is not a measure of complete reporting.
#> 9                           Position among the eligible forces of the same year and group, ordered by ratio, with ties sharing the lower number. Rank intervals show how far sampling variability alone could move it.
#> 10                                                     Whether a force's monthly return for a month is supplied, missing or unverified. Supplied is not proof of complete recording; missing is never treated as zero.
#> 11                                                                                A month outside the window in which the dashboard checks submissions. Its counts are as published and its completeness is not known.
#> 12 A year with at least one supplied and at least one missing month. Counts cover the supplied months only and are not annualised; a ratio of two counts from the same months is not affected under uniform reporting.
#> 13                                                                                                          How many months of a calendar year the Police.uk source month covers. The final source year is incomplete.
#> 14                                                                          A search under Section 60 of the Criminal Justice and Public Order Act 1994, authorised for an area and time without individual suspicion.
#> 15             The share of searches with a known outcome whose outcome was linked to what the search was looking for, sometimes called the find rate. Forces that omit or machine-fill the field are voided upstream.
#> 16                                          An immutable, checksummed snapshot of the dashboard's aggregates. A new source month or method produces a new release identifier; existing releases are never overwritten.
#> 17                                                                                 A JSON file that pins a chart to a release, a selection and settings so that it replays with identical numbers. It carries no code.
btg_glossary()[btg_glossary()$term == "ratio", "definition"]
#> [1] "A group's rate per 1,000 residents divided by the White rate. 1x is parity; 4x means four times the recorded rate of White residents. It is descriptive and does not establish discrimination."
```
