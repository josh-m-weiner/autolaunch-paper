# ==========================================================================|
# ONE-TIME PROJECT SETUP ===================================================
# ==========================================================================|

# Run this script once on a new machine to set up the project environment.
# This is NOT part of the analysis pipeline and is NOT sourced by
# 999_run_all.r.

# ==========================================================================|
# RESTORE PACKAGES =========================================================
# ==========================================================================|

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}
renv::restore()

# ==========================================================================|
# CREATE DIRECTORY STRUCTURE ===============================================
# ==========================================================================|

dirs <- c("raw_data", "clean_data", "output", "R", "scripts")
for (d in dirs) {
  if (!dir.exists(d)) dir.create(d)
}

# ==========================================================================|
# CHECK API KEYS ===========================================================
# ==========================================================================|

if (Sys.getenv("CENSUS_API_KEY") == "") {
  message(
    "NOTE: Set CENSUS_API_KEY in .Renviron for tidycensus.\n",
    "  Run: usethis::edit_r_environ()\n",
    "  Add: CENSUS_API_KEY=your_key_here"
  )
}
if (Sys.getenv("CENSUS_API_KEY") != "")
{
  message(
    "CENSUS_API_KEY found successfully"
    )
}

# ==========================================================================|
# VERIFY CONFIG ============================================================
# ==========================================================================|

source("R/1_functions.R")
config <- load_config()
message("config.yml loaded successfully.")
