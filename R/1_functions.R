# ==========================================================================|
# CORE HELPER FUNCTIONS ====================================================
# ==========================================================================|

# Shared functions sourced by all pipeline scripts.
# Usage: source("R/1_functions.R")


# ==========================================================================|
# CONFIG ===================================================================
# ==========================================================================|

load_config <- function(path = "config.yml") {
  # Load and validate config.yml
  if (!file.exists(path)) {
    stop("config.yml not found. Run from the project root directory.")
  }
  cfg <- yaml::read_yaml(path)

  # Validate required top-level keys
  required <- c("spatial", "helicopter", "activation", "osm_speeds")
  missing <- setdiff(required, names(cfg))
  if (length(missing) > 0) {
    stop(
      "config.yml missing required sections: ",
      paste(missing, collapse = ", ")
    )
  }
  cfg
}


# ==========================================================================|
# CLEAN DATA I/O ===========================================================  
# ==========================================================================|

save_clean <- function(obj, name, dir = "clean_data") {
  # Save an object to clean_data/ as .RData
  path <- file.path(dir, paste0(name, ".RData"))
  assign(name, obj)
  save(list = name, file = path, envir = environment())
  invisible(path)
}

load_clean <- function(name, dir = "clean_data") {
  # Load an .RData file from clean_data/ into the calling env
  path <- file.path(dir, paste0(name, ".RData"))
  if (!file.exists(path)) {
    stop(
      "clean_data/", name, ".RData not found. ",
      "Run the upstream script first."
    )
  }
  load(path, envir = parent.frame())
  invisible(path)
}


# ==========================================================================|
# CRS HELPERS ==============================================================
# ==========================================================================|

assert_crs <- function(sf_obj, expected_epsg = 26915) {
  # Stop if the sf/sfc object is not in the expected CRS
  actual <- sf::st_crs(sf_obj)$epsg
  if (is.na(actual) || actual != expected_epsg) {
    stop(
      "CRS mismatch: expected EPSG:", expected_epsg,
      " but got EPSG:", actual
    )
  }
  invisible(sf_obj)
}

ensure_crs <- function(sf_obj, target_epsg = 26915) {
  # Reproject to the project CRS if needed
  actual <- sf::st_crs(sf_obj)$epsg
  if (is.na(actual) || actual != target_epsg) {
    sf_obj <- sf::st_transform(sf_obj, target_epsg)
  }
  sf_obj
}


# ==========================================================================|
# OSM SPEED LOOKUP =========================================================
# ==========================================================================|

osm_speed_lookup <- function(config) {
  # Return a named vector: highway tag -> speed in km/h
  speeds <- unlist(config$osm_speeds)
  speeds
}


# ==========================================================================|
# WIND-ADJUSTED SPEED ======================================================
# ==========================================================================|

compute_wind_adjusted_speed <- function(airspeed_kts, wind_u, wind_v,
                                        bearing_rad) {
  # Compute effective ground speed (m/min) given airspeed and wind
  #
  # airspeed_kts: helicopter airspeed in knots
  # wind_u: east-west wind component (m/s, positive = eastward)
  # wind_v: north-south wind component (m/s, positive = northward)
  # bearing_rad: flight bearing in radians (0 = north, clockwise)
  #
  # Returns: effective ground speed in m/min

  # Convert airspeed to m/s
  airspeed_ms <- airspeed_kts * 0.514444

  # Headwind/tailwind component along the flight bearing
  # Positive = tailwind (wind pushing in direction of flight)
  wind_component <- wind_u * sin(bearing_rad) +
    wind_v * cos(bearing_rad)

  # Effective ground speed in m/s, convert to m/min
  ground_speed_ms <- airspeed_ms + wind_component
  ground_speed_ms * 60
}


# ==========================================================================|
# NETWORK SNAPPING =========================================================
# ==========================================================================|

snap_to_network <- function(points_sf, nodes_sf) {
  # Snap a set of sf points to their nearest road network node
  #
  # Returns a tibble with columns:
  #   point_id: row index of input point
  #   node_id:  row index of nearest node
  #   snap_dist_m: distance in meters

  # Extract coordinate matrices
  point_coords <- sf::st_coordinates(points_sf)
  node_coords <- sf::st_coordinates(nodes_sf)

  # Fast nearest-neighbor via RANN
  nn <- RANN::nn2(node_coords, point_coords, k = 1)

  tibble::tibble(
    point_id = seq_len(nrow(point_coords)),
    node_id = as.integer(nn$nn.idx[, 1]),
    snap_dist_m = as.numeric(nn$nn.dists[, 1])
  )
}


