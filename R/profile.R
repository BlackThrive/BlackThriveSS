# A structured evidence profile for one force or council: the numbers behind
# a briefing, with plain statements that carry their own qualifications, and
# an HTML briefing rendered from the installed R Markdown template.

.fmt <- function(x, digits = 1) {
  format(round(x, digits), nsmall = digits, big.mark = ",", trim = TRUE, scientific = FALSE)
}
.fmt_count <- function(x) format(x, big.mark = ",", trim = TRUE, scientific = FALSE)
.ordinal <- function(n) {
  suffix <- ifelse(n %% 100 %in% 11:13, "th",
                   c("th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th")[n %% 10 + 1])
  paste0(n, suffix)
}
.pick_year <- function(x, year) {
  if (is.null(year)) return(.default_chart_year(x))
  if (!is.numeric(year) || length(year) != 1L || is.na(year) || !year %in% x$data$year) {
    stop("year must be one calendar year the dataset holds.", call. = FALSE)
  }
  as.integer(year)
}
.month_name <- function(ym) format(as.Date(paste0(ym, "-01")), "%B")

.profile_caveats <- c(
  "Rates divide recorded stop and search events by Census 2021 resident populations. They are event rates, not the probability that an individual is stopped, and residents are a proxy for the people present in an area.",
  "Ethnicity is as perceived by the officer; Census ethnicity is self-reported. The two classifications differ, and stops with no recorded ethnicity are excluded from the ratio but shown separately.",
  "Intervals describe sampling variability on the recorded counts only. They do not capture missing monthly returns, classification differences or the choice of denominator.",
  "A ratio, rank or change is descriptive. It does not establish discrimination, and it does not separate recording practice, who is present in an area and policing decisions.",
  "Supplied returns are not proof of complete recording. Missing months are shown as missing, never as zero, and counts for incomplete periods are not annualised.")

