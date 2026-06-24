#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${OPEN_ELEVATION_DATA_DIR:-/code/data}"
AUTO_DOWNLOAD="${OPEN_ELEVATION_AUTO_DOWNLOAD_DATA:-true}"

mkdir -p "$DATA_DIR"

if [ "$AUTO_DOWNLOAD" = "true" ] && ! find "$DATA_DIR" -maxdepth 1 -name '*.tif' -print -quit | grep -q .; then
    echo "No GeoTIFF files found in $DATA_DIR; downloading the whole-world SRTM dataset."
    /code/create-dataset.sh
fi

exec "$@"
