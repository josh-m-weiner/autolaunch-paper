# ==========================================================================|
# DATA VALIDATION HELPERS ==================================================
# ==========================================================================|

# Sanity checks called by pipeline scripts after loading or creating data.
# Usage: source("R/3_validation.R")


# ==========================================================================|
# SPATIAL VALIDATION =======================================================
# ==========================================================================|

validate_facilities_in_study_area <- function(facilities_sf,
                                              study_area_sf,
                                              label = "facilities") {
  # Warn if any facility points fall outside the study area
  inside <- sf::st_intersects(facilities_sf, study_area_sf, sparse = FALSE)
  n_outside <- sum(!inside[, 1])
  if (n_outside > 0) {
    warning(
      n_outside, " of ", nrow(facilities_sf), " ", label,
      " fall outside the study area."
    )
  }
  invisible(n_outside == 0)
}


validate_grid_coverage <- function(grid_rast, study_area_sf) {
  # Check that the grid fully covers the study area
  # Returns TRUE if the grid extent contains the study area bbox
  grid_ext <- terra::ext(grid_rast)
  sa_bbox <- sf::st_bbox(study_area_sf)

  covered <- grid_ext$xmin <= sa_bbox["xmin"] &&
    grid_ext$xmax >= sa_bbox["xmax"] &&
    grid_ext$ymin <= sa_bbox["ymin"] &&
    grid_ext$ymax >= sa_bbox["ymax"]

  if (!covered) {
    warning("Grid does not fully cover the study area extent.")
  }
  invisible(covered)
}


# ==========================================================================|
# VALUE RANGE VALIDATION ===================================================
# ==========================================================================|

validate_time_range <- function(rast, label = "layer",
                                min_expected = 0,
                                max_expected = 600) {
  # Flag cells with implausible travel time values
  vals <- terra::values(rast, na.rm = TRUE)
  n_below <- sum(vals < min_expected)
  n_above <- sum(vals > max_expected)
  n_na <- sum(is.na(terra::values(rast)))

  if (n_below > 0) {
    warning(
      label, ": ", n_below,
      " cells below ", min_expected, " minutes."
    )
  }
  if (n_above > 0) {
    warning(
      label, ": ", n_above,
      " cells above ", max_expected, " minutes."
    )
  }

  invisible(tibble::tibble(
    layer = label,
    n_cells = length(vals),
    n_na = n_na,
    n_below_min = n_below,
    n_above_max = n_above,
    min_val = min(vals),
    max_val = max(vals),
    mean_val = mean(vals)
  ))
}


validate_snap_distances <- function(snap_df, threshold_m = 5000,
                                    label = "grid cells") {
  # Flag points that snapped suspiciously far from the road network
  n_far <- sum(snap_df$snap_dist_m > threshold_m)
  if (n_far > 0) {
    warning(
      n_far, " ", label, " snapped > ",
      threshold_m / 1000, " km from nearest road node."
    )
  }
  invisible(n_far)
}
