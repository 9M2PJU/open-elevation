#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${OPEN_ELEVATION_DATA_DIR:-/code/data}"
AUTO_DOWNLOAD="${OPEN_ELEVATION_AUTO_DOWNLOAD_DATA:-true}"
AUTO_BUILD_REGION="${OPEN_ELEVATION_AUTO_BUILD_REGION:-false}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$DATA_DIR"

has_any_geotiff() {
    find "$DATA_DIR" -maxdepth 1 -name '*.tif' -print -quit | grep -q .
}

has_runtime_tiles() {
    find "$DATA_DIR" -maxdepth 1 -regextype posix-extended -regex '.*/.*_[0-9]+_[0-9]+\.tif' -print -quit | grep -q .
}

has_raw_world_rasters() {
    find "$DATA_DIR" -maxdepth 1 \( \
        -name 'SRTM_NE_250m.tif' -o \
        -name 'SRTM_SE_250m.tif' -o \
        -name 'SRTM_W_250m.tif' \
    \) -print -quit | grep -q .
}

if [ "$AUTO_BUILD_REGION" = "true" ] && ! has_runtime_tiles; then
    echo "Open-Elevation dataset mode: regional"
    echo "No tiled runtime GeoTIFF files found in $DATA_DIR; building a regional dataset."
    "$SCRIPT_DIR/create-region-dataset.sh"
elif [ "$AUTO_DOWNLOAD" = "true" ] && ! has_runtime_tiles; then
    echo "Open-Elevation dataset mode: whole world"
    if has_raw_world_rasters; then
        echo "Found raw SRTM source rasters but no tiled runtime dataset."
        echo "Building tiles before starting the API."
    elif has_any_geotiff; then
        echo "Found GeoTIFF files, but none look like Open-Elevation tiled runtime data."
        echo "Building the whole-world tiled dataset before starting the API."
    else
        echo "No GeoTIFF files found in $DATA_DIR; downloading the whole-world SRTM dataset."
    fi
    "$SCRIPT_DIR/create-dataset.sh"
elif has_runtime_tiles; then
    echo "Open-Elevation dataset mode: existing data"
    echo "Found tiled runtime GeoTIFF files in $DATA_DIR; skipping dataset download/build."
else
    echo "Open-Elevation dataset mode: no automatic dataset build"
    echo "No tiled runtime GeoTIFF files found in $DATA_DIR."
fi

exec "$@"
