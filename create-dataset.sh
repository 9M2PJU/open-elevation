#!/usr/bin/env bash

set -eu

OUTDIR="${OPEN_ELEVATION_DATA_DIR:-/code/data}"
if [ ! -d "$OUTDIR" ] ; then
    echo "$OUTDIR does not exist!"
    exit 1
fi

CUR_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_TIME="$(date +%s)"

section() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

file_size() {
    if [ -f "$1" ]; then
        du -h "$1" | awk '{print $1}'
    else
        echo "missing"
    fi
}

cd "$OUTDIR"
section "Open-Elevation whole-world dataset build"
echo "Data directory: $OUTDIR"
echo "This downloads, extracts, and tiles the SRTM 250m dataset."

"$SCRIPT_DIR/download-srtm-data.sh"

ensure_raster() {
    raster="$1"

    if [ -f "$raster" ]; then
        echo "Found raster $raster ($(file_size "$raster"))"
        return 0
    fi

    extracted_path="$(find . -mindepth 2 -maxdepth 2 -type f -name "$raster" -print -quit)"
    if [ -n "$extracted_path" ]; then
        echo "Moving extracted raster $extracted_path to $OUTDIR/$raster"
        mv "$extracted_path" "$raster"
        echo "Ready raster $raster ($(file_size "$raster"))"
    fi

    if [ ! -f "$raster" ]; then
        echo "Expected raster $raster was not found after download/extraction."
        echo "Check the extracted archive layout in $OUTDIR."
        exit 1
    fi
}

section "Preparing extracted rasters"
ensure_raster SRTM_NE_250m.tif
ensure_raster SRTM_SE_250m.tif
ensure_raster SRTM_W_250m.tif

section "Tiling northern/eastern hemisphere raster"
"$SCRIPT_DIR/create-tiles.sh" SRTM_NE_250m.tif 10 10

section "Tiling southern/eastern hemisphere raster"
"$SCRIPT_DIR/create-tiles.sh" SRTM_SE_250m.tif 10 10

section "Tiling western hemisphere raster"
"$SCRIPT_DIR/create-tiles.sh" SRTM_W_250m.tif 10 20

section "Cleaning temporary archives and source rasters"
rm -rf SRTM_NE_250m.tif SRTM_SE_250m.tif SRTM_W_250m.tif *.rar
rm -rf SRTM_NE_250m_TIF SRTM_SE_250m_TIF SRTM_W_250m_TIF

END_TIME="$(date +%s)"
ELAPSED="$((END_TIME - START_TIME))"
section "Whole-world dataset build complete"
echo "Generated GeoTIFF tiles: $(find "$OUTDIR" -maxdepth 1 -name '*.tif' | wc -l)"
echo "Elapsed time: ${ELAPSED}s"

cd "$CUR_DIR"
