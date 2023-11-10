#!/bin/bash

##################################
## variables needed to be set: ###
##################################

# Filenames
mbtile_original=/media/fridtjof/ELEMENTS/skitourenguru/originals/AU_SG_TOPO15_MINI4.1.mbtiles
polygon=/media/fridtjof/ELEMENTS/skitourenguru/originals/polygone/Suedtirol.shp

# native max zoomlevel of mbtiles file
nativeMaxZoom=15

# desired max zoomlevel and gdal_translate ZLEVEL (if TILE_FORMAT=PNG is used). Please note: ZLEVEL has nothing to do with zoom-level!
maxZoom=15
minZoom=9
format=PNG8
ZLEVEL=6

###################################
##### no changes from here on #####
###################################

# calculate pixel-per-meter resolution (at equator?) for zoom levels, needed for gdal_translate (?)
# according to: https://wiki.openstreetmap.org/wiki/Zoom_levels 
# (approx.) circumreference of earth in meters

circ=40075017

# formula (easily readable):
#(circ*cos(0))/2^(0+8)

term1=$(echo 2^$(echo $nativeMaxZoom+8 | bc) | bc)
calcMaxRes=$(echo $circ/$term1 | bc -l)

echo 'native maximum resolution:' $calcMaxRes

diffZoom=$(echo $nativeMaxZoom-$maxZoom | bc)
mult=$(echo 2^$diffZoom | bc)
ans=$(echo $calcMaxRes*$mult | bc)

steps=$(echo $maxZoom-$minZoom | bc)


n=0

if [[ $nativeMaxZoom == $maxZoom ]] ;then
	
	echo "NO change in maximum zoom level!"
	gdalwarp -overwrite -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$maxZoom.vrt
	gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" "lvl"$maxZoom".vrt" "map.mbtiles"
	echo '"lvl'$(echo $maxZoom-$n | bc)'.vrt"'
	
	while [[ $n -lt $steps  ]]
        do
        ans=$(echo $ans *2 | bc)
        gdalwarp -overwrite -ovr $n -tr $ans $ans -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$(echo $maxZoom -$n-1 | bc).vrt
        gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" "lvl"$(echo $maxZoom-$n-1| bc)".vrt" "lvl"$(echo $maxZoom-$n-1| bc)".mbtiles"
        echo '"lvl'$(echo $maxZoom-$n-1| bc)'.vrt"'
        (( n++ ))
	done
	
else
	ovr=$(echo $diffZoom - 1 | bc)
        echo "Change in maximum zoom level!"
	echo 'Highest resolution in new file:' $ans
	gdalwarp -overwrite -ovr $ovr -tr $ans $ans -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$maxZoom.vrt	
	gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" "lvl"$maxZoom".vrt" "map.mbtiles"	
	
	while [[ $n -lt $steps  ]]
        do
	(( ovr++ ))
        (( n++ ))
	ans=$(echo $ans *2 | bc)
        gdalwarp -overwrite -ovr $ovr -tr $ans $ans -of vrt -cutline $polygon -crop_to_cutline $mbtile_original lvl$(echo $maxZoom -$n | bc).vrt
        gdal_translate -of mbtiles -co "TILE_FORMAT=$format" -co "ZLEVEL="$ZLEVEL"" "lvl"$(echo $maxZoom-$n | bc)".vrt" "lvl"$(echo $maxZoom-$n | bc)".mbtiles"
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

