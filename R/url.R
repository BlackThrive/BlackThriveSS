# Round trip between a chart and the dashboard's shareable links.
#
# The dashboard describes a view in its URL. Every deployed version reads the
# per-parameter form (`?tab=disparity&year=2025&eth=Black&def=std&view=chart&
# force=Metropolitan%20Police`); newer builds also write a JSON `state`
# parameter (`?tab=disparity&v=1&state={...}&release=2026-07`). This file
# writes either form and reads both. Links select a view; they never carry
# numbers, so a link is reproduced from the bundled snapshot and the result
# is as fixed as any other chart from this package.

.dashboard_groups <- c("Black", "Asian", "Mixed", "Other")

#' The public address of the dashboard
#'
#' Returns the base URL that [btg_dashboard_url()] links to. Set the option
#' `BlackThriveSS.dashboard_url` to point at another deployment, such as a
#' preview build.
#' @return A single URL ending in a slash.
#' @export
#' @examples
#' btg_dashboard_base()
btg_dashboard_base <- function() {
  base <- getOption("BlackThriveSS.dashboard_url",
                    "https://bgtresearch-stop-search-dashboard.share.connect.posit.cloud/")
  .scalar_string(base, "BlackThriveSS.dashboard_url")
  sub("/*$", "/", base)
}

.view_from_plot <- function(p) {
  view <- attr(p, "btg_view", exact = TRUE)
  if (is.null(view)) stop("No BlackThriveSS view on this plot.", call. = FALSE)
  if (!identical(view$chart, "force_disparity_ranking")) {
    stop("Only the force ranking chart has a dashboard page.", call. = FALSE)
  }
  view
}

.force_label <- function(force) {
  if (is.null(force) || is.na(force)) return(NULL)
  d <- btg_get_data("force_ethnicity_year", years = 2025L, groups = "Black")$data
  label <- d$force_label[match(force, d$force)]
  if (is.na(label)) stop("Unknown force identifier ", force, ".", call. = FALSE)
  label
}

.encode_query <- function(values) {
  values <- values[!vapply(values, is.null, logical(1))]
  paste(names(values), vapply(values, function(v) utils::URLencode(as.character(v), reserved = TRUE), character(1)),
        sep = "=", collapse = "&")
}

#' Link a chart to the same view on the dashboard
#'
#' Builds the dashboard address that opens the Disparity page at the year,
#' group, display and selected force a chart was drawn from. The link selects
#' a view on the live website; it does not freeze the numbers, which the
#' website recomputes from its current release. The chart's own numbers stay
#' pinned in the saved view and the package snapshot.
#'
#' @param p A plot from [btg_plot_disparity()], [btg_from_view()] or
#'   [btg_from_url()].
#' @param format `"parameters"` (the default) writes the per-parameter form
#'   that every deployed dashboard version reads; `"state"` writes the newer
#'   JSON state form, which also carries the ranking order and the source
#'   month the chart came from.
#' @param base The dashboard address; see [btg_dashboard_base()].
#' @return A single URL.
#' @details The dashboard page defaults to its map view with the chart beneath;
#'   links from this function ask for the chart view. The ranking order is
#'   only carried by the `"state"` form. A `highlight` force becomes the
#'   page's selected force.
#' @export
#' @examples
#' p <- btg_plot_disparity(highlight = "metropolitan")
#' btg_dashboard_url(p)
#' btg_dashboard_url(p, format = "state")
btg_dashboard_url <- function(p, format = c("parameters", "state"), base = btg_dashboard_base()) {
  format <- match.arg(format)
  view <- .view_from_plot(p)
  .scalar_string(base, "base")
  focus <- .force_label(view$highlight)
  group <- view$group %||% "Black"
  query <- if (format == "parameters") {
    .encode_query(list(tab = "disparity", year = view$year, eth = group, def = "std",
                       view = "chart", force = focus))
  } else {
    state <- list(year = as.integer(view$year), eth = group, def = "std", view = "chart",
                  ranking_view = view$ranking)
    if (!is.null(focus)) state[["_focus"]] <- focus
    manifest <- .release(view$release)
    .encode_query(list(tab = "disparity", v = "1",
                       state = jsonlite::toJSON(state, auto_unbox = TRUE),
                       release = manifest$source$latest_month))
  }
  paste0(sub("/*$", "/", base), "?", query)
}

.parse_query <- function(url) {
  .scalar_string(url, "url")
  if (nchar(url) > 8192L) stop("The link is too long to be a dashboard view.", call. = FALSE)
  query <- sub("^[^?]*\\??", "", sub("#.*$", "", url))
  if (!nzchar(query)) return(list())
  parts <- strsplit(strsplit(query, "&", fixed = TRUE)[[1]], "=", fixed = TRUE)
  values <- lapply(parts, function(kv) if (length(kv) > 1L) utils::URLdecode(paste(kv[-1], collapse = "=")) else "")
  names(values) <- vapply(parts, function(kv) utils::URLdecode(kv[1]), character(1))
  values[!duplicated(names(values))]
}

