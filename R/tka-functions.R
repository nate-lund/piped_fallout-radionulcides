#================================ Energy Calibration ================================

#' [Test code]
# file_path = "C:/Users/natha/Box/_data/_fallout_radionuclides/Popeye_CAM-TKA/260522_NL_Popeye_2025-LRW-TS30_Marinelli_24hr.TKA"

energy_cal_tka = function(file_path){
  
  # Read TKA file
  tka <- readLines(file_path) %>% 
    as.numeric()
  
  # Strip the extension from the file path
  file = tools::file_path_sans_ext(basename(file_path))
  
  # First two lines are live time and real time
  live_time <- tka[1]
  real_time <- tka[2]
  
  # Pull just counts
  counts = tka[3:length(tka)] # Raw data
  
  # Build dataframe
  tka_df <- tibble(
    channel = seq_along(counts), # Essential the row of the TKA,
    count = counts # Raw data
  )
  
  # Define calibration coefs from cal file
  # This set is from "Popeye_2026EZ-Marinelli_order2_Mar05_2026"
  a = -1.721e-1 # Intercept
  b = 1.696e-1
  c = 2.357e-18
  
  # Create energy calibration function
  energy_cal = function(channel){
    keV <-a + b * channel - c * channel^2
  }
  
  # Apply energy calibration
  tka_df = tka_df %>% 
    mutate(kev = energy_cal(channel))
  
  spectrum = list(tka_df, file, live_time, real_time)
  
  return(spectrum)
}


#================================ Efficiency Calibration ================================

#' [Test code]
# spectrum = tar_read(spectra_list)[[2]]

efficiency_cal_tka = function(spectrum){
  
  # Create a function for the calibration equation,
  # this set is from "Popeye_2026EZ-Marinelli_order2_Mar05_2026" 
  efficiency_cal <- function(E) {10^(-2.993e-04*E -1.546e00 + 1.185e02/E - 9.472e03/E^2 + 6.118e04/E^3)
  }
  
  # Copy to preserve list metadata
  efcal_spectrum = spectrum
  # Apply calibration
  efcal_spectrum[[1]] = spectrum[[1]] %>% 
    mutate(eff_count = (count * 1 / efficiency_cal(kev)))

  return(efcal_spectrum)
}


#================================ Plot spectra ================================

#' [Test code]
# spectrum = tar_read(spectra_list)[[15]]

plot_spectra = function(spectrum){
  
  ggplot = ggplot(spectrum[[1]], aes(x = kev, y = eff_count)) +
    geom_point() +
    #coord_cartesian(xlim = c(40, 50)) +
    coord_cartesian(xlim = c(655, 670),
                    ylim = c(0, 40000)) +
    # Vertical line at 661.7 kev, should be peak
    geom_vline(xintercept = 661.7,  color = "red") +
    # Vertical line at approximate peak ends,
    geom_vline(xintercept = 661.7 - 2, linetype = "dashed", color = "red") + # Lower
    geom_vline(xintercept = 661.7 + 2, linetype = "dashed", color = "red") + # Upper
    labs(
      title = spectrum[[2]],
      x = "Kev",
      y = "eff_counts",
      subtitle = paste0("Live time: ", round(spectrum[[3]]), "s | Real time: ", round(spectrum[[4]]), "s")
    ) +
    theme_minimal()
  
  # Also saves the plot to the _plots_outputs folder for furture reference
  out_path = paste0("_plot_outputs/plot_", spectrum[[2]], ".png")
  ggsave(out_path, ggplot, width = 8, height = 6)
  
  return(out_path)
}


#================================ Compute Peak Area ================================

#' [Test Code]
# spectrum = tar_read(spectra_list)[[1]]

compute_peak_counts = function(spectrum){
  
  # Half of peak width in channels , using 12 for 137-Cs
  peak_width = 12 
  
  # Background widths
  upper_width = 6 # Upper
  lower_width = 18 # Lower
  
  # Peak kev
  peak_kev = 661.7 # for 137-Cs
  
  
  # Identify peak channel, i.e. the channel with a kev closest to peak kev
  peak_channel = spectrum[[1]] %>%
    mutate(diff = abs(kev - peak_kev),
           peak = if_else(diff == min(diff), 1, 0)) %>%
    filter(peak == 1) %>% 
    select(channel) %>% 
    as.numeric()
  
  # Subset spectrum for only peak energies
  peak = spectrum # Copy metadata
  peak[[1]] = spectrum[[1]] %>% 
    filter(channel >= peak_channel - peak_width & # uses width above
             channel <= peak_channel + peak_width)
 
  
  # Compute net peak area
  N_net = sum(peak[[1]]["eff_count"])
  
  # Subset spectrum for only background energies
  background = spectrum # Copy metadata
  background[[1]] = spectrum[[1]] %>% 
    filter(
      # Lower
      (channel <= peak_channel - peak_width - 1 &
             channel >= peak_channel - peak_width - lower_width)
      | # Or
        
        # Upper
        (channel >= peak_channel + peak_width + 1 &
           channel <= peak_channel + peak_width + upper_width)
        )

  # Compute the background peak area
  N_bg = sum(background[[1]]["eff_count"]) * (2 * peak_width + 1) / (lower_width + upper_width)
  
  # Compute total counts
  N = N_net - N_bg
  
  out = data.frame(
    N = N,
    file = spectrum[[2]],
    live_time = spectrum[[3]],
    real_time = spectrum[[4]]
  )
  
  return(out)
  
}


