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
writeLines(capture.output(sessionInfo()), "artifacts/session-info.txt")
writeLines(btg_citation(x), "artifacts/citation.txt")
cat("Chart, data, coverage and replayable view written to artifacts/.\n")