#' Reproduce the chart behind a dashboard link
#'
#' Reads a link copied from the dashboard's Share view button, or any address
#' of its Disparity page, and draws the same comparison from the bundled
#' snapshot: the year, the group compared with White, the ranking order and the
#' selected force. Both link forms the dashboard has used are understood.
#'
#' @param url A dashboard link. Only the Disparity page (`tab=disparity`) is
#'   supported; the expanded Black definition (`def=exp`) is not, because it
#'   rests on self-defined ethnicity the package does not bundle.
#' @param n Maximum number of displayed forces, as in [btg_plot_disparity()].
#' @return A ggplot with its evidence table and saved view, exactly as
#'   [btg_plot_disparity()] returns. The source month named in the link, if
#'   any, is compared with the snapshot's and a warning is raised when they
#'   differ.
#' @details Fields the dashboard would ignore are ignored here too, with a
#'   warning where that changes what is drawn. Links never execute code or
#'   trigger downloads.
#' @export
#' @examples
#' btg_from_url("https://example.org/?tab=disparity&year=2024&eth=Asian&view=chart")
#' link <- btg_dashboard_url(btg_plot_disparity(ranking = "closest"), format = "state")
#' btg_from_url(link)
btg_from_url <- function(url, n = 10L) {
  q <- .parse_query(url)
  tab <- q$tab %||% "cover"
  if (!identical(tab, "disparity")) {
    stop("Only Disparity page links (tab=disparity) can be reproduced; this link opens ",
         tab, ".", call. = FALSE)
  }
  if (!is.null(q$state)) {
    if (!identical(q$v, "1") || nchar(q$state) > 8000L) stop("Unsupported dashboard view version.", call. = FALSE)
    state <- tryCatch(jsonlite::fromJSON(q$state, simplifyVector = TRUE),
                      error = function(e) stop("Invalid dashboard view state.", call. = FALSE))
    if (!is.list(state) || is.data.frame(state)) stop("Invalid dashboard view state.", call. = FALSE)
    fields <- list(year = state$year, eth = state$eth, def = state$def, view = state$view,
                   ranking = state$ranking_view, force = state[["_focus"]])
  } else {
    fields <- list(year = q$year, eth = q$eth, def = q$def, view = q$view,
                   ranking = NULL, force = q$force)
  }
  scalar <- function(v) if (is.null(v) || length(v) != 1L || is.na(v)) NULL else v
  fields <- lapply(fields, scalar)
  if (!is.null(fields$def) && !identical(fields$def, "std")) {
    stop("The expanded Black definition (def=exp) uses self-defined ethnicity, which this package does not bundle.", call. = FALSE)
  }
  x <- btg_get_data("force_ethnicity_year")
  years <- unique(x$data$year)
  year <- suppressWarnings(as.integer(fields$year))
  if (is.null(fields$year)) {
    year <- .default_chart_year(x)
  } else if (is.na(year) || !year %in% years) {
    stop("The link asks for year ", fields$year, ", which the snapshot does not hold.", call. = FALSE)
  }
  group <- fields$eth %||% "Black"
  if (!group %in% .dashboard_groups) stop("Unknown group ", group, " in the link.", call. = FALSE)
  ranking <- fields$ranking %||% "highest"
  if (!ranking %in% c("highest", "lowest", "closest")) {
    warning("Unknown ranking order ", ranking, " in the link; showing the highest ratios.", call. = FALSE)
    ranking <- "highest"
  }
  highlight <- NULL
  if (!is.null(fields$force)) {
    forces <- unique(x$data[c("force", "force_label")])
    highlight <- forces$force[match(fields$force, forces$force_label)]
    if (is.na(highlight)) {
      # the dashboard's own label, allowing for "Police" or "Constabulary" suffixes
      stem <- function(v) gsub("[^a-z]", "", sub(" (police service|police|constabulary)$", "", tolower(v)))
      highlight <- forces$force[match(stem(fields$force), stem(forces$force_label))]
    }
    if (is.na(highlight)) {
      warning("The link selects ", fields$force, ", which is not a force in the snapshot; no force is highlighted.", call. = FALSE)
      highlight <- NULL
    }
  }
  if (!is.null(q$release) && !identical(q$release, x$metadata$source$latest_month)) {
    warning("The link was made from source month ", q$release, "; this snapshot holds ",
            x$metadata$source$latest_month, ". The view is reproduced from the snapshot.", call. = FALSE)
  }
  btg_plot_disparity(x, n = n, ranking = ranking, year = year, group = group, highlight = highlight)
}