#' Build an evidence profile for one force or council
#'
#' Gathers, for one area and one year, everything the package can say with
#' its bundled evidence: each group's recorded stops, rate per 1,000 residents
#' and ratio to White residents with its interval; the force's rank among
#' eligible forces, how much sampling variability moves that rank
#' ([btg_rank_stability()]) and how far the allocation of unknown-ethnicity
#' stops could move the ratio ([btg_sensitivity()]); the change since the
#' previous year ([btg_change()]); monthly reporting coverage; Section 60
#' searches; and national context. Each finding is also written as a plain
#' statement that carries its own qualification, ready for a briefing.
#'
#' @param force A Police.uk force identifier such as `"metropolitan"`, or
#' @param council an ONS local-authority code such as `"E09000022"`. Name
#'   one of the two.
#' @param year The calendar year to profile. `NULL` uses the latest year the
#'   source covers in full.
#' @param release A value from [btg_releases()]; `NULL` uses the default
#'   catalogue release.
#' @param draws,seed Simulation settings passed to [btg_rank_stability()].
#' @return A list of class `btg_profile` with `area`, `year`, `release`,
#'   `source_month`, `comparisons` (one row per group), `stability` (forces
#'   only), `change`, `coverage` (forces only), `section60` (forces only),
#'   `national`, `statements`, `topics` and `caveats`. Each statement is
#'   named by its topic (`coverage`, a group, `section60` or `national`), and
#'   `topics` gives the heading for each, which [btg_report()] and the print
#'   method use to group the statements.
#' @details Ranks, rank intervals and allocation bounds are computed against
#'   every force in the release, not only the profiled one. Councils carry no
#'   rank, eligibility or coverage, as in the dataset, and their counts depend
#'   on published stop coordinates.
#' @export
#' @examples
#' p <- btg_profile(force = "metropolitan", draws = 500)
#' p
#' p$comparisons[c("group", "ratio", "rank", "rank_lower", "rank_upper", "parity_direction")]
btg_profile <- function(force = NULL, council = NULL, year = NULL, release = NULL,
                        draws = 2000L, seed = 1L) {
  if (is.null(force) == is.null(council)) stop("Name one force or one council.", call. = FALSE)
  level <- if (is.null(force)) "council" else "force"
  if (identical(level, "force")) {
    .scalar_string(force, "force")
    x <- btg_get_data("force_ethnicity_year", force = force, release = release)
  } else {
    .scalar_string(council, "council")
    x <- btg_get_data("council_ethnicity_year", council = council, release = release)
  }
  year <- .pick_year(x, year)
  release <- x$metadata$release
  source_month <- x$metadata$source$latest_month
  id <- x$data[[level]][1]
  label <- x$data[[paste0(level, "_label")]][1]
  area <- list(level = level, id = id, label = label,
               pfa_code = if (identical(level, "force")) x$data$pfa_code[1] else NA_character_)
  rows <- x$data[x$data$year == year, ]
  rows <- rows[order(match(rows$group, c("Black", "Asian", "Mixed", "Other"))), ]
  every <- btg_get_data(x$selection$dataset, years = year, release = release)
  sens <- btg_sensitivity(every)
  sens <- sens[sens[[level]] == id, ]
  sens <- sens[match(rows$group, sens$group), ]
  comparisons <- data.frame(
    group = rows$group, group_stops = rows$group_stops, white_stops = rows$white_stops,
    group_population = rows$group_population, white_population = rows$white_population,
    group_rate = rows$group_rate, white_rate = rows$white_rate,
    ratio = rows$ratio, ci_lower = rows$ci_lower, ci_upper = rows$ci_upper,
    ratio_min = sens$ratio_min, ratio_max = sens$ratio_max, parity_direction = sens$parity_direction,
    unknown_ethnicity_stops = rows$unknown_ethnicity_stops, total_records = rows$total_records,
    unknown_share = sens$unknown_share, stringsAsFactors = FALSE)
  stability <- NULL
  if (identical(level, "force")) {
    comparisons$eligible <- rows$eligible
    comparisons$rank <- rows$rank
    comparisons$rank_best <- sens$rank_best
    comparisons$rank_worst <- sens$rank_worst
    eligible_counts <- tapply(every$data$eligible, every$data$group, sum)
    comparisons$n_eligible <- as.integer(eligible_counts[comparisons$group])
    if (any(every$data$eligible)) {
      stability <- btg_rank_stability(every, draws = draws, seed = seed)
      mine <- stability[stability$force == id, ]
      m <- match(comparisons$group, mine$group)
      comparisons$rank_lower <- mine$rank_lower[m]
      comparisons$rank_upper <- mine$rank_upper[m]
      comparisons$prob_top <- mine$prob_top[m]
    }
  }
  change <- if (year > min(x$data$year)) btg_change(x, from = year - 1L, to = year) else NULL
  if (!is.null(change)) change <- change[match(rows$group, change$group), ]
  coverage <- NULL
  if (identical(level, "force")) {
    months <- x$coverage[substr(x$coverage$month, 1, 4) == year, ]
    coverage <- list(status = rows$coverage_status[1], months_supplied = rows$months_supplied[1],
                     months_missing = rows$months_missing[1], months_unverified = rows$months_unverified[1],
                     months_in_source = rows$months_in_source[1], months = months)
  }
  section60 <- NULL
  if (identical(level, "force")) {
    s60 <- tryCatch(btg_get_data("section60_force_year", force = id, years = year, release = release)$data,
                    error = function(e) NULL)
    if (!is.null(s60)) section60 <- s60[c("group", "s60_stops")]
  }
  national_year <- btg_get_data("national_year", years = year, release = release)$data
  hit <- btg_get_data("hit_rate_ethnicity_year", years = year, release = release)$data
  national <- list(year = national_year, hit_rate = hit[c("group", "hit_yes", "hit_total", "hit_rate")])
  statements <- .profile_statements(area, year, source_month, comparisons, change, coverage, section60, national)
  topics <- unique(names(statements))
  structure(list(area = area, year = year, release = release, source_month = source_month,
                 comparisons = comparisons, stability = stability, change = change,
                 coverage = coverage, section60 = section60, national = national,
                 statements = statements,
                 topics = data.frame(topic = topics, heading = .statement_headings(topics, level),
                                     stringsAsFactors = FALSE),
                 caveats = .profile_caveats),
            class = "btg_profile")
}

