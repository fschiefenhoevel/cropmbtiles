# cropmbtiles
a bash script that uses gdal and sqlite3 to crop .mbtiles files using a polygon shapefile.

## Background
You have an mbtiles file and want to crop a region and possibly even want to reduce the maximum zoom level or increase compression in order to save diskspace. Using GDAL Raster Extraction (within QGIS for example) gives you only the original's (one) maximum zoom level, loses all the existing lower zoom levels which might actually be cleverly designed in what level of detail they show and (by default) creates no new overviews.

## Prerequisites
gdal and sqlite3 installed. Polygon shapefile specifying region of interest.

## Usage:
download/clone script, edit variables (2 filepaths, maxZoom and minZoom) in the first section and run. Change optional parameters if you like. Output files will be generated in the directory the script is running in. Every zoomlevel is created (lvl*.mbtiles) additionally to the composite map.mbtiles (which is the final map with every zoomlevel). Delete lvl*.mbtiles manually after running the script.
