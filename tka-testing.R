#================================ Setup ================================

# Clear environment
rm(list = ls(all.names = TRUE))

# libraries needed
libs <- c("httr", "jsonlite", "ggplot2", "terra", "leaflet", "ncdf4", "tidyr", "dplyr", "readr", "targets", "usethis", "sf", "targets", "visNetwork", "tarchetypes", "tidyterra", "performance", "see", "RColorBrewer", "lme4", "nlme", "readxl", "writexl", "emmeans", "splines", "lspline", "ggeffects", "lubridate", "cowplot", "gridGraphics", "broom", "DT", "flextable", "wesanderson", "ggspatial", "extrafont")

# install missing libraries
installed_libs <- libs %in% rownames(installed.packages())
if (any(installed_libs == F)) {
  install.packages(libs[!installed_libs])
}

# load libraries
lapply(libs, library, character.only = T)

#================================ X ================================


# Read the file - each line is one value
raw <- readLines("C:/Users/natha/Box/_data/_fallout_radionuclides/Popeye_CAM-TKA/Popeye_CAM-TKA/260311_NL_Popeye_LR-ref-0-5_Marinelli_24hr.TKA")
raw <- readLines("C:/Users/natha/Box/_data/_fallout_radionuclides/Popeye_CAM-TKA/Popeye_CAM-TKA/260312_NL_Popeye_LR-ref-5-10_Marinelli_24hr.TKA")

values <- as.numeric(raw)

# First two values are typically live time and real time (seconds)
live_time <- values[1]
real_time <- values[2]

# Remaining values are counts per bin
counts <- values[3:length(values)]

# Create data frame
df <- data.frame(
  bin = seq_along(counts),
  counts = counts
)

# Plot
ggplot(df, aes(x = bin, y = counts)) +
  geom_line(linewidth = 0.3) +
  labs(
    x = "Channel",
    y = "Counts",
    title = "LR-ref-0-5 Marinelli 24hr Spectrum",
    subtitle = paste0("Live time: ", round(live_time), "s | Real time: ", round(real_time), "s")
  ) +
  theme_minimal()