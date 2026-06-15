#================================ Pacakges ================================

# Clear environment
rm(list = ls(all.names = TRUE))

?rm()

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
    #  list.files("_data", pattern = "\\.TKA$", full.names = TRUE), Code for testing
    list.files("C:/Users/natha/Box/_data/_fallout_radionuclides/Popeye_CAM-TKA/Popeye_CAM-TKA", pattern = "\\.TKA$", full.names = TRUE),
    cue = tar_cue(mode = "always")
    ),
  
  ## Energy calibrate each file (one branch per file) ====
  tar_target(
    spectra,
    energy_cal_tka(tka_files),
    pattern = map(tka_files),
    iteration = "list"
    ),
  
  ## Plot each spectra ====
  tar_target(
    spectra_plots,
    plot_spectra(spectra),
    pattern = map(spectra),
    iteration = "list",
    format = "file"
    )

)


#================================ Run Targets ================================
  
# tar_visnetwork()

# tar_make()

# tar_meta(fields = error, complete_only = TRUE)

# tar_read()
