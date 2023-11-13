# cropmbtiles
a bash script that uses gdal and sqlite3 to crop .mbtiles files using a polygon shapefile.

## Background
You have a mbtiles file and want to crop a region and possibly even want to reduce the maximum zoom level or increase compression in order to save diskspace. 

## Prerequisites
gdal and sqlite3 installed. Polygon shapefile specifying region of interest.

## Usage:
download/clone script, edit variables (2 filepaths, maxZoom and minZoom) in the first section and run. Change optional parameters if you like. Output files will be generated in the directory the script is running in. 
