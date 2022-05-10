geoplyr: Working with spatial data inside dataframes

Given the advent of nested dataframes (tidyr) and purrr tools, can spatial data be stored in columns of dataframes such that dplyr tools can be used?

In addition to this, other parallel solutions we are discussing:
- geojson/turf/lawn workflow that does not depend on rgdal or sp and provides a lightweight way to work with the most common spatial workflows
- making R spatial tools work nicely with SQL (ala PostGIS)
