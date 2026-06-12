#================================ Pacakges ================================

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


#================================ Setup ================================

# Set target options:
tar_option_set(
  packages = libs # Packages needed for tasks
)

# Run the R scripts in the R/ folder with functions
tar_source("R/tka-functions.R")
# tar_source(R/bd_functions.R)


#================================ Targets ================================

# Define a list with targets. Order does not matter
list(

  ## List all TKA files in destination folder ====
  tar_target(
    tka_files,
    list.files("_data", pattern = "\\.TKA$", full.names = TRUE)
  ),
  
  ## Energy calibrate each file (one branch per file) ====
  tar_target(
    spectra,
    energy_cal_tka(tka_files),
    pattern = map(tka_files),
    iteration = "list"
  ),
  
  ## Combine all into one dataframe ====
  tar_target(
    all_spectra,
    bind_rows(spectra)
  )
)

ggplot(data= tar_read(all_spectra), aes(x = kev, y = counts)) +
  geom_line(linewidth = 0.3) +
  facet_wrap(~file, ncol = 1) +
  theme_minimal()


#================================ Run Targets ================================
  
# tar_visnetwork()

# tar_make()

# tar_meta(fields = error, complete_only = TRUE)

# tar_read()
