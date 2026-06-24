#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${OPEN_ELEVATION_DATA_DIR:-/code/data}"
AUTO_DOWNLOAD="${OPEN_ELEVATION_AUTO_DOWNLOAD_DATA:-true}"
AUTO_BUILD_REGION="${OPEN_ELEVATION_AUTO_BUILD_REGION:-false}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$DATA_DIR"

if [ "$AUTO_BUILD_REGION" = "true" ] && ! find "$DATA_DIR" -maxdepth 1 -name '*.tif' -print -quit | grep -q .; then
    echo "No GeoTIFF files found in $DATA_DIR; building a regional dataset."
    "$SCRIPT_DIR/create-region-dataset.sh"
elif [ "$AUTO_DOWNLOAD" = "true" ] && ! find "$DATA_DIR" -maxdepth 1 -name '*.tif' -print -quit | grep -q .; then
    echo "No GeoTIFF files found in $DATA_DIR; downloading the whole-world SRTM dataset."
    "$SCRIPT_DIR/create-dataset.sh"
fi

exec "$@"
