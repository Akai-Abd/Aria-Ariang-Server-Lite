#!/usr/bin/env bash
# Aria-Ariang Server (Lite Version) - Telegram Notification Helper
# Ponytail: Zero-dependency Telegram notification engine using pure bash + curl.

set -euo pipefail

TEXT="${1:-}"
PARSE_MODE="${2:-Markdown}"

if [ -z "$TEXT" ]; then
    exit 0
fi

# Load env file if environment variables are not directly provided
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
    for ENV_FILE in "/config/script/telegram.env" "/config/telegram.env" "$(dirname "$0")/../.env"; do
        if [ -f "$ENV_FILE" ]; then
            # shellcheck disable=SC1090
            source "$ENV_FILE" 2>/dev/null || true
            break
        fi
    done
fi

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# Ponytail: If Telegram is not configured, exit silently without breaking main tasks
if [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
    exit 0
fi

API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

# Send async notification (retry max 2 times, timeout 5s)
curl -s -S --max-time 5 --retry 1 \
    -X POST "$API_URL" \
    -d "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${TEXT}" \
    -d "parse_mode=${PARSE_MODE}" >/dev/null 2>&1 || true

exit 0
