# Setup -------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

library(rgeos)
library(sp)
library(rgdal)
library(maptools)
library(leaflet)

library(tigris)
library(acs)


# Load data ---------------------------------------------------------------

attach('rdata/county_shapes_simp.rda')
attach('rdata/sub_stops.rda')

# Get transit stop locations ----------------------------------------------

#' Get transit stop locations for an agency or agencies
#' 
#' @param agency A character vector of one or more agency names (matching short_name)
#' 
#' @return An object of class SpatialPoints
#' 
#' @export

get_stops <- function(agency) {
  
  stops_df <- all_stops_df %>%
    filter(short_name %in% agency)
  
  stops_spt <- SpatialPoints(data.frame(stops_df[, c('longitude', 'latitude')]), proj4string = CRS("+proj=longlat"))
  
  return(stops_spt)
  
}


# Create a shape around all stop locations --------------------------------

#' Create a shape around a collection of points based on a given radius
#' 
#' @param stops_sp An object of class SpatialPoints
#' @param radius Radius for circle around points, in miles
#' 
#' @return An object of class SpatialPolygons outlining the area covered by the radius
#' 
#' @export

make_stop_shape <- function(stops_spt, radius) {
  
  # convert radius to meters
  radius_m <- radius * 1609.34
  
  # convert projection
  stops_spt <- spTransform(stops_spt, CRS("+init=epsg:3395"))
  
  # get shape(s) of buffered stops
  buffered_spy <- gBuffer(stops_spt, width = radius_m)
  
  # convert back to lat/long
  stop_shape_spy <- spTransform(buffered_spy, CRS("+proj=longlat"))
  
  return(stop_shape_spy)
  
}

# Get all census BGs that overlaps with the stop shape --------------------

get_bg <- function(stop_shape_spy, counties_spdf = bb_spdf) {
  
  # Harmonize CRS
  counties_spdf <- spTransform(counties_spdf, proj4string(stop_shape_spy))
  
  # Get character vectors of FIPS codes for the counties overlapping the stop shape and the state
  overlaps_county <- gOverlaps(spgeom1 = stop_shape_spy, spgeom2 = counties_spdf, byid = TRUE)
  within_county <- gWithin(spgeom1 = stop_shape_spy, spgeom2 = counties_spdf, byid = TRUE)
  counties_overlapped <- unique(
    c(as.character(counties_spdf@data$COUNTY[overlaps_county]), 
      as.character(counties_spdf@data$COUNTY[within_county]))
  )
  
  state_ind <- overlaps_county | within_county
  state_overlapped <- unique(c(as.character(counties_spdf@data$STATE[state_ind])))
  
  if (length(state_overlapped) > 1) stop('Multiple states not yet handled.')
  if (length(state_overlapped) == 0) stop('No U.S. county overlapped detected.')
  
  # block group shapes for all relevant counties
  my_bg <- block_groups(state = state_overlapped, county = counties_overlapped)
  
  # reprojected block group shapes for all relevant counties (1006)
  new_bg <- spTransform(my_bg, proj4string(stop_shape_spy))
  
  # sub_sb is the reprojected block group shapes that overlap with the stop shape (628)
  bg_include <- gIntersects(stop_shape_spy, new_bg, byid = TRUE) # This is the index based on new_bg
  sub_bg <- new_bg[new_bg$GEOID %in% new_bg$GEOID[bg_include], ]
  
}


# Find intersection of block groups with stop shape -----------------------

get_intersect <- function(stop_shape_spy, bg_spdf) {
  
  gIntersection(stop_shape_spy, bg_spdf, byid = TRUE)
  
}


# Find pct area overlap for bg/stop shape by bg ---------------------------

get_area <- function(bg_spdf, intersect_spy) {
  
  proj_intersect_spy <- spTransform(intersect_spy, CRS("+proj=utm +zone=17 +datum=WGS84"))
  
  intersect_area <- gArea(proj_intersect_spy, byid = TRUE)
  
  proj_bg_spdf <- spTransform(bg_spdf, CRS("+proj=utm +zone=17 +datum=WGS84"))
  bg_area <- gArea(proj_bg_spdf, byid = TRUE)
  
  data_frame(intersect_area = intersect_area,
             bg_area = bg_area) %>%
    mutate(bg_geoid = bg_spdf@data$GEOID) %>%
    mutate(pct_area = round(100 * intersect_area / bg_area, 1)) %>%
    mutate(bg_within = pct_area >= 100)
  
}
