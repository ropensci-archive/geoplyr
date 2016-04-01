# example spatial operations in R

# devtools::install_github("hrbrmstr/albersusa") # for us data
library(sp) # for spatial data classes
library(jsonlite) # for jsons
library(raster) # for splitting polygons
library(tmap) # for vis

# get points data
download.file("https://data.sfgov.org/resource/w969-5mn4.json", "data/w969-5mn4.json")
p = fromJSON("https://data.sfgov.org/resource/w969-5mn4.json")
p_orig = p
p = SpatialPoints(coords = cbind(as.numeric(p$latitude$longitude), as.numeric(p$latitude$latitude)))

# get and explore polygon data
sf = albersusa::counties_composite()
sf = sf[sf$name == "San Francisco",]
plot(sf)
points(sf@polygons[[1]]@Polygons[[1]]@coords) # where the points are stashed
# extract just the main polygon
sf = SpatialPolygons(list(Polygons(list(sf@polygons[[1]]@Polygons[[4]]), ID = "1")))
plot(sf, col = "red", add = T)
plot(p)

# split sf into pieces
# sf4 = geoaxe::chop(sf, size = 10) # not working for now...
r <- raster(x = sf, ncols = 3, nrows = 3)
sf9 = as(r, "SpatialPolygons")
plot(sf9, add = T)
r = raster(x = sf, ncols = 4, nrows = 4)
sf16 = as(r, "SpatialPolygons")
plot(sf16, add = T)

# spatial operations
# spatial subsetting
p_subset = p[sf9[1,]]
points(p_subset)

# spatial aggregation (points in polygon)
sf9_point_count = aggregate(p ~ sf9, FUN = length)
p = SpatialPointsDataFrame(p, p_orig[1:5])
sf9_point_count = aggregate(p["spaces"], by = sf9, FUN = length)
qtm(sf9_point_count, "spaces")

# cut SpatialPolygons 
plot(sf)
plot(sf9[1,], add = T)
sf_subset = rgeos::gIntersection(sf, sf9[1,])
plot(sf_subset, col = "green", add = T)