#================================ Compute Activity ================================

#' [Test code]
# peak_counts = tar_read(all_peak_counts); sample_inventory = tar_read(sample_inventory)



compute_activity = function(peak_counts, sample_inventory){
  
  # Clean up the dataframe
  file_inventory = peak_counts %>%
    # Pull apart file name into unique columns
    separate_wider_delim(
      cols  = file,
      delim = "_",
      names = c("run_date", "initals", "detector", "sample", "geometry", "count_time")
    ) %>% 
    
    # Pull apart sample name into parts
    separate_wider_delim(
      cols  = sample,
      delim = "-",
      names = c("year", "forest", "slope_pos"),
      too_few  = "align_start", 
      too_many = "merge" 
    ) %>% 
    
    mutate(
      run_date = ymd(run_date),
      year = as.numeric(year))
  
  # Clean up sample inventory
  sample_inventory = sample_inventory %>% 
    mutate(
      sample_date = as.Date(sample_date),
      sample_mass = filled_marinelli - labeled_marinelli
    )
  
  # Join file and sample inventories, keeping all columns
  joined_inventory = full_join(file_inventory,
                               sample_inventory,
                               by = c("forest", "year", "slope_pos"))
  

  # Define a function to compute activity (based on IAEA), will compute
  # activity in units of Bq / kg
  computue_activity = function(peak_area, decay_constant, counting_time,
                               sample_time, run_time, sample_mass,
                               emission_prob){
    
    # Compute time difference
    time_diff = as.numeric(difftime(run_time, sample_time, units = "secs"))
    
    activity = (peak_area * exp(decay_constant * time_diff)) /
      (emission_prob * sample_mass * counting_time)
    
    return(activity)
    
    }
  
  # Compute activity
  activity_inventory = joined_inventory %>% 
    mutate(
      # Compute activity using the function
      activity_g = computue_activity(peak_area = N,
                                      decay_constant = log(2)/30.17 / 31557600, # 137Cs
                                      counting_time = live_time,
                                      sample_time = sample_date,
                                      run_time = run_date,
                                      sample_mass = sample_mass,
                                      emission_prob = 0.85) # 137Cs
    ) %>% 
    
    # Provide a bd-correct value too
    mutate(
      bd = sample_mass / (probe_pushes * height * (pi * (probe_diameter/2)^2)),
      activity_cm3 = activity_g  * bd
    )
    
    
  
  return(activity_inventory)
}


#================================ Convert Actibity to Length ================================
# This is only needed if outside bd data was collected 

bd_correction = function(activity_invetory){
  
  
}

#================================ Plot Activity ================================

#' [Test code]
# activity_inventory = tar_read(activity_inventory)

plot_activity = function(activities){
  
  # Filter erosion data from reference data
  eros_data = activity_inventory %>%
    filter(
      forest %in% c("ASH", "WD", "MAG", "LRE", "LRW", "LRJ") &
        slope_pos %in% c("SU", "SH", "BS3", "BS2", "BS1", "FS30",
                                                 "TS30", "FS60", "TS60")
      ) %>%
    mutate(forest = factor(forest, levels = c("ASH", "LRE", "LRW", "MAG", "WD", "LRJ"))) %>% 
    mutate(slope_pos = factor(slope_pos, levels = c("SU", "SH", "BS3", "BS2", "BS1", "FS30",
                                                 "TS30", "FS60", "TS60", "FS", "TS"))) %>% 
    group_by(forest, slope_pos) %>%
    summarise(activity_cm3 = mean(activity_cm3), .groups = "drop") %>% # Removes replicate LRW samples for now
    ungroup()
  
  # Plot erosion data
  ggplot(data = eros_data, mapping = aes(x = slope_pos, y = activity_cm3)) +
    geom_col() +
    facet_wrap(~forest)
  
  # Filter reference data from erosion data
  ref_data = activity_inventory %>%
    filter(
      slope_pos %in% c("ref-25-30", "ref-20-25", "ref-15-20", "ref-10-15", "ref-5-10", "ref-0-5")
      ) %>%
    mutate(
      slope_pos = factor(slope_pos, levels = c("ref-25-30", "ref-20-25", "ref-15-20", "ref-10-15", "ref-5-10", "ref-0-5"))
      ) 
  
  # Plot reference data
  ggplot(data = ref_data, mapping = aes(x = activity_cm3, y = slope_pos)) +
    geom_col(width = 0.96) +
    facet_wrap(~forest, ncol = 1)
  
    
}



