
# ==========================================================================|
# RUN ALL SCRIPTS AND RENDER REPORTS =======================================|
# ==========================================================================|

library(tidyverse)
library(rmarkdown)

# ==========================================================================|
# PIPELINE CONTROL =========================================================|
# ==========================================================================|

# Set TRUE to force re-run of a stage even if cached output exists.
# By default, each script skips expensive computation when its output
# already exists in clean_data/.
force <- list(
  data_import = FALSE,
  study_area  = FALSE,
  weather     = FALSE,
  airlayer    = FALSE,
  groundlayer = FALSE,
  activation  = FALSE,
  analysis    = FALSE,
  sensitivity = FALSE
)

saveRDS(force, "clean_data/.force_flags.rds")

# ==========================================================================|
# SOURCE FUNCTION LIBRARIES ================================================|
# ==========================================================================|

source("R/1_functions.R")
source("R/2_map_tools.R")
source("R/3_validation.R")

# ==========================================================================|
# RUN ANALYSIS PIPELINE ====================================================|
# ==========================================================================|

source("1_data_import.r")
source("2_study_area.r")
source("3_weather.r")
source("4_airlayer.r")
source("5_groundlayer.r")
source("6_activation.r")
source("7_analysis.r")
source("8_sensitivity.r")

# ==========================================================================|
# RENDER REPORTS ===========================================================|
# ==========================================================================|

# Main report
render(
  "10_report.Rmd",
  output_file = paste0(
    "10_report-",
    format(Sys.time(), "%Y-%m-%d-%H%M"),
    ".pdf"
  ),
  output_dir = "output"
)

# Interactive supplement
render(
  "11_supplement.Rmd",
  output_file = paste0(
    "11_supplement-",
    format(Sys.time(), "%Y-%m-%d-%H%M"),
    ".html"
  ),
  output_dir = "output"
)

# Clean up temp flags
file.remove("clean_data/.force_flags.rds")