.profile_statements <- function(area, year, source_month, comparisons, change, coverage, section60, national) {
  out <- character()
  add <- function(topic, text) out <<- c(out, stats::setNames(text, topic))
  force <- identical(area$level, "force")
  months_in_source <- if (as.integer(substr(source_month, 1, 4)) == year) as.integer(substr(source_month, 6, 7)) else 12L
  period <- if (months_in_source < 12L) {
    sprintf("the first %d months of %d (to %s)", months_in_source, year, .month_name(source_month))
  } else as.character(year)
  if (force && !is.null(coverage)) {
    add("coverage", switch(coverage$status,
      all_months_supplied = sprintf("%s supplied stop and search returns for all 12 months of %d.", area$label, year),
      partial_year = {
        missing <- coverage$months[coverage$months$status == "missing", "month"]
        sprintf("%s supplied returns for %d of 12 months of %d; %s missing (%s). Counts for the year cover the supplied months only and are not annualised.",
                area$label, coverage$months_supplied, year, if (length(missing) == 1L) "one month is" else paste(length(missing), "months are"),
                paste(.month_name(missing), collapse = ", "))
      },
      no_months_supplied = sprintf("%s has no supplied returns for %d in this release; its counts for the year are missing, not zero.", area$label, year),
      unverified = sprintf("Monthly submissions for %d lie outside the window the dashboard verifies, so %s's counts are as published and their completeness is unverified.", year, area$label)))
  }
  if (!force) {
    add("coverage", sprintf("%s's counts are located by published stop coordinates, which some forces withhold, so they undercount and carry no rank or display rule.", area$label))
  }
  for (i in seq_len(nrow(comparisons))) {
    r <- comparisons[i, ]
    if (!is.finite(r$ratio)) {
      if (is.na(r$group_stops)) next
      add(r$group, sprintf("No resident-based %s:White comparison is available for %s in %s.", r$group, area$label, period))
      next
    }
    if (r$group_stops == 0) {
      add(r$group, sprintf("No stops of %s people were recorded under officer-defined ethnicity in %s; White residents were stopped at %s per 1,000.",
                           r$group, period, .fmt(r$white_rate)))
    } else {
      sentence <- sprintf("Recorded stops of %s people in %s: %s per 1,000 %s residents, %sx the rate for White residents (%s per 1,000)",
                          r$group, period, .fmt(r$group_rate), r$group, .fmt(r$ratio), .fmt(r$white_rate))
      if (is.finite(r$ci_lower)) sentence <- sprintf("%s, 95%% interval %sx to %sx", sentence, .fmt(r$ci_lower), .fmt(r$ci_upper))
      sentence <- sprintf("%s, from %s and %s recorded stops.", sentence, .fmt_count(r$group_stops), .fmt_count(r$white_stops))
      add(r$group, sentence)
    }
    if (force && isTRUE(r$eligible) && !is.na(r$rank)) {
      rank_sentence <- sprintf("That %s:White ratio ranks %s of %d forces with an eligible comparison", r$group, .ordinal(r$rank), r$n_eligible)
      if (!is.null(r$rank_lower) && !is.na(r$rank_lower)) {
        rank_sentence <- sprintf("%s; sampling variability alone puts the rank between %d and %d", rank_sentence, r$rank_lower, r$rank_upper)
      }
      add(r$group, paste0(rank_sentence, "."))
    } else if (force && !is.na(r$group_stops)) {
      add(r$group, sprintf("The %s:White comparison does not meet the dashboard's display rule (a positive ratio from at least 200 stops with known ethnicity and comparable resident populations), so it carries no rank.", r$group))
    }
    if (is.finite(r$ratio_min) && is.finite(r$ratio_max) && r$unknown_ethnicity_stops > 0 && r$group_stops > 0) {
      add(r$group, sprintf("%s of the %s recorded stops in %s (%s%%) have no recorded ethnicity. Counting every one of them as White would put the %s:White ratio at %sx; counting every one as %s would put it at %sx. %s",
                            .fmt_count(r$unknown_ethnicity_stops), .fmt_count(r$total_records), period, .fmt(100 * r$unknown_share),
                            r$group, .fmt(r$ratio_min), r$group, .fmt(r$ratio_max),
                            switch(r$parity_direction,
                                   above = "The ratio stays above parity under every allocation.",
                                   below = "The ratio stays below parity under every allocation.",
                                   sensitive = "Which side of parity the ratio falls on depends on those stops.")))
    }
    if (!is.null(change)) {
      ch <- change[i, ]
      if (is.finite(ch$change)) {
        direction <- if (ch$change >= 1) "higher" else "lower"
        pct <- .fmt(100 * abs(ch$change - 1), 0)
        sentence <- sprintf("Compared with %d, the %s:White ratio in %d was %s%% %s", ch$year_from, r$group, ch$year_to, pct, direction)
        if (is.finite(ch$change_lower)) {
          sentence <- sprintf("%s (95%% interval %sx to %sx the earlier ratio%s)", sentence, .fmt(ch$change_lower, 2), .fmt(ch$change_upper, 2),
                              if (identical(ch$change_direction, "unclear")) ", which includes no change" else "")
        }
        sentence <- if (isTRUE(ch$comparable_coverage)) paste0(sentence, "; both years are covered in full.") else
          paste0(sentence, "; returns do not cover both years in full, so this comparison is indicative only.")
        add(r$group, sentence)
      }
    }
  }
  if (force && !is.null(section60) && nrow(section60)) {
    total <- sum(section60$s60_stops, na.rm = TRUE)
    black <- section60$s60_stops[section60$group == "Black"]
    sentence <- sprintf("%s recorded %s searches under Section 60 in %s", area$label, .fmt_count(total), period)
    if (length(black) == 1L && total > 0) sentence <- sprintf("%s, %s%% of them of Black people", sentence, .fmt(100 * black / total, 0))
    add("section60", paste0(sentence, "."))
  }
  ny <- national$year
  if (nrow(ny) == 1L) {
    hit <- national$hit_rate
    black_hit <- hit$hit_rate[hit$group == "Black"]
    white_hit <- hit$hit_rate[hit$group == "White"]
    sentence <- sprintf("Across England and Wales, %s stops were recorded in %s; %s%% led to an arrest", .fmt_count(ny$stops), period, .fmt(ny$arrest_rate))
    if (length(black_hit) == 1L && length(white_hit) == 1L) {
      sentence <- sprintf("%s, and the share of searches whose outcome was linked to what was searched for was %s%% for Black people and %s%% for White people", sentence, .fmt(black_hit), .fmt(white_hit))
    }
    add("national", paste0(sentence, "."))
  }
  out
}

