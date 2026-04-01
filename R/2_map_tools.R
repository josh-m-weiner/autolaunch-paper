# ==========================================================================|
# MAP VIEWING AND VISUALIZATION TOOLS ======================================
# ==========================================================================|

# Interactive and static mapping helpers using tmap.
# Usage: source("R/2_map_tools.R")


# ==========================================================================|
# INTERACTIVE VIEWERS ======================================================
# ==========================================================================|

view_layer <- function(data, col, title = col, palette = "viridis",
                       alpha = 0.7) {
  # Quick interactive tmap viewer for a single layer
  #
  # data: sf or SpatRaster object
  # col: column name (sf) or layer name (raster) to display
  # title: legend title
  # palette: color palette name

  tmap::tmap_mode("view")

  if (inherits(data, "SpatRaster")) {
    tmap::tm_shape(data) +
      tmap::tm_raster(
        col = col,
        title = title,
        palette = palette,
        alpha = alpha
      )
  } else {
    tmap::tm_shape(data) +
      tmap::tm_fill(
        col = col,
        title = title,
        palette = palette,
        alpha = alpha
      ) +
      tmap::tm_borders(lwd = 0.5)
  }
}


view_comparison <- function(data, cols, titles = cols,
                            palette = "viridis") {
  # Side-by-side tmap view of multiple variables from the same dataset
  #
  # data: sf or SpatRaster
  # cols: character vector of column/layer names
  # titles: legend titles (same length as cols)

  tmap::tmap_mode("view")

  maps <- purrr::map2(cols, titles, function(col, title) {
    view_layer(data, col, title, palette)
  })

  tmap::tmap_arrange(maps, sync = TRUE)
}


view_facilities <- function(trauma_centers = NULL, air_bases = NULL,
                            counties = NULL) {
  # Quick facility overview map with optional county boundaries
  #
  # trauma_centers: sf POINT (optional)
  # air_bases: sf POINT (optional)
  # counties: sf POLYGON (optional)

  tmap::tmap_mode("view")
  map <- tmap::tm_basemap("OpenStreetMap")

  if (!is.null(counties)) {
    map <- map +
      tmap::tm_shape(counties, name = "Counties") +
      tmap::tm_borders(col = "grey50", lwd = 0.5)
  }

  if (!is.null(trauma_centers)) {
    map <- map +
      tmap::tm_shape(trauma_centers, name = "Trauma Centers") +
      tmap::tm_dots(col = "red", size = 0.1)
  }

  if (!is.null(air_bases)) {
    map <- map +
      tmap::tm_shape(air_bases, name = "Air Bases") +
      tmap::tm_dots(col = "blue", size = 0.1)
  }

  map
}


# ==========================================================================|
# CONTOUR TOOLS ============================================================
# ==========================================================================|

make_contour_polygons <- function(rast, breaks, simplify_m = 100) {
  # Convert a continuous raster into contour polygons at specified breaks
  #
  # rast: SpatRaster (e.g., time-difference surface)
  # breaks: numeric vector of contour breaks
  # simplify_m: tolerance for polygon simplification (meters)
  #
  # Returns: sf polygons with a 'level' column

  # Classify raster into bins
  rcl_matrix <- cbind(
    c(-Inf, breaks),
    c(breaks, Inf),
    seq_along(c(breaks, Inf))
  )
  classified <- terra::classify(rast, rcl_matrix)

  # Convert to polygons and simplify
  polys <- terra::as.polygons(classified, dissolve = TRUE) %>%
    sf::st_as_sf() %>%
    sf::st_simplify(dTolerance = simplify_m)

  polys
}


# ==========================================================================|
# STATIC MAPS ===============================================================
# ==========================================================================|

static_map <- function(data, col, title = col, palette = "viridis",
                       breaks = NULL) {
  # Publication-ready static map via tmap
  #
  # data: sf or SpatRaster
  # col: variable to plot
  # title: legend title
  # palette: color palette
  # breaks: optional manual breaks for the color scale

  tmap::tmap_mode("plot")

  if (inherits(data, "SpatRaster")) {
    tmap::tm_shape(data) +
      tmap::tm_raster(
        col = col,
        title = title,
        palette = palette,
        breaks = breaks
      ) +
      tmap::tm_layout(
        frame = FALSE,
        legend.outside = TRUE
      )
  } else {
    tmap::tm_shape(data) +
      tmap::tm_fill(
        col = col,
        title = title,
        palette = palette,
        breaks = breaks
      ) +
      tmap::tm_borders(lwd = 0.3) +
      tmap::tm_layout(
        frame = FALSE,
        legend.outside = TRUE
      )
  }
}
