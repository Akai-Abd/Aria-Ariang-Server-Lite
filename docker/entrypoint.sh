#!/usr/bin/env bash
# Aria-Ariang Lite - All-in-One Container Entrypoint
# Manages aria2c (background) + nginx (foreground)

set -euo pipefail

# --- Defaults ---
RPC_SECRET="${RPC_SECRET:-changeme}"
BASIC_AUTH_USER="${BASIC_AUTH_USER:-admin}"
BASIC_AUTH_PASS="${BASIC_AUTH_PASS:-changeme}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
TZ="${TZ:-UTC}"
ENABLE_AUTO_CLEAN="${ENABLE_AUTO_CLEAN:-true}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 */6 * * *}"


echo "╔════════════════════════════════════════════════╗"
echo "║   Aria-Ariang Lite Server (All-in-One)        ║"
echo "╚════════════════════════════════════════════════╝"

# --- Timezone ---
if [ -f "/usr/share/zoneinfo/$TZ" ]; then
    ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
fi

# --- First-run: copy default configs if not present ---
[ -f /config/aria2.conf ] || cp /config/aria2.conf.default /config/aria2.conf
[ -f /config/script.conf ] || cp /config/script.conf.default /config/script.conf
[ -f /config/cloud-destinations.json ] || cp /config/cloud-destinations.json.default /config/cloud-destinations.json

# Ensure session file exists
touch /config/aria2.session

# --- Patch aria2.conf with RPC_SECRET from env ---
if grep -q "^rpc-secret=" /config/aria2.conf; then
    sed -i "s|^rpc-secret=.*|rpc-secret=${RPC_SECRET}|" /config/aria2.conf
else
    echo "rpc-secret=${RPC_SECRET}" >> /config/aria2.conf
fi

# --- Generate .htpasswd for nginx basic auth ---
htpasswd -bc /config/.htpasswd "$BASIC_AUTH_USER" "$BASIC_AUTH_PASS" 2>/dev/null

# --- Ensure script permissions ---
chmod +x /config/script/*.sh 2>/dev/null || true

# --- Create downloads dir ---
mkdir -p /downloads

# --- Signal handling: stop both processes cleanly ---
ARIA2_PID=""

cleanup() {
    echo "[entrypoint] Shutting down..."
    if [ -n "$ARIA2_PID" ] && kill -0 "$ARIA2_PID" 2>/dev/null; then
        kill -TERM "$ARIA2_PID" 2>/dev/null || true
        wait "$ARIA2_PID" 2>/dev/null || true
    fi
    nginx -s stop 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

# --- Start aria2c in background ---
echo "[entrypoint] Starting aria2c..."
aria2c \
    --conf-path=/config/aria2.conf \
    --input-file=/config/aria2.session \
    --save-session=/config/aria2.session \
    --dir=/downloads \
    --enable-rpc \
    --rpc-listen-all=true \
    --rpc-listen-port=6800 \
    --rpc-secret="${RPC_SECRET}" \
    --daemon=false &
ARIA2_PID=$!

# Brief pause to let aria2 bind its port
sleep 1

if ! kill -0 "$ARIA2_PID" 2>/dev/null; then
    echo "[entrypoint] ERROR: aria2c failed to start"
    exit 1
fi

echo "[entrypoint] aria2c started (PID: $ARIA2_PID)"

# --- Start crond for storage retention auto-cleaner ---
if [ "$ENABLE_AUTO_CLEAN" = "true" ]; then
    echo "[entrypoint] Setting up storage retention cron (${CRON_SCHEDULE})..."
    mkdir -p /var/spool/cron/crontabs
    echo "${CRON_SCHEDULE} /config/script/clean_retention.sh >> /config/clean_retention.log 2>&1" > /var/spool/cron/crontabs/root
    crond -b -l 2 2>/dev/null || true
fi

# --- Start nginx in foreground ---
echo "[entrypoint] Starting nginx..."
nginx -g "daemon off;" &
NGINX_PID=$!

# Wait for either process to exit
wait -n "$ARIA2_PID" "$NGINX_PID" 2>/dev/null || true

echo "[entrypoint] A process exited unexpectedly, shutting down..."
cleanup
