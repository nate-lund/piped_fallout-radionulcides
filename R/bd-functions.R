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
frn_inventory = read_excel("G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/sample-inventory.xlsx")

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
  ) %>% 
  # Remove root ball sample
  filter(!(forest == "AREF" & replicate == "B" & bottom_depth == 5))


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
         


#================================ Plot together ================================

# See per forest
ggplot(data = binded, mapping = aes(x = bd,
                                    y = -bottom_depth,
                                    color = method,
                                    group = interaction(bottom_depth, worms))) +
  geom_point(aes(shape = dataset)) +
  #  geom_boxplot(orientation = "y") +
  scale_y_continuous(limits = c(0, -60)) +
  facet_wrap(~forest +worms)

# See hisogram
ggplot(binded, aes(x = bd)) +
  geom_histogram(bins = 20)  





#================================ Mess with RP data ================================

runoff_plots1

# Pivot table to wide, easier time with plotting
runoff_plots_wide <- runoff_plots1 %>%
  pivot_wider(
    id_cols     = c(forest, plot, replicate),
    names_from  = c(sample, bottom_depth),
    values_from = bd,
    names_glue  = "{sample}_{bottom_depth}cm"
  )

# plot ring vs probe
rp_plot = ggplot(data = runoff_plots_wide, mapping = aes(x = `bd-ring_5cm`,
                                                         y = `bd-probe_5cm`,
                                                         color = forest,
                                                         shape = plot)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed")







#================================ Comapre Ref Samples ================================

# Take the mean of the refernece samples
mean_frn_ref = frn_ref1 %>% 
  #group_by(forest, bottom_depth) %>% 
  #summarise(mean = mean(bd)) %>% 
  #ungroup()

# Join dfs
inventory_ref = full_join(frn_inventory1, mean_frn_ref)

# Plot
inven_plot = ggplot(data = inventory_ref, mapping = aes(x = mean, y = bd, color = bottom_depth)) +
  geom_point() +
  labs(x = "ring", y = "probe") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed")

# Plot all BD ref
plot_grid(plotlist = c(inven_plot, rp_plot), ncol = 1)


# For looking at extra mass leftover from marinelli
inventory3 = inventory2 %>% 
  mutate(excess = dry_mass - labeled_marinelli - filled_marinelli)





#================================ Join comparative data sets ================================

# Simplify inventory_ref
inventory_ref1 = inventory_ref %>% 
  select(year, forest, site, bd, mean, bottom_depth) %>% 
  rename(probe = bd,
         ring = mean) %>% 
  filter(bottom_depth != 30)

# Rename columns
runoff_plots_wide1 = runoff_plots_wide %>% 
  rename(ring = `bd-ring_5cm`,
         probe = `bd-probe_5cm`)

# Bind DFs
rp_inv_ref = bind_rows(inventory_ref1, runoff_plots_wide1, .id = "dataset")

# Plot
ggplot(data = rp_inv_ref, mapping = aes(x = ring, y = probe, color = bottom_depth)) +
  geom_point() +
  labs(x = "ring", y = "probe") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  geom_smooth(method = "lm")
