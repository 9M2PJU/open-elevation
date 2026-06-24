#!/usr/bin/env bash

set -eu

WGET_FLAGS="--continue --tries=3 --timeout=30 --progress=bar:force:noscroll"

section() {
    echo
    echo "==> $1"
}

file_size() {
    if [ -f "$1" ]; then
        du -h "$1" | awk '{print $1}'
    else
        echo "0"
    fi
}

download_rar() {
    url="$1"
    output="$2"

    section "Downloading $output"
    if [ -f "$output" ]; then
        echo "Existing partial/full file: $output ($(file_size "$output"))"
        echo "Resuming if needed..."
    fi

    wget $WGET_FLAGS -O "$output" "$url"
    echo "Downloaded $output ($(file_size "$output"))"
}

extract_rar() {
    archive="$1"

    section "Extracting $archive"
    unar -f "$archive"
    echo "Extracted $archive"
}

section "Open-Elevation SRTM download"
download_rar https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_NE_250m_TIF.rar SRTM_NE_250m_TIF.rar
download_rar https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_SE_250m_TIF.rar SRTM_SE_250m_TIF.rar
download_rar https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_W_250m_TIF.rar SRTM_W_250m_TIF.rar

extract_rar SRTM_NE_250m_TIF.rar
extract_rar SRTM_SE_250m_TIF.rar
extract_rar SRTM_W_250m_TIF.rar

section "Download and extraction complete"