# Headings for the topics that name a profile's statements.
.statement_headings <- function(topics, level = "force") {
  groups <- c(Black = "Black people compared with White residents",
              Asian = "Asian people compared with White residents",
              Mixed = "Mixed people compared with White residents",
              Other = "People of other ethnic groups compared with White residents")
  fixed <- c(coverage = if (identical(level, "force")) "Reporting coverage" else "About council counts",
             section60 = "Section 60 searches", national = "National context")
  headings <- c(fixed, groups)
  unname(headings[topics])
}

#' @export
print.btg_profile <- function(x, ...) {
  cat("BlackThriveSS evidence profile: ", x$area$label, ", ", x$year, "\n",
      "Release ", x$release, " (source month ", x$source_month, ")\n", sep = "")
  topics <- unique(names(x$statements))
  for (topic in topics) {
    cat("\n", .statement_headings(topic, x$area$level), "\n", sep = "")
    for (s in x$statements[names(x$statements) == topic]) {
      cat(strwrap(s, width = 78, prefix = "  ", initial = "* "), sep = "\n")
    }
  }
  cat("\nTables: $comparisons, $change, $coverage, $section60, $national; qualifications: $caveats\n")
  invisible(x)
}

#' Render an HTML briefing for one force or council
#'
#' Writes a self-contained HTML briefing from the package's installed
#' R Markdown template: the headline statements of [btg_profile()], the
#' ranking, robustness, trend and change charts for the area, the tables
#' behind them, reporting coverage, the methods and their limits, and the
#' citation and release identifiers needed to reproduce every figure.
#'
#' @inheritParams btg_profile
#' @param file Path of the file to write.
#' @param format `"html"` for a self-contained web page, `"docx"` for a Word
#'   document or `"pdf"` for a PDF, all with the same content. `NULL` takes
#'   the format from the file's extension.
#' @param overwrite Whether to replace an existing file.
#' @return The path of the written file, invisibly.
#' @details Rendering needs the `rmarkdown` package and Pandoc, which
#'   RStudio and Positron supply, and a PDF additionally needs a LaTeX
#'   installation such as TinyTeX (`tinytex::install_tinytex()`); the
#'   function stops with a clear message when any is missing. Paragraphs are
#'   justified and the body text is 12-point Calibri in HTML and Word; the
#'   PDF uses Calibri too, through XeLaTeX, when the machine has that font or
#'   its open counterpart Carlito, and LaTeX's default face otherwise. Tables
#'   are set with [btg_table()], Word output uses the styled reference
#'   document installed with the template, and PDF output uses booktabs
#'   tables. The
#'   template is also available in those editors as the R Markdown template
#'   "BlackThriveSS briefing" for editing, where Knit to HTML, Word or PDF
#'   gives the same three outputs.
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available("2.0")) {
#'   path <- tempfile(fileext = ".html")
#'   btg_report(force = "metropolitan", file = path, draws = 500)
#'   unlink(path)
#' }
#' }
btg_report <- function(force = NULL, council = NULL, year = NULL, release = NULL, file,
                       format = NULL, overwrite = FALSE, draws = 2000L, seed = 1L) {
  .scalar_string(file, "file")
  format <- format %||% if (grepl("[.]docx$", file, ignore.case = TRUE)) "docx" else
    if (grepl("[.]pdf$", file, ignore.case = TRUE)) "pdf" else "html"
  if (!is.character(format) || length(format) != 1L || !format %in% c("html", "docx", "pdf")) {
    stop("format must be html, docx or pdf.", call. = FALSE)
  }
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    stop("overwrite must be TRUE or FALSE.", call. = FALSE)
  }
  if (file.exists(file) && !overwrite) stop("File exists; use overwrite = TRUE.", call. = FALSE)
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Install the rmarkdown package to render briefings.", call. = FALSE)
  }
  if (!rmarkdown::pandoc_available("2.0")) {
    stop("Pandoc 2.0 or later is needed to render briefings; RStudio and Positron include it, or set RSTUDIO_PANDOC.", call. = FALSE)
  }
  if (identical(format, "pdf") && !.latex_available()) {
    stop("A LaTeX installation is needed for PDF briefings. Install TinyTeX with tinytex::install_tinytex(), or choose html or docx.", call. = FALSE)
  }
  if (is.null(force) == is.null(council)) stop("Name one force or one council.", call. = FALSE)
  skeleton <- system.file("rmarkdown", "templates", "briefing", "skeleton", package = "BlackThriveSS")
  if (!nzchar(skeleton) || !file.exists(file.path(skeleton, "skeleton.Rmd"))) {
    stop("The briefing template is missing from this installation.", call. = FALSE)
  }
  work <- tempfile("btg-briefing-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  # the template's stylesheet and Word reference document travel with it
  file.copy(list.files(skeleton, full.names = TRUE), work)
  input <- file.path(work, "skeleton.Rmd")
  output_format <- switch(format, html = "html_document", docx = "word_document", pdf = "pdf_document")
  output_options <- if (identical(format, "pdf")) .pdf_font_options() else NULL
  output <- rmarkdown::render(
    input, output_format = output_format, output_options = output_options,
    output_file = paste0("briefing.", format), output_dir = work, quiet = TRUE,
    envir = new.env(parent = asNamespace("BlackThriveSS")),
    params = list(force = force, council = council, year = year, release = release,
                  draws = draws, seed = seed))
  if (!file.copy(output, file, overwrite = TRUE)) stop("Could not write ", file, ".", call. = FALSE)
  invisible(file)
}

