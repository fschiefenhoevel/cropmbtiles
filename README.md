# cropmbtiles
a bash script that uses gdal and sqlite3 to crop .mbtiles files using custom polygon shapefiles.

## Background
You have mbtiles and want to crop certain regions and possibly even want to reduce the maximum zoom level in order to save diskspace. 

## Prerequisites
gdal and sqlite3 installed. Polygon shapefile specifying region of interest.

## Usage:
download/clone script, edit variables in the first section and run. Output files will by default be generated in the directory the script is running in.

## Issues:
I deliberately did not use gdalinfo to extract infos (minZoom, maxZoom etc.) from the .mbtiles metadata table since this info might be wrong. 
