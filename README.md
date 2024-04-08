# cropmbtiles
a bash script that uses gdal and sqlite3 to crop a raster mbtiles file using a polygon shapefile. Original zoom levels are kept.

## Background
You have an mbtiles file and want to crop a region and possibly even want to reduce the maximum zoom level or increase compression in order to save diskspace. Using GDAL Raster Extraction (within QGIS for example) gives you only the original's (one) maximum zoom level and loses all the existing lower zoom levels which might actually be cleverly designed when it comes to their level of detail. 

## Prerequisites
gdal and sqlite3 installed. Polygon shapefile (.shp) specifying region of interest, created by QGIS for example.

## Usage:
download/clone script, make executable, edit variables (2 filepaths, maxZoom and minZoom) in the first section and run. Change optional parameters if you like. Output files will be generated in the directory the script is running in. Every zoomlevel between minZoom and maxZoom is created (lvl*.mbtiles) additionally to the composite map.mbtiles (which is the final map with every zoomlevel). Delete the superfluous lvl*.mbtiles manually after running the script.
