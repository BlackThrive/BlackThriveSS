# Requires an installed BlackThriveSS package; no network or dashboard needed.
library(BlackThriveSS)

# Discover the bundled datasets and their fixed source releases.
btg_datasets()
btg_releases()

# Reproduce the 2025 Black:White force ranking.
x <- btg_get_data()
p <- btg_plot_disparity(x)
print(p)

# Retrieve editable tables and explicit provenance.
head(btg_figure_data(p))
btg_get_data(force = "metropolitan")$data
head(btg_coverage(x))
btg_metadata(x)$source
btg_citation(x)

# Recreate the included evidence specification exactly.
path <- system.file("examples", "disparity-2025.json", package = "BlackThriveSS")
replayed <- btg_from_view(path)
stopifnot(identical(btg_figure_data(p), btg_figure_data(replayed)))

# Any year and group from the catalogue, and the link to the same view online.
y <- btg_get_data("force_ethnicity_year")
q <- btg_plot_disparity(y, year = 2024, group = "Asian", highlight = "metropolitan")
print(q)
btg_dashboard_url(q)
stopifnot(identical(btg_figure_data(btg_from_url(btg_dashboard_url(q))), btg_figure_data(q)))

# To save your own view:
# btg_save_view(p, "my-view.json")
# btg_from_view("my-view.json")
