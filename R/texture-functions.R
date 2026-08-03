

# Texture file testing
path <- "G:/Shared drives/P05-mitppc-jumpingwormerosion/Project-Data/Fallout-Radionucldes/LPSA_2026/GUNELSON29JUL2026_NL_raw_undersize.csv"
raw = read_csv(path)


meta_cols <- names(raw)[1:8]
size_cols <- names(raw)[9:ncol(raw)]

# size class diameters (µm), taken straight from the column headers
size_um <- as.numeric(size_cols)

psd_long <- raw %>%
  mutate(row_id = row_number()) %>%
  pivot_longer(
    cols = all_of(size_cols),
    names_to = "size_label",
    values_to = "cum_pct_undersize"
  ) %>%
  mutate(size_um = as.numeric(size_label)) %>%
  arrange(row_id, size_um) %>%
  select(row_id, all_of(meta_cols), size_um, cum_pct_undersize) %>% 

  # Add diff column
  group_by(row_id) %>%
  mutate(diff_pct_volume = cum_pct_undersize - lag(cum_pct_undersize, default = 0)) %>%
  ungroup()



ggplot(data = psd_count, mapping= aes(y = diff_pct_volume, y = ))