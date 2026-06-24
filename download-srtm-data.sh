#!/usr/bin/env bash

set -eu

WGET_FLAGS="--continue --tries=3 --timeout=30 --progress=bar:force:noscroll"
STATUS_INTERVAL="${OPEN_ELEVATION_DOWNLOAD_STATUS_INTERVAL:-15}"
PARALLEL_DOWNLOADS="${OPEN_ELEVATION_PARALLEL_DOWNLOADS:-true}"

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

download_rar_background() {
    url="$1"
    output="$2"
    log_file="$3"

    {
        echo "Starting $output"
        if [ -f "$output" ]; then
            echo "Existing partial/full file: $output ($(file_size "$output"))"
            echo "Resuming if needed..."
        fi
        wget $WGET_FLAGS -O "$output" "$url"
        echo "Downloaded $output ($(file_size "$output"))"
    } > "$log_file" 2>&1 &
    DOWNLOAD_PID="$!"
}

print_download_status() {
    echo
    echo "Download status ($(date +%H:%M:%S))"
    printf '%-24s %-12s %s\n' "Archive" "Size" "Status"
    printf '%-24s %-12s %s\n' "-------" "----" "------"

    for i in "${!OUTPUTS[@]}"; do
        process_state="$(ps -o stat= -p "${PIDS[$i]}" 2>/dev/null || true)"
        if [ -f "${DONE_FILES[$i]}" ]; then
            status="complete"
        elif [ -n "$process_state" ] && [ "${process_state#Z}" = "$process_state" ]; then
            status="downloading"
        else
            status="finishing"
        fi
        printf '%-24s %-12s %s\n' "${OUTPUTS[$i]}" "$(file_size "${OUTPUTS[$i]}")" "$status"
    done
}

wait_for_parallel_downloads() {
    remaining="${#PIDS[@]}"

    while [ "$remaining" -gt 0 ]; do
        print_download_status

        for i in "${!PIDS[@]}"; do
            if [ -f "${DONE_FILES[$i]}" ]; then
                continue
            fi

            process_state="$(ps -o stat= -p "${PIDS[$i]}" 2>/dev/null || true)"
            if [ -n "$process_state" ] && [ "${process_state#Z}" = "$process_state" ]; then
                continue
            fi

            if wait "${PIDS[$i]}"; then
                touch "${DONE_FILES[$i]}"
                remaining=$((remaining - 1))
            else
                echo
                echo "Download failed: ${OUTPUTS[$i]}"
                echo "Last log lines:"
                tail -n 40 "${LOG_FILES[$i]}" || true
                exit 1
            fi
        done

        if [ "$remaining" -gt 0 ]; then
            sleep "$STATUS_INTERVAL"
        fi
    done

    print_download_status
}

extract_rar() {
    archive="$1"

    section "Extracting $archive"
    unar -f "$archive"
    echo "Extracted $archive"
}

URLS=(
    "https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_NE_250m_TIF.rar"
    "https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_SE_250m_TIF.rar"
    "https://srtm.csi.cgiar.org/wp-content/uploads/files/250m/SRTM_W_250m_TIF.rar"
)
OUTPUTS=(
    "SRTM_NE_250m_TIF.rar"
    "SRTM_SE_250m_TIF.rar"
    "SRTM_W_250m_TIF.rar"
)
PIDS=()
LOG_FILES=()
DONE_FILES=()

section "Open-Elevation SRTM download"
if [ "$PARALLEL_DOWNLOADS" = "true" ]; then
    echo "Parallel downloads: enabled"
    echo "Status refresh: every ${STATUS_INTERVAL}s"
    LOG_DIR=".download-logs"
    rm -rf "$LOG_DIR"
    mkdir -p "$LOG_DIR"

    for i in "${!URLS[@]}"; do
        output="${OUTPUTS[$i]}"
        log_file="$LOG_DIR/${output}.log"
        done_file="$LOG_DIR/${output}.done"
        LOG_FILES+=("$log_file")
        DONE_FILES+=("$done_file")
        download_rar_background "${URLS[$i]}" "$output" "$log_file"
        PIDS+=("$DOWNLOAD_PID")
    done

    wait_for_parallel_downloads
    rm -rf "$LOG_DIR"
else
    echo "Parallel downloads: disabled"
    for i in "${!URLS[@]}"; do
        download_rar "${URLS[$i]}" "${OUTPUTS[$i]}"
    done
fi

extract_rar SRTM_NE_250m_TIF.rar
extract_rar SRTM_SE_250m_TIF.rar
extract_rar SRTM_W_250m_TIF.rar

section "Download and extraction complete"
