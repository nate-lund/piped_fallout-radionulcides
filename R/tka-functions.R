#================================ Read files ================================

#' [Test code]
# file_path = "_data/260311_NL_Popeye_LR-ref-0-5_Marinelli_24hr.TKA"

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
    counts = counts # Raw data
  )
  
  # Define calibration coefs from cal file
  # This set is from "Popeye_2026EZ-Marinelli_order2_Mar05_2026"
  a = -1.721e-1 # Intercept
  b = 1.696e-1
  c = 2.357e-18
  
  # Create energy calibration function
  calibrate = function(channel){
    keV <-a + b * channel - c * channel^2
  }
  
  # Apply energy calibration
  tka_df = tka_df %>% 
    mutate(kev = calibrate(channel))
  
  spectrum = list(tka_df, file, live_time, real_time)
  
  return(spectrum)
}



#================================ Plot spectra ================================

#' [Test code]
# spectrum = tar_read(spectra_2e52922180ebdeb1)

plot_spectra = function(spectrum){
  
  ggplot = ggplot(spectrum[[1]], aes(x = kev, y = counts)) +
    geom_point() +
    #coord_cartesian(xlim = c(40, 50)) +
    coord_cartesian(xlim = c(655, 670)) +
    geom_vline(xintercept = 661.7, linetype = "dashed", color = "red") +
    labs(
      title = spectrum[[2]],
      x = "Channel",
      y = "Counts",
      subtitle = paste0("Live time: ", round(spectrum[[3]]), "s | Real time: ", round(spectrum[[4]]), "s")
    ) +
    theme_minimal()
  
  # Also saves the plot to the _plots_outputs folder for furture reference
  out_path = paste0("_plot_outputs/plot_", spectrum[[2]], ".png")
  ggsave(out_path, ggplot, width = 8, height = 6)
  
  return(out_path)
}
