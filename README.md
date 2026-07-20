# piped_fallout-radionulcides

In short, this is a set of code that uses .TKA files and some sample parameters
(stored in an .xlxs file) to compute actual samples activities by performing 
energy and efficiency calibration and peak-to-total computations for Cs-137 
(erosion computations are saved for another set).

This project uses the targets R package. If you are not familiar, the 
documentation for running targets scrips can be found here: 
https://books.ropensci.org/targets/ 


Required inputs:
1. A set of TKA files. These should be placed in the "_TKA-files" folder.

  File names should be structured as follows:
  "YYMMDD_'initials'_'detector'_'sample name'_'container geometry_'run time'.CNF" 

  For example:
  "260304_NL_Popeye_2026-EZ-Std-March_Marinelli_24hr.CNF"

  The code is written for a particular structure of sample name, but it will run
  without it. You will just get some non-useful descriptive columns. 


2. A sample inventory sheet. This should be placed in the "_sample-inventory"
folder. This sheet will store some critical information under the following 
column headers.

  Forest: 
