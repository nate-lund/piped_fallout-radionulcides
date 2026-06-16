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


#================================ Plotting ================================

# Define the equation as a function
eff_cal <- function(E) {10^( # This is a log transform
  
  -2.993e-04*E -1.546e00 + 1.185e02/E - 9.472e03/E^2 + 6.118e04/E^3
  
)
  }

# Plot 
ggplot() +
  xlim(-10, 10) +
  geom_function(fun = eff_cal, color = "black", size = 1) +
  scale_x_continuous(limits = c(0, 1500)) +
  scale_y_continuous(limits = c(0, 0.07)) +
  labs(x = "Energy (Kev)", y = "Eff") +
  theme_minimal()





