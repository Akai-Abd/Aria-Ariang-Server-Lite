# 🛠️ Troubleshooting Guide

Quick solutions for common issues, runtime errors, and configuration checks in **Aria-Ariang-Server-Lite**.

---

## 🔍 Quick Diagnostics

Always run the built-in health check script first to diagnose container status, storage, and trackers:

```bash
./check.sh
```

To automatically broadcast issue reports to your Telegram Bot:

```bash
./check.sh --notify
```

---

## ❓ Common Issues & Solutions

### 1. AriaNg "Disconnected" / RPC Unauthorized Error

* **Symptom**: AriaNg Web UI displays "Disconnected" or "Unauthorized".
* **Cause**: `RPC_SECRET` mismatch between `.env` and AriaNg settings.
* **Fix**:
  1. Verify `RPC_SECRET` in `.env`:
     ```bash
     cat .env | grep RPC_SECRET
     ```
  2. Open AriaNg UI -> **AriaNg Settings** -> **RPC**.
  3. Enter your `RPC_SECRET` in Secret Token field.
  4. Ensure RPC Address is set to `/jsonrpc` (or `https://your-domain.com/jsonrpc`).

---

### 2. Rclone Auto-Upload Fails or Skips

* **Symptom**: Downloads finish but files remain in `/downloads` and don't upload.
* **Cause**: Incorrect remote name, disabled destination in `cloud-destinations.json`, or missing `rclone.conf`.
* **Fix**:
  1. Inspect the upload log inside the container:
     ```bash
     docker exec -it aria2-pro cat /config/upload.log
     ```
  2. Verify `./cloud-destinations.json` has `"enabled": true` and remote name matches `rclone.conf`:
     ```json
     {
       "destinations": [
         {
           "name": "OneDrive Main",
           "remote": "onedrive",
           "path": "/aria2-downloads",
           "enabled": true
         }
       ]
     }
     ```
  3. Check Rclone config validity:
     ```bash
     docker exec -it aria2-pro rclone listremotes --config /config/rclone/rclone.conf
     ```

---

### 3. Telegram Bot Notifications Not Sending

* **Symptom**: Download/Upload finishes but no Telegram messages are received.
* **Cause**: Unset or incorrect `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID`, or Bot not started.
* **Fix**:
  1. Ensure you sent `/start` to your bot on Telegram.
  2. Test sending a message manually:
     ```bash
     ./script/telegram.sh "🚀 Test alert" "Markdown"
     ```
  3. Verify variables are passed to `aria2-pro`:
     ```bash
     docker exec -it aria2-pro env | grep TELEGRAM
     ```
  4. If empty, restart containers: `docker compose up -d`

---

### 4. Nginx 502 Bad Gateway / 401 Unauthorized

* **Symptom**: Browser shows 502 Bad Gateway or 401 Unauthorized when opening AriaNg.
* **Cause**: `.htpasswd` file missing, or `aria2-pro` container failed to start.
* **Fix**:
  1. Re-generate `.htpasswd` file:
     ```bash
     htpasswd -c .htpasswd admin
     ```
  2. Restart container stack:
     ```bash
     docker compose restart
     ```

---

### 5. Slow Torrent Download Speed / 0 Seeds

* **Symptom**: BT downloads stall or have very low download speeds.
* **Cause**: Outdated BitTorrent tracker list.
* **Fix**:
  Update BT trackers using the bundled tracker utility:
  ```bash
  ./script/tracker.sh
  ```

---

### 6. Low Disk Space Alert

* **Symptom**: Server storage is full or `./check.sh` reports disk usage > 90%.
* **Fix**:
  Clean up residual temporary files and incomplete downloads:
  ```bash
  docker exec -it aria2-pro /config/script/clean.sh
  ```
