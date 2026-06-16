#================================ Packages ================================

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
    list.files("C:/Users/natha/Box/_data/_fallout_radionuclides/Popeye_CAM-TKA", pattern = "\\.TKA$", full.names = TRUE),
    cue = tar_cue(mode = "always")
    ),
  
  ## Energy calibrate each file (one branch per file) ====
  tar_target(
    encal_spectra,
    energy_cal_tka(tka_files),
    pattern = map(tka_files),
    iteration = "list"
    ),
  
  ## Calibrate blank ====
  tar_target(
    blank,
    energy_cal_tka(list.files("_blank/", pattern = "\\.TKA$", full.names = TRUE))
    ),
  
  
  ## Efficiency calibrate each spectra ====
  tar_target(
    efcal_spectra,
    efficiency_cal_tka(encal_spectra),
    pattern = map(encal_spectra),
    iteration = "list"
  ),
  
  ## Plot each spectra ====
  tar_target(
    spectra_plots,
    plot_spectra(efcal_spectra),
    pattern = map(efcal_spectra),
    iteration = "list",
    format = "file"
  ),
    
  ## Bind all spectra into a list ====
  tar_target(
    spectra_list,
    as.list(efcal_spectra)
  ),
  
  ## Peak area computations for each spectrum ====
  tar_target(
    peak_counts,
    compute_peak_counts(efcal_spectra),
    pattern = map(efcal_spectra),
    iteration = "list"
  ),
  
  ## Bind peak count dfs ====
  tar_target(
    all_peak_counts,
    bind_rows(peak_counts)
  ),
  
  ## Load sample data ====
  tar_target(
    sample_inventory,
    read_xlsx("G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/sample_inventory.xlsx")
    )

)


#================================ Run Targets ================================
  
# Visialize the worlfow
# tar_visnetwork()

# Clear _targets/objects
# tar_prune() 

# Run the workflow
# tar_make()

# View errors
# tar_meta(fields = error, complete_only = TRUE)

# Read a single file
# tar_read()
