#!/bin/bash

##################################
## variables needed to be set: ###
##################################

# input filenames
mbtile_original=/path/to/original_map.mbtiles
polygon=/path/to/shape.shp

# desired maximum and minimum zoomlevel of output
maxZoom=13
minZoom=9

##################################
### variables that can be set ####
#################################

# possible formats = PNG, PNG8, JPEG
#  n.b.: PNG uses ZLEVEL_1-9, which has nothing to do with zoomlevel. JPEG uses QUALITY=1-100, PNG8 uses DITHER=[YES/NO]
# also, JPEG is smaller, yet doesn't have transparency
# NO need to uncomment unnecessary options, i.e. you can leave ZLEVEL set to 6 and still use PNG8, which doesn't use it.
format=PNG8
ZLEVEL=6 # default=6
QUALITY=75 # default=75
DITHER=NO # default=NO

# native max zoomlevel of mbtiles file
# done automatically with gdalinfo
ginfo=$(gdalinfo $mbtile_original)
nativeMaxZoom=$(echo $ginfo | sed -n "s/^.*maxzoom=\(\S*\).*$/\1/p")

# uncomment to set manually
# nativeMaxZoom=16



# maxímum resolution of input:
# get maximum resolution automatically from gdalinfo
maxRes=$(echo $ginfo | sed -n "s/^.*Pixel Size = (\(\S*\),.*$/\1/p")

# alternatively, this can be calculated with formula:
# according to: https://wiki.openstreetmap.org/wiki/Zoom_levels 
# formula (easily readable):
#(circ*cos(0))/2^(0+8)
circ=40075017
term1=$(echo 2^$(echo $nativeMaxZoom+8 | bc) | bc)
# uncomment the following line to calculate maxiumum resolution by formula 
#maxRes=$(echo $circ/$term1 | bc -l)



###################################
##### no changes from here on #####
###################################

echo 'native maximum resolution:' $maxRes

diffZoom=$(echo $nativeMaxZoom-$maxZoom | bc)
mult=$(echo 2^$diffZoom | bc)
ans=$(echo $maxRes*$mult | bc)

steps=$(echo $maxZoom-$minZoom | bc)


n=0

if [[ $nativeMaxZoom == $maxZoom ]] ;then
	
	echo "NO change in maximum zoom level!"
	gdalwarp -overwrite -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$maxZoom.vrt
	gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" -co "QUALITY="$QUALITY"" -co "DITHER="$DITHER""  "lvl"$maxZoom".vrt" "map.mbtiles"
	echo '"lvl'$(echo $maxZoom-$n | bc)'.vrt"'
	
	while [[ $n -lt $steps  ]]
        do
        ans=$(echo $ans *2 | bc)
        gdalwarp -overwrite -ovr $n -tr $ans $ans -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$(echo $maxZoom -$n-1 | bc).vrt
        gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" -co "QUALITY="$QUALITY"" -co "DITHER="$DITHER"" "lvl"$(echo $maxZoom-$n-1| bc)".vrt" "lvl"$(echo $maxZoom-$n-1| bc)".mbtiles"
        echo '"lvl'$(echo $maxZoom-$n-1| bc)'.vrt"'
        (( n++ ))
	done
	
else
	ovr=$(echo $diffZoom - 1 | bc)
        echo "Change in maximum zoom level!"
	echo 'Highest resolution in new file:' $ans
	gdalwarp -overwrite -ovr $ovr -tr $ans $ans -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$maxZoom.vrt	
	gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" -co "QUALITY="$QUALITY"" -co "DITHER="$DITHER"" "lvl"$maxZoom".vrt" "map.mbtiles"	
	
	while [[ $n -lt $steps  ]]
        do
	(( ovr++ ))
        (( n++ ))
	ans=$(echo $ans *2 | bc)
        gdalwarp -overwrite -ovr $ovr -tr $ans $ans -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$(echo $maxZoom -$n | bc).vrt
        gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" -co "QUALITY="$QUALITY"" -co "DITHER="$DITHER"" "lvl"$(echo $maxZoom-$n | bc)".vrt" "lvl"$(echo $maxZoom-$n | bc)".mbtiles"
        echo '"lvl'$(echo $maxZoom-$n | bc)'.vrt"'
        done

fi	

# rm .vrt files
 rm *.vrt


# build SQLite Query
c=0
query=$(
    echo '.open map.mbtiles'
for file in lvl*.mbtiles; do
    echo "ATTACH \"$file\" AS db$c;"
    echo "INSERT INTO main.tiles SELECT * FROM db$c.tiles;"
    (( c++ ))
done
    echo "UPDATE metadata SET value = $minZoom WHERE name = 'minzoom' AND value = $maxZoom;"
    echo "REINDEX;"
    echo "VACUUM;"
    echo ".exit"
)

# uncomment to see sqlite3 command
# cat <<< $var


# Pipe SQLite Query into sqlite3
echo "$query" | sqlite3

