# piped_fallout-radionulcides

In short, this is a set of code that uses .TKA files and some sample parameters
(stored in an .xlxs file) to compute actual samples activities by performing 
energy and efficiency calibration and peak-to-total computations for Cs-137 
(erosion computations are saved for another set).

This project uses the targets R package. If you are not familiar, the 
documentation for running targets scrips can be found here: 
https://books.ropensci.org/targets/. The gist is you should run the whole 
"_targets.R" script, the run "tar_make()" in the console everything will run. 
Assuming that all the prerequisites are in place.


Prerequisites / Required inputs:
1. A set of TKA files. These should be placed in the "_TKA-files" folder. My 
files will be in there by default, feel free to delete.

  File names should be structured as follows:
  "YYMMDD_'initials'_'detector'_'year-forest-slopepos'_'container geometry_'run time'.CNF" 

  For example:
  "260304_NL_Popeye_2026-EZ-2024-LRW-SU_24hr.CNF"

  The code is written for a particular structure of sample name, in which different
  "items" are seperated by "-". Matching that structure is helpful.


2. A sample inventory sheet. You'll need to input this file path in the "_targets.R"
script. This sheet will store some critical information needed to compute actual
activities. Notably, we need the mass of the soil in the Marinelli so we can
compute activity in Bq/g. In order to do this, we need to match each .TKA to a row
in this .xlxs sheet. I use the following sample identifiers, each represented in a column
in my sample inventory sheet:

  forest — join key (must match value from .TKA file name)
  
  year — join key (must match value from .TKA file name)
  
  slope_pos — join key (must match value from .TKA file name)
  
  sample_date — date sample was taken
  
  filled_marinelli — mass of filled marinelli beaker
  
  labeled_marinelli — mass of empty marinelli beaker (used to compute sample_mass = filled_marinelli - labeled_marinelli)



NOTE: In any case, targets past "## Compute activity in Bq / g ====" will fail.
Lots of outside information is needed here. YOu will also need to make changes
to the plots, but this is place to start.