# Body text in Calibri, as in the HTML and Word briefings, when XeLaTeX and the
# font (or Carlito, its metric-compatible open counterpart) are available.
.pdf_font_options <- function() {
  if (!nzchar(Sys.which("xelatex"))) return(NULL)
  font <- if (.Platform$OS.type == "windows") "Calibri" else {
    fc <- Sys.which("fc-list")
    if (!nzchar(fc)) return(NULL)
    families <- tryCatch(suppressWarnings(system2(fc, c(":", "family"), stdout = TRUE, stderr = FALSE)),
                         error = function(e) character())
    if (any(grepl("^Calibri", families))) "Calibri" else if (any(grepl("^Carlito", families))) "Carlito" else NULL
  }
  if (is.null(font)) return(NULL)
  list(latex_engine = "xelatex", pandoc_args = c("-V", paste0("mainfont=", font)))
}

.latex_available <- function() {
  nzchar(Sys.which("pdflatex")) || nzchar(Sys.which("xelatex")) ||
    (requireNamespace("tinytex", quietly = TRUE) && isTRUE(tinytex::is_tinytex()))
}

#' Set a table for a briefing or report
#'
#' Formats a data frame for the document being knitted, in the style the
#' package's briefings use: an HTML table that the briefing stylesheet lays
#' out, a Word table that takes the reference document's table style, or a
#' booktabs table in PDF. Numeric columns are right-aligned and text columns
#' left-aligned unless `align` says otherwise. Outside a knitting session it
#' returns a plain Markdown table.
#'
#' @param x A data frame.
#' @param caption Optional caption.
#' @param align Optional alignment string or vector as [knitr::kable()] takes
#'   it, one letter per column.
#' @param digits Number of decimal places for numeric columns.
#' @return A `knitr_kable` object, printed by knitr into the document; in PDF
#'   the table is set one size smaller than the text.
#' @export
#' @examples
#' btg_table(head(btg_get_data("national_year")$data[c("year", "stops", "arrest_rate")]),
#'           caption = "National totals")
btg_table <- function(x, caption = NULL, align = NULL, digits = 1) {
  if (!is.data.frame(x)) stop("x must be a data frame.", call. = FALSE)
  if (!requireNamespace("knitr", quietly = TRUE)) stop("Install the knitr package to set tables.", call. = FALSE)
  align <- align %||% ifelse(vapply(x, is.numeric, logical(1)), "r", "l")
  if (knitr::is_latex_output()) {
    table <- knitr::kable(x, format = "latex", caption = caption, align = align, digits = digits,
                          booktabs = TRUE, linesep = "", escape = TRUE, position = "H")
    # one size smaller than the text, still a kable so that knitr and print() treat it as one
    structure(paste0("\\begingroup\\small\n", paste(table, collapse = "\n"), "\n\\endgroup\n"),
              format = "latex", class = "knitr_kable")
  } else if (knitr::is_html_output()) {
    knitr::kable(x, format = "html", caption = caption, align = align, digits = digits,
                 escape = TRUE, table.attr = "class=\"btg-table\"")
  } else {
    knitr::kable(x, format = "pipe", caption = caption, align = align, digits = digits)
  }
}
