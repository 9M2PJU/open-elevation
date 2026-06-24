#!/usr/bin/env bash

set -eu

WGET_FLAGS="--continue --tries=3 --timeout=30"

download_rar() {
    url="$1"
    output="$2"

    wget $WGET_FLAGS -O "$output" "$url"
}

download_rar https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_NE_250m_TIF.rar SRTM_NE_250m_TIF.rar
download_rar https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_SE_250m_TIF.rar SRTM_SE_250m_TIF.rar
download_rar https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_W_250m_TIF.rar SRTM_W_250m_TIF.rar

unar -f SRTM_NE_250m_TIF.rar
unar -f SRTM_SE_250m_TIF.rar
unar -f SRTM_W_250m_TIF.rar
