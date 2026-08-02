#!/usr/bin/env bash
# Aria-Ariang Server (Lite Version) - Download Error Event Handler
# Triggered by Aria2 on download error (on-download-error).

set -euo pipefail

GID="${1:-Unknown}"
FILE_COUNT="${2:-0}"
FILE_PATH="${3:-Unknown}"

LOG_FILE="/config/upload.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR_HOOK] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR_HOOK] $1"
}

log "Download failed for GID: $GID, Path: $FILE_PATH"

# Send Telegram alert
if [ -f "$SCRIPT_DIR/telegram.sh" ]; then
    MSG="⚠️ *Download Error Report*
*File Path:* \`${FILE_PATH}\`
*GID:* \`${GID}\`
*File Count:* \`${FILE_COUNT}\`
*Time:* \`$(date '+%Y-%m-%d %H:%M:%S')\`"
    
    "$SCRIPT_DIR/telegram.sh" "$MSG" "Markdown" || true
fi

exit 0
