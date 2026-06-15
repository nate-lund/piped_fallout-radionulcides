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
ref_bd_raw = read_excel(path)

ggplot(data = ref_bd_raw, mapping = aes(x = bd, y = -bottom_depth, color = site)) +
  geom_point()


ref_bd = ref_bd_raw %>% 
  # Remove root ball sample
  filter(!(site == "ARB" & replicate == "B" & bottom_depth == 5)) %>% 
  group_by(site, bottom_depth) %>% 
  summarise(mean = mean(bd)) %>% 
  ungroup()


path2 = "G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/sample_inventory.xlsx"
inventory = read_excel(path2)


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

# For looking at extra mass leftover from marinelli
inventory3 = inventory2 %>% 
  mutate(excess = dry_mass - labeled_marinelli - filled_marinelli)


#================================ BD Worm difference ================================

# Clean up df
clean_inven = inventory2 %>% 
  select(site, forest, slope_pos, bottom_depth, dry_mass, volume, bd) %>% 
  filter(forest %in% c("ASH", "WD", "MAG", "LRJ", "LRW", "LRE")) %>% 
  
  # Order slope positions
  mutate(
    slope_pos = factor(slope_pos, levels = c("TS60", "FS60", "TS30", "FS30", "BS1", "BS2", "BS3", "SH", "SU")),
    
    worms = case_when(
      forest %in% c("ASH", "LRE", "LRW") ~ "EW",
      forest %in% c("MAG", "WD", "LRJ") ~ "JW"
    )
  )


ggplot(data = clean_inven, mapping = aes(x = slope_pos, y = bd)) +
  geom_point() +
  facet_wrap(~worms, ncol = 1)


#================================ BD Probe testing ================================

# Look at only reference samples
probe_ref = inventory2 %>% 
  select(site, forest, bottom_depth, dry_mass, volume, bd) %>% 
  filter(forest %in% c("ARB_ref", "LR_ref"))


# Join reference samples collect with ring method and probe method
joined = left_join(probe_ref, ref_bd, by = c("site", "bottom_depth")) %>% 
  select(site, bottom_depth, bd, mean)

ggplot(data = joined, mapping = aes(x = bd, y = mean, color = bottom_depth)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed")


