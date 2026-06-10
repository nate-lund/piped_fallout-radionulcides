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
ref_bd = read_excel(path)

ref_bd = ref_bd %>% 
  # Remove root ball sample
  filter(!(site == "ARB" & replicate == "B" & bottom_depth == 5)) %>% 
  group_by(site, bottom_depth) %>% 
  summarise(mean = mean(bd)) %>% 
  ungroup()


path2 = "G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/sample_inventory.xlsx"
inventory = read_excel(path2)
datatable(inventory2)

inventory2 = inventory %>%
  mutate(
    # Compute dry mass
    dry_mass = tin_plus_soil - tin,
    
    # Assign volumes based on the number of sampling points and volume of sample
    volume = case_when(
      forest %in% c("ASH", "WD", "MAG") ~ "510",
      forest %in% c("LRJ", "LRW", "LRE") ~ "510",
      forest == "ARB_ref" ~ "425", 
      forest == "LR_ref" ~ "453.33",
      TRUE ~ ""
    ),
    
    volume = as.numeric(volume),
    
    bd = dry_mass / volume
  )

# Look at only reference samples
probe_ref = inventory2 %>% 
  select(site, forest, bottom_depth, dry_mass, volume, bd) %>% 
  filter(forest %in% c("ARB_ref", "LR_ref"))


# Join refernece samples collect with ring method and probe method


joined = left_join(probe_ref, ref_bd, by = c("site", "bottom_depth")) %>% 
  select(site, bottom_depth, bd, mean)

ggplot(data = joined, mapping = aes(x = bd, y = mean, color = bottom_depth)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed")


