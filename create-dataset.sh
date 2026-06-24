#!/usr/bin/env bash

set -eu

OUTDIR="${OPEN_ELEVATION_DATA_DIR:-/code/data}"
if [ ! -d "$OUTDIR" ] ; then
    echo "$OUTDIR does not exist!"
    exit 1
fi

CUR_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$OUTDIR"
"$SCRIPT_DIR/download-srtm-data.sh"

ensure_raster() {
    raster="$1"

    if [ -f "$raster" ]; then
        return 0
    fi

    extracted_path="$(find . -mindepth 2 -maxdepth 2 -type f -name "$raster" -print -quit)"
    if [ -n "$extracted_path" ]; then
        echo "Moving extracted raster $extracted_path to $OUTDIR/$raster"
        mv "$extracted_path" "$raster"
    fi

    if [ ! -f "$raster" ]; then
        echo "Expected raster $raster was not found after download/extraction."
        echo "Check the extracted archive layout in $OUTDIR."
        exit 1
    fi
}

ensure_raster SRTM_NE_250m.tif
ensure_raster SRTM_SE_250m.tif
ensure_raster SRTM_W_250m.tif

"$SCRIPT_DIR/create-tiles.sh" SRTM_NE_250m.tif 10 10
"$SCRIPT_DIR/create-tiles.sh" SRTM_SE_250m.tif 10 10
"$SCRIPT_DIR/create-tiles.sh" SRTM_W_250m.tif 10 20
rm -rf SRTM_NE_250m.tif SRTM_SE_250m.tif SRTM_W_250m.tif *.rar
rm -rf SRTM_NE_250m_TIF SRTM_SE_250m_TIF SRTM_W_250m_TIF

cd "$CUR_DIR"
