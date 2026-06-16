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
    mutate(real_count = (count * 1 / efficiency_cal(kev)))

  ggplot(data = efcal_spectrum[[1]], mapping = aes(x = kev, y = real_count)) +
    scale_y_continuous(limits = c(0, 100000)) +
    scale_x_continuous(limits = c(650, 670)) +
    geom_point()

  return(efcal_spectrum)
}





#================================ Plot spectra ================================

#' [Test code]
# spectrum = tar_read(spectra_list)[[1]]

plot_spectra = function(spectrum){
  
  ggplot = ggplot(spectrum[[1]], aes(x = kev, y = real_count)) +
    geom_point() +
    #coord_cartesian(xlim = c(40, 50)) +
    coord_cartesian(xlim = c(655, 670),
                    ylim = c(0, 40000)) +
    geom_vline(xintercept = 661.7, linetype = "dashed", color = "red") +
    labs(
      title = spectrum[[2]],
      x = "Kev",
      y = "real_coutns",
      subtitle = paste0("Live time: ", round(spectrum[[3]]), "s | Real time: ", round(spectrum[[4]]), "s")
    ) +
    theme_minimal()
  
  # Also saves the plot to the _plots_outputs folder for furture reference
  out_path = paste0("_plot_outputs/plot_", spectrum[[2]], ".png")
  ggsave(out_path, ggplot, width = 8, height = 6)
  
  return(out_path)
}



