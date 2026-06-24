#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${OPEN_ELEVATION_SOURCE_DATA_DIR:-/code/source-data}"
OUTDIR="${OPEN_ELEVATION_DATA_DIR:-/code/data}"
XTILES="${OPEN_ELEVATION_REGION_X_TILES:-4}"
YTILES="${OPEN_ELEVATION_REGION_Y_TILES:-4}"
REGION_RASTER="$OUTDIR/open_elevation_region.tif"

missing=()
for name in \
    OPEN_ELEVATION_REGION_MIN_LATITUDE \
    OPEN_ELEVATION_REGION_MAX_LATITUDE \
    OPEN_ELEVATION_REGION_MIN_LONGITUDE \
    OPEN_ELEVATION_REGION_MAX_LONGITUDE
do
    if [ -z "${!name:-}" ]; then
        missing+=("$name")
    fi
done

if [ "${#missing[@]}" -gt 0 ]; then
    echo "Regional dataset mode requires these bounding-box values:"
    printf '  - %s\n' "${missing[@]}"
    echo
    echo "Fill them in docker-compose.yml, or disable regional mode with:"
    echo '  OPEN_ELEVATION_AUTO_BUILD_REGION: "false"'
    exit 64
fi

MIN_LON="$OPEN_ELEVATION_REGION_MIN_LONGITUDE"
MIN_LAT="$OPEN_ELEVATION_REGION_MIN_LATITUDE"
MAX_LON="$OPEN_ELEVATION_REGION_MAX_LONGITUDE"
MAX_LAT="$OPEN_ELEVATION_REGION_MAX_LATITUDE"

mkdir -p "$OUTDIR"
rm -f "$OUTDIR/summary.json"

if ! find "$SOURCE_DIR" -maxdepth 1 -name '*.tif' -print -quit | grep -q .; then
    echo "No source GeoTIFF files found in $SOURCE_DIR."
    echo "Put source .tif files in ./source-data before enabling regional mode."
    exit 1
fi

echo "Building regional dataset from $SOURCE_DIR"
echo "Bounding box: longitude $MIN_LON..$MAX_LON, latitude $MIN_LAT..$MAX_LAT"

SOURCE_FILES=()
while IFS= read -r file; do
    SOURCE_FILES+=("$file")
done < <(find "$SOURCE_DIR" -maxdepth 1 -name '*.tif' -print | sort)

gdalwarp \
    -overwrite \
    -te "$MIN_LON" "$MIN_LAT" "$MAX_LON" "$MAX_LAT" \
    -of GTiff \
    "${SOURCE_FILES[@]}" \
    "$REGION_RASTER"

"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/create-tiles.sh" "$REGION_RASTER" "$XTILES" "$YTILES"
rm -f "$REGION_RASTER"
