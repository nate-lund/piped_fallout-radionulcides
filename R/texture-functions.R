
#================================ Input data ================================

# Texture file testing
path <- "G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/LPSA_2026/GUNELSON29JUL2026_NL_raw_undersize.csv"
raw = read_csv(path)

#================================ Pre-process data ================================

pre_process = function(data){
  
  return(psd_count)
}

# Clean up table
data = raw %>% 
  rename(
    sample = `Sample Name`,
    date_time = `Measurement Date Time`,
    dx_10 = `Dx (10)`,
    dx_50 = `Dx (50)`,
    dx_90 = `Dx (90)`,
    operator = `Operator Name`,
    instrument = `Instrument Serial No.`,
    run = `Record Number`
  )

# Create some headers for pivot table
meta_cols <- names(data)[1:8]
size_cols <- names(data)[9:ncol(data)]
size_um <- as.numeric(size_cols)

psd_count <- data %>%

  # Pivot
  pivot_longer(
    cols = all_of(size_cols),
    names_to = "size_label",
    values_to = "cumu_percent"
  ) %>%
  mutate(size_um = as.numeric(size_label)) %>%
  arrange(run, size_um) %>%
  select(run, all_of(meta_cols), size_um, cumu_percent) %>% 

  # Add diff column
  group_by(run) %>%
  mutate(count = cumu_percent - lag(cumu_percent, default = 0)) %>%
  ungroup() 
  

#================================ Compute Texture Classes ================================
# Note: This is written as if there could be coarse fragment data in the table.
# However, because we sieve to 2mm, that is not possible.

compute_texture = function(data){
  
}

# Pull only sand sit clay cumulative percentages
texture_raw = psd_count %>% 
  
  # Group by sample and date
  group_by(run) %>% 
  
  # To get the size closest to the borders, use some code tricks 
  mutate(
    sand_diff = abs(size_um - 2000),
    silt_diff = abs(size_um - 50),
    clay_diff = abs(size_um - 2),
    
    breaks = if_else(row_number() == which.min(sand_diff), 2000,
                     if_else(row_number() == which.min(silt_diff), 50,
                             if_else(row_number() == which.min(clay_diff), 2, 0)))
    
    ) %>%
  
  # Filter for only sand silt clay break rows
  filter(breaks != 0) %>% 
  select(-sand_diff, -silt_diff, -clay_diff) %>% 
  
  # Create summary
  summarise(
    sample    = first(sample),
    date_time = first(date_time),
    clay = cumu_percent[breaks == 2],
    silt = cumu_percent[breaks == 50] - cumu_percent[breaks == 2],
    sand = cumu_percent[breaks == 2000] - cumu_percent[breaks == 50],
    
    ) %>% 
  ungroup()

datatable(texture_raw)


#================================ Get Texture Class ================================

data = texture_raw %>% 

  # Compute a mean sand / silt / clay
  group_by(sample) %>% 
  summarize(
    first_date_time = first(date_time),
    clay = mean(clay),
    silt = mean(silt),
    sand = mean(sand)
  ) %>% 
  
  # Add soil texture class column
  mutate(
    texture_class = ssc_to_texcl(
      sand = sand, 
      clay = clay, 
      simplify = TRUE # Set to TRUE for the 12 major USDA classes
    )
  )


#================================ Plot Bins ================================

plot_bins = function(data){

# Filter for just one sample
plot_data = psd_count #%>% 
  #filter(sample == last(sample))

ggplot(data = plot_data, mapping= aes(y = count,
                                      x = log(size_um))) +
  geom_point() +
  geom_vline(xintercept = log(2000),  color = "darkred") + # grave-sand
  geom_vline(xintercept = log(50),  color = "firebrick") + # sand-silt
  geom_vline(xintercept = log(2),  color = "red") + # silt-clay
  
  facet_wrap(~sample)

}

