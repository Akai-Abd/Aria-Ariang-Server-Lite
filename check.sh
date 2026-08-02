#!/usr/bin/env bash
# Aria-Ariang Server (Lite Version) - Health Check & Issue Reporter Script

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY_FLAG="${1:-}"

# Colors
BOLD='\033[1m'
RESET='\033[0m'
GREEN='\033[38;5;46m'
BLUE='\033[38;5;39m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;201m'
YELLOW='\033[38;5;226m'
RED='\033[38;5;196m'
GRAY='\033[38;5;240m'

ISSUES=()

clear
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}║       ${BOLD}ARIA-ARIANG LITE SERVER HEALTH CHECK${RESET}${BLUE} | ${CYAN}$(date '+%H:%M %d-%b') ${BLUE} ║${RESET}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${RESET}"

# 1. Trackers Check
echo -e "\n${MAGENTA}📡 BITTORRENT TRACKERS${RESET}"
echo -e "${GRAY}──────────────────────────────────────────────────────────────────${RESET}"
if grep -q "^bt-tracker=" "$PROJECT_DIR/aria2/aria2.conf" 2>/dev/null; then
    COUNT=$(grep "bt-tracker=" "$PROJECT_DIR/aria2/aria2.conf" | awk -F= '{print $2}' | awk -F, '{print NF}')
    echo -e "   Status : ${GREEN}✅ Active${RESET} (${COUNT} trackers loaded)"
else
    echo -e "   Status : ${RED}❌ Missing trackers${RESET}"
    ISSUES+=("📡 Missing BT trackers in aria2.conf")
fi

# 2. Disk Storage
echo -e "\n${YELLOW}💾 DISK STORAGE${RESET}"
echo -e "${GRAY}──────────────────────────────────────────────────────────────────${RESET}"
DF_OUT=$(df -h "$PROJECT_DIR" | tail -n 1)
SIZE=$(echo "$DF_OUT" | awk '{print $2}')
USED=$(echo "$DF_OUT" | awk '{print $3}')
AVAIL=$(echo "$DF_OUT" | awk '{print $4}')
PCT=$(echo "$DF_OUT" | awk '{print $5}')
PCT_NUM="${PCT%\%}"
echo -e "   Storage: ${RED}$USED${RESET} used / ${GREEN}$SIZE${RESET} total (Free: ${BLUE}$AVAIL${RESET} - $PCT)"

if [ "${PCT_NUM:-0}" -ge 90 ]; then
    ISSUES+=("💾 Low Disk Space: ${USED}/${SIZE} (${PCT} used)")
fi

# 3. Docker Services
echo -e "\n${BLUE}🐳 CONTAINER STATUS${RESET}"
echo -e "${GRAY}──────────────────────────────────────────────────────────────────${RESET}"
printf "   %-20s %-20s\n" "CONTAINER" "STATUS"
while IFS='|' read -r NAME STATUS; do
    [ -z "$NAME" ] && continue
    if [[ "$STATUS" == *"Up"* ]]; then
        printf "   %-20s ${GREEN}● Online${RESET}\n" "$NAME"
    else
        printf "   %-20s ${RED}● Offline${RESET}\n" "$NAME"
        ISSUES+=("🐳 Container Offline: ${NAME}")
    fi
done < <(docker ps -a --format "{{.Names}}|{{.Status}}" | grep -E "aria2-pro|nginx-proxy" || true)

# 4. Memory Footprint
echo -e "\n${CYAN}⚡ MEMORY USAGE (LITE STACK)${RESET}"
echo -e "${GRAY}──────────────────────────────────────────────────────────────────${RESET}"
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep -E "aria2-pro|nginx-proxy" || true

echo -e "\n${GREEN}Health check complete.${RESET}\n"

# Send Telegram alert if issues detected or --notify flag passed
if [ "${#ISSUES[@]}" -gt 0 ] || [ "$NOTIFY_FLAG" = "--notify" ]; then
    if [ -f "$PROJECT_DIR/script/telegram.sh" ]; then
        if [ "${#ISSUES[@]}" -gt 0 ]; then
            ISSUE_LIST=""
            for ISSUE in "${ISSUES[@]}"; do
                ISSUE_LIST="${ISSUE_LIST}\n• ${ISSUE}"
            done
            MSG="🚨 *System Issue Report*
*Time:* \`$(date '+%Y-%m-%d %H:%M:%S')\`
*Issues Detected:*${ISSUE_LIST}"
        else
            MSG="✅ *System Health Report*
All services (aria2-pro, nginx-proxy) are online and healthy. Storage: ${USED}/${SIZE} (${PCT} used)."
        fi
        
        echo -e "${YELLOW}Sending Telegram notification...${RESET}"
        "$PROJECT_DIR/script/telegram.sh" "$MSG" "Markdown" || true
    fi
fi
