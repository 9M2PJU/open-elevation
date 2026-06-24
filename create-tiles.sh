#!/usr/bin/env bash
# Original Source: https://github.com/mapbox/gdal-polygonize-test
set -eu

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <raster.tif> <x-tiles> <y-tiles>"
    exit 1
fi

raster=$1
xtiles=$2
ytiles=$3
total_tiles=$((xtiles * ytiles))
tile_number=0

if [ ! -f "$raster" ]; then
    echo "Raster file not found: $raster"
    exit 1
fi

# get raster bounds
ul=($(gdalinfo "$raster" | grep '^Upper Left' | sed -e 's/[a-zA-Z ]*(//' -e 's/).*//' -e 's/,/ /'))
lr=($(gdalinfo "$raster" | grep '^Lower Right' | sed -e 's/[a-zA-Z ]*(//' -e 's/).*//' -e 's/,/ /'))

if [ "${#ul[@]}" -lt 2 ] || [ "${#lr[@]}" -lt 2 ]; then
    echo "Could not read raster bounds from $raster"
    exit 1
fi

xmin=${ul[0]}
xsize=$(echo "${lr[0]} - $xmin" | bc)
ysize=$(echo "${ul[1]} - ${lr[1]}" | bc)

xdif=$(echo "$xsize/$xtiles" | bc -l)

echo "Raster: $raster"
echo "Bounds: upper-left (${ul[0]}, ${ul[1]}), lower-right (${lr[0]}, ${lr[1]})"
echo "Tile grid: ${xtiles} x ${ytiles} (${total_tiles} tiles)"

for x in $(eval echo {0..$(($xtiles-1))}); do
    xmax=$(echo "$xmin + $xdif" | bc)
    ymax=${ul[1]}
    ydif=$(echo "$ysize/$ytiles" | bc -l)

    for y in $(eval echo {0..$((ytiles-1))}); do
        ymin=$(echo "$ymax - $ydif" | bc)
        tile_number=$((tile_number + 1))
        percent=$((tile_number * 100 / total_tiles))
        output="${raster%.tif}_${x}_${y}.tif"

        printf '[%3d%%] Tile %d/%d -> %s\n' "$percent" "$tile_number" "$total_tiles" "$output"

        # Create chunk of source raster
        gdal_translate -q \
            -projwin $xmin $ymax $xmax $ymin \
            -of GTiff \
            "$raster" "$output"

        ymax=$ymin
    done
    xmin=$xmax
done

echo "Finished tiling $raster"
