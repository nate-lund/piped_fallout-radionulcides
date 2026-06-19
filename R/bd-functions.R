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

#================================ Pull BD Data sets ================================


# Runoff plot data 
runoff_plots = read_excel("G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Runoff-Plots/soil-samples.xlsx")

# FRN reference data
frn_ref = read_excel("G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/reference-bulk-density.xlsx")

# FRN full inventory (little of this is segmented)
frn_inventory = read_excel("G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/sample_inventory.xlsx")

# Baumann et al. (2025) data
baumann = read_excel("C:/Users/natha/Box/_data/_outside_data/Baument-et-al_BD-values.xlsx")



# 1. Produce a few index columns.
# Forest: ASH, MAG, WD, LRJ, LRE, LRW, AREF, LREF
# Earthworm: JW, EW (add this by forest at end)
# Method: ring, probe
# Depth: 0, 5, 10, 15, 20, 25, 30
# Height: 5, 10, 30, 60
# Buld density (bd)

# Runoff plots
runoff_plots1 = runoff_plots %>% 
  drop_na(boat_soil) %>% 
  mutate(
    worms = NA,
    method = case_when(
      sample == "bd-ring" ~ "ring",
      sample == "bd-probe" ~ "probe"
    )
  )


# FRN reference data
frn_ref1 = frn_ref %>%
  mutate(
    method = "ring",
    worms = NA,
    sample_date = as.Date(sample_date)
  )


# FRN inventory
frn_inventory1 = frn_inventory %>% 
  drop_na(tin_plus_soil) %>% 
  mutate(
    sample_mass = tin_plus_soil - tin,
    volume = height * probe_pushes * (pi*(probe_diameter/2)^2),
    bd = sample_mass / volume,
    method = "probe",
    worms = NA,
    sample_date = as.Date(sample_date)
   )
  

# Baumann et al. (2025) data
baumann1 = baumann %>%
  mutate(
    forest = case_when(
      Forest == "Acer" ~ "ACE",
      Forest == "Magnolia" ~ "MAG",
      Forest == "WoodDuck" ~ "WD",
    ),
    worms = case_when(
      Worm_Type == "L" ~ "EW",
      Worm_Type == "A" ~ "JW"
    ),
    bottom_depth = case_when(
      Depth_cm == "0-5" ~ 5,
      Depth_cm == "5-10" ~ 10,
      Depth_cm == "10-15" ~ 15
    ),
    height = 5,
    bd = `Bulk_Density (g/cm^3)`,
    method = "?"
  )

# Bind all datasets together
binded = bind_rows(runoff_plots1, frn_ref1, frn_inventory1, baumann1, .id = "dataset") %>% 
  
  # Fill worms column 
  mutate(worms = if_else(
    dataset != "4",
    case_when(
      forest %in% c("ASH", "LRE", "LRW", "AREF", "LREF") ~ "EW",
      forest %in% c("MAG", "WD", "LRJ") ~ "JW"
    ),
    worms
  ))
         

datatable(binded)

ggplot(data = binded, mapping = aes(x = bd,
                          y = -bottom_depth,
                          color = worms,
                          group = interaction(bottom_depth, worms))) +
  geom_point(aes(shape = dataset)) +
#  geom_boxplot(orientation = "y") +
  scale_y_continuous(limits = c(0, -60)) +
  facet_wrap(~forest)


ggplot(binded, aes(x = bd)) +
  geom_histogram(bins = 20)  

?geom_boxplot












#================================ Testing ================================

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


