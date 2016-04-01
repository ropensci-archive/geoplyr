# some example functions with gtfs data

# using stplanr
download.file("http://transitfeeds.com/p/bart/58/latest/download", "bart.zip")
bart = gtfs2sldf("bart.zip")
plot(bart)

# using gtfsr (early version)
devtools::install_github("ropenscilabs/gtfsr")
dir.create("bart")
library(readr)
file.copy("bart.zip", "bart/bart.zip")
unzip_gtfs("bart/bart.zip")
bart_list = read_gtfs("bart/")[[1]]
lapply(bart_list, function(x) "shape_id" %in% names(x))
lapply(bart_list, function(x) "route_id" %in% names(x))
lapply(bart_list, nrow)
library(dplyr)
validate_feed(bart_df)