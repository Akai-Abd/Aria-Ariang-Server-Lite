# 🤖 Telegram Bot Notifications Guide

**Aria-Ariang-Server-Lite** features real-time, zero-dependency Telegram notification alerts built using standard bash scripts and `curl`.

---

## ⚡ Supported Notification Events

| Event | Icon | Description |
| :--- | :---: | :--- |
| **Download Complete** | 📥 | Sent when Aria2 completes downloading a file/torrent batch. |
| **Upload Complete** | ☁️ | Sent when Rclone successfully finishes moving files to cloud storage. |
| **Upload Failed Report** | ❌ | Sent if Rclone cloud move encounters an error. |
| **Download Error Report** | ⚠️ | Sent if Aria2 encounters a download failure. |
| **System Health Report** | 🚨 / ✅ | Sent via `./check.sh --notify` when services offline or storage critical. |

---

## 🛠️ Step-by-Step Telegram Setup

### Step 1: Create a Bot
1. Open Telegram and search for [@BotFather](https://t.me/BotFather).
2. Send `/newbot` and follow instructions to set name and username.
3. Copy your HTTP API Bot Token (e.g. `123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ`).

### Step 2: Get Your Chat ID
1. Search for [@userinfobot](https://t.me/userinfobot) on Telegram and send `/start`.
2. Copy your numerical **Id** (e.g. `123456789`).
3. For Telegram channels or groups, add your bot as Administrator and use the channel ID (e.g. `-1001234567890`).

### Step 3: Configure `.env`
Open `.env` on your server and set:

```env
TELEGRAM_BOT_TOKEN=123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ
TELEGRAM_CHAT_ID=123456789
```

### Step 4: Apply Changes
Restart containers to pass variables:
```bash
docker compose up -d
```

---

## 🧪 Testing Telegram Notifications

Run a manual test notification via `script/telegram.sh`:

```bash
./script/telegram.sh "🚀 *Test Message from Aria-Ariang Server*" "Markdown"
```

Or trigger a health report notification:

```bash
./check.sh --notify
```
