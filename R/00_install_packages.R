packages_needed <- c(
  "tidyverse",
  "lubridate",
  "scales",
  "ggridges",
  "modelr",
  "zoo",
  "broom"
)

missing_packages <- packages_needed[!packages_needed %in% installed.packages()[, "Package"]]

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}
