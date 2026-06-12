#================================ Read files ================================

#' [Test code]
# file_path = "_data/260311_NL_Popeye_LR-ref-0-5_Marinelli_24hr.TKA"

energy_cal_tka = function(file_path){
  
  # Read TKA file
  tka <- readLines(file_path) %>% 
    as.numeric()
  
  # First two lines are live time and real time
  live_time <- tka[1]
  real_time <- tka[2]
  
  # Remaining values are counts per channel
  counts <- tka[3:length(tka)] # Raw data
  channels <- seq_along(counts) # Essential the row of the TKA
  
  # Build dataframe
  tka_df <- tibble(
    channel = channels,
    counts = counts
  )
  
  # Define calibration coefs from cal file
  # This set is from "Popeye_2026EZ-Marinelli_order2_Mar05_2026"
  a = -1.721e-1 # Intercept
  b = 1.696e-1
  c = 2.357e-18
  
  # Create energy calibration function
  calibrate = function(channels){
    keV <-a + b * channels - c * channels^2
  }
  
  # Apply energy calibration
  spectrum = tka_df %>% 
    mutate(kev = calibrate(channels))
  
  return(spectrum)
}


# # Plot
# ggplot(spectrum, aes(x = kev, y = counts)) +
#   geom_point() +
#   #coord_cartesian(xlim = c(40, 50)) +
#   coord_cartesian(xlim = c(655, 670)) +
#   geom_vline(xintercept = 661.7, linetype = "dashed", color = "red") +
#   labs(
#     title = file,
#     x = "Channel",
#     y = "Counts",
#     subtitle = paste0("Live time: ", round(live_time), "s | Real time: ", round(real_time), "s")
#   ) +
#   theme_minimal()
