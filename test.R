#================================ Setup ================================

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

path = "G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/reference-bulk-density.xlsx"

data = read_excel(path)

datatable(processed)

processed = data %>% 
  # Remove root ball sample
  filter(!(site == "ARB" & replicate == "B" & depth == "0-5")) %>% 
  group_by(site, depth) %>% 
  summarise(mean = mean(bd)) %>% 
  ungroup()
