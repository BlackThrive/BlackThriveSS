# Run from the BlackThriveSS directory after installing the package.
# Rscript --vanilla dev/reproduce.R
if (dir.exists("artifacts/library")) .libPaths(c(normalizePath("artifacts/library"), .libPaths()))
library(BlackThriveSS)
dir.create("artifacts", showWarnings = FALSE)
x <- btg_get_data()
p <- btg_plot_disparity(x)
ggplot2::ggsave("artifacts/black-white-disparity-2025.png", p,
                width = 11.5, height = 7.5, dpi = 160, bg = "white")
utils::write.csv(btg_figure_data(p), "artifacts/chart-data.csv", row.names = FALSE, na = "NA")
utils::write.csv(x$coverage, "artifacts/reporting-coverage.csv", row.names = FALSE, na = "NA")
btg_save_view(p, "artifacts/disparity-2025.json", overwrite = TRUE)
replayed <- btg_from_view("artifacts/disparity-2025.json")
stopifnot(identical(btg_figure_data(p), btg_figure_data(replayed)))
y <- btg_get_data("force_ethnicity_year")
ggplot2::ggsave("artifacts/black-white-sensitivity-2025.png", btg_plot_sensitivity(x),
                width = 11.5, height = 7.5, dpi = 160, bg = "white")
ggplot2::ggsave("artifacts/metropolitan-trend.png",
                btg_plot_trend(btg_get_data("force_ethnicity_year", force = "metropolitan")),
                width = 11, height = 6.5, dpi = 160, bg = "white")
ggplot2::ggsave("artifacts/black-white-change-2024-2025.png", btg_plot_change(y),
                width = 11.5, height = 7, dpi = 160, bg = "white")
utils::write.csv(btg_sensitivity(x), "artifacts/sensitivity-2025.csv", row.names = FALSE, na = "NA")
utils::write.csv(btg_rank_stability(x), "artifacts/rank-stability-2025.csv", row.names = FALSE, na = "NA")
if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available("2.0")) {
  btg_report(force = "metropolitan", file = "artifacts/briefing-metropolitan-2025.html", overwrite = TRUE)
}
writeLines(capture.output(sessionInfo()), "artifacts/session-info.txt")
writeLines(btg_citation(x), "artifacts/citation.txt")
cat("Charts, tables, briefing, coverage and replayable view written to artifacts/.\n")
