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
# peak_counts = tar_read(all_peak_counts)

# sample_inventory = tar_read(sample_inventory)

compute_activity = function(peak_counts, sample_invetory){
  
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
      too_few  = "align_start", # rows with only 3 pieces -> extra = NA
      too_many = "merge" # rows with 5+ pieces -> everything past slope_pos goes into extra
    ) %>% 
    
    mutate(run_date = ymd(run_date))
  
  print(file_inventory, n = 46)
  
}


