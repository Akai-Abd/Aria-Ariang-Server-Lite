#!/usr/bin/env bash
# Aria-Ariang Server (Lite Version) - Storage Retention & Auto-Cleaner Script
# Ponytail: Zero-bloat storage retention cleaner using native bash, find, and curl.

set -euo pipefail

FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=true ;;
        --dry-run|-d) DRY_RUN=true ;;
    esac
done

DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"
MAX_DISK_USAGE_PCT="${MAX_DISK_USAGE_PCT:-85}"
RETENTION_DAYS="${RETENTION_DAYS:-3}"
LOG_FILE="${LOG_FILE:-/config/clean_retention.log}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

notify_telegram() {
    if [ -f "$SCRIPT_DIR/telegram.sh" ]; then
        "$SCRIPT_DIR/telegram.sh" "$1" "${2:-Markdown}" || true
    fi
}

if [ ! -d "$DOWNLOAD_DIR" ]; then
    log "[WARN] Download directory $DOWNLOAD_DIR does not exist."
    exit 0
fi

# Calculate initial disk usage
DF_OUT=$(df -h "$DOWNLOAD_DIR" | tail -n 1)
TOTAL_SIZE=$(echo "$DF_OUT" | awk '{print $2}')
INITIAL_USED=$(echo "$DF_OUT" | awk '{print $3}')
INITIAL_AVAIL=$(echo "$DF_OUT" | awk '{print $4}')
INITIAL_PCT=$(echo "$DF_OUT" | awk '{print $5}')
PCT_NUM="${INITIAL_PCT%\%}"

log "[INFO] Disk check: ${INITIAL_USED}/${TOTAL_SIZE} used (${INITIAL_PCT}). Threshold: ${MAX_DISK_USAGE_PCT}%"

if [ "$PCT_NUM" -lt "$MAX_DISK_USAGE_PCT" ] && [ "$FORCE" = false ]; then
    log "[INFO] Disk usage (${INITIAL_PCT}) is below threshold (${MAX_DISK_USAGE_PCT}%). No cleanup needed."
    exit 0
fi

log "[INFO] Starting storage retention cleanup (Retention: ${RETENTION_DAYS} days, Force: ${FORCE}, DryRun: ${DRY_RUN})..."

DELETED_ITEMS=()
FREED_BYTES=0

# Iterate top-level items in DOWNLOAD_DIR
while IFS= read -r -d '' ITEM; do
    BASENAME="$(basename "$ITEM")"

    # Skip hidden files or control files directly
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == *.aria2 ]]; then
        continue
    fi

    # Check if item is older than RETENTION_DAYS
    # -mtime +RETENTION_DAYS means modified more than RETENTION_DAYS ago
    IS_OLD=$(find "$ITEM" -maxdepth 0 -mtime "+${RETENTION_DAYS}" 2>/dev/null | wc -l)
    if [ "$IS_OLD" -eq 0 ] && [ "$FORCE" = false ]; then
        continue
    fi

    # Check for active .aria2 control files indicating incomplete download
    CONTROL_COUNT=0
    if [ -d "$ITEM" ]; then
        CONTROL_COUNT=$(find "$ITEM" -name "*.aria2" 2>/dev/null | wc -l)
    elif [ -f "${ITEM}.aria2" ]; then
        CONTROL_COUNT=1
    fi

    if [ "$CONTROL_COUNT" -gt 0 ]; then
        log "[INFO] Skipping $BASENAME (download active or incomplete, $CONTROL_COUNT aria2 control files found)."
        continue
    fi

    # Calculate item size
    ITEM_SIZE=$(du -sh "$ITEM" 2>/dev/null | awk '{print $1}' || echo "unknown")
    ITEM_BYTES=$(du -sb "$ITEM" 2>/dev/null | awk '{print $1}' || echo "0")

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would remove: $BASENAME ($ITEM_SIZE)"
        DELETED_ITEMS+=("$BASENAME ($ITEM_SIZE)")
    else
        log "[CLEAN] Removing completed item: $BASENAME ($ITEM_SIZE)"
        if rm -rf "$ITEM"; then
            DELETED_ITEMS+=("$BASENAME ($ITEM_SIZE)")
            FREED_BYTES=$((FREED_BYTES + ITEM_BYTES))
        else
            log "[ERROR] Failed to remove: $BASENAME"
        fi
    fi
done < <(find "$DOWNLOAD_DIR" -mindepth 1 -maxdepth 1 -print0)

# Clean orphaned .aria2 control files older than 7 days
while IFS= read -r -d '' CONTROL_FILE; do
    TARGET_FILE="${CONTROL_FILE%.aria2}"
    if [ ! -e "$TARGET_FILE" ]; then
        log "[CLEAN] Removing orphaned control file: $(basename "$CONTROL_FILE")"
        [ "$DRY_RUN" = false ] && rm -f "$CONTROL_FILE" 2>/dev/null || true
    fi
done < <(find "$DOWNLOAD_DIR" -maxdepth 2 -name "*.aria2" -mtime +7 -print0 2>/dev/null)

# Calculate final disk usage
DF_NEW=$(df -h "$DOWNLOAD_DIR" | tail -n 1)
FINAL_USED=$(echo "$DF_NEW" | awk '{print $3}')
FINAL_AVAIL=$(echo "$DF_NEW" | awk '{print $4}')
FINAL_PCT=$(echo "$DF_NEW" | awk '{print $5}')
FINAL_PCT_NUM="${FINAL_PCT%\%}"

HUMAN_FREED=$(numfmt --to=iec "$FREED_BYTES" 2>/dev/null || echo "${FREED_BYTES} bytes")

log "[SUCCESS] Cleanup finished. Freed: ${HUMAN_FREED}. New Usage: ${FINAL_USED}/${TOTAL_SIZE} (${FINAL_PCT})"

# Send Telegram notification if items were removed or if disk is still dangerously full
if [ "${#DELETED_ITEMS[@]}" -gt 0 ] || [ "$FINAL_PCT_NUM" -ge 90 ]; then
    CLEANED_LIST=""
    if [ "${#DELETED_ITEMS[@]}" -gt 0 ]; then
        for ITEM_NAME in "${DELETED_ITEMS[@]}"; do
            CLEANED_LIST="${CLEANED_LIST}\n• \`${ITEM_NAME}\`"
        done
    else
        CLEANED_LIST="\n• _No eligible old files found to delete_"
    fi

    STATUS_EMOJI="🧹"
    [ "$FINAL_PCT_NUM" -ge 90 ] && STATUS_EMOJI="⚠️"

    TELEGRAM_MSG="${STATUS_EMOJI} *Storage Retention & Auto-Cleaner Report*
*Time:* \`$(date '+%Y-%m-%d %H:%M:%S')\`
*Initial Disk Usage:* \`${INITIAL_USED}/${TOTAL_SIZE}\` (${INITIAL_PCT})
*Final Disk Usage:* \`${FINAL_USED}/${TOTAL_SIZE}\` (${FINAL_PCT})
*Storage Freed:* \`${HUMAN_FREED}\`

*Items Cleaned:*${CLEANED_LIST}"

    notify_telegram "$TELEGRAM_MSG" "Markdown"
fi

exit 0
