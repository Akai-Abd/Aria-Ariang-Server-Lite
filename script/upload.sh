#!/usr/bin/env bash
# Aria-Ariang Server (Lite Version) - Auto Upload Script
# Triggered by Aria2 on download completion.

set -euo pipefail

GID="${1:-}"
FILE_COUNT="${2:-}"
FILE_PATH="${3:-}"

LOG_FILE="/config/upload.log"
CLOUD_DEST_FILE="/config/cloud-destinations.json"
RCLONE_CONF="/config/rclone/rclone.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

notify_telegram() {
    if [ -f "$SCRIPT_DIR/telegram.sh" ]; then
        "$SCRIPT_DIR/telegram.sh" "$1" "${2:-Markdown}" || true
    fi
}

if [ -z "$FILE_PATH" ]; then
    log "[WARN] No file path provided to upload script. Exiting."
    exit 0
fi

# Determine top-level download target
DOWNLOAD_PATH="${FILE_PATH%/}"
RELATIVE_PATH="${DOWNLOAD_PATH#/downloads/}"
TOP_NAME="$(cut -d/ -f1 <<< "$RELATIVE_PATH")"
FINAL_TARGET="/downloads/$TOP_NAME"

if [ -z "$TOP_NAME" ] || [ ! -e "$FINAL_TARGET" ]; then
    log "[INFO] Target path does not exist or is invalid: $FINAL_TARGET"
    exit 0
fi

# Check for remaining control files (incomplete torrent batch)
CONTROL_COUNT=0
if [ -d "$FINAL_TARGET" ]; then
    CONTROL_COUNT=$(find "$FINAL_TARGET" -name "*.aria2" 2>/dev/null | wc -l)
fi
if [ -f "${FINAL_TARGET}.aria2" ]; then
    ((CONTROL_COUNT++)) || true
fi

if [ "$CONTROL_COUNT" -gt 0 ]; then
    log "[INFO] Download still in progress ($CONTROL_COUNT aria2 control files). Skipping upload for: $TOP_NAME"
    exit 0
fi

log "[INFO] Download complete for: $TOP_NAME (GID: $GID)"

# Send Telegram notification for Download Complete
notify_telegram "📥 *Download Complete*
*File/Folder:* \`${TOP_NAME}\`
*GID:* \`${GID}\`
*Path:* \`${FINAL_TARGET}\`
*Time:* \`$(date '+%Y-%m-%d %H:%M:%S')\`"

# Read destination from cloud-destinations.json
DEST=""
if [ -f "$CLOUD_DEST_FILE" ] && command -v jq >/dev/null 2>&1; then
    DEST=$(jq -r '.destinations[] | select(.enabled == true) | .remote + ":" + .path' "$CLOUD_DEST_FILE" 2>/dev/null | head -n 1)
fi

if [ -z "$DEST" ] || [ "$DEST" = "null:" ]; then
    log "[WARN] No active destination found in $CLOUD_DEST_FILE. Skipping upload."
    exit 0
fi

# Run Rclone CLI move
RCLONE_CMD=("rclone" "move" "$FINAL_TARGET")

if [ -d "$FINAL_TARGET" ]; then
    RCLONE_CMD+=("$DEST/$TOP_NAME")
else
    RCLONE_CMD+=("$DEST")
fi

if [ -f "$RCLONE_CONF" ]; then
    RCLONE_CMD+=("--config" "$RCLONE_CONF")
fi

RCLONE_CMD+=("--stats" "5s" "--fast-list" "-v")

log "[INFO] Executing: ${RCLONE_CMD[*]}"
if "${RCLONE_CMD[@]}"; then
    log "[SUCCESS] Successfully uploaded $TOP_NAME to $DEST"
    notify_telegram "☁️ *Upload Complete*
*File/Folder:* \`${TOP_NAME}\`
*Destination:* \`${DEST}\`
*Time:* \`$(date '+%Y-%m-%d %H:%M:%S')\`"
    rm -rf "$FINAL_TARGET" 2>/dev/null || true
else
    log "[ERROR] Failed to upload $TOP_NAME to $DEST"
    notify_telegram "❌ *Upload Failed Report*
*File/Folder:* \`${TOP_NAME}\`
*Destination:* \`${DEST}\`
*Time:* \`$(date '+%Y-%m-%d %H:%M:%S')\`"
    exit 1
fi
