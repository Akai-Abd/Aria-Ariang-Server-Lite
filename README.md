# Aria-Ariang Server (Lite Version) ⚡

> **Lite Edition**: Ultra-lightweight, high-performance download & cloud sync server powered by Docker, Aria2, AriaNg, Nginx, and Rclone.

[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-v2-blue?logo=docker)](https://docs.docker.com/compose/)
[![RAM Usage](https://img.shields.io/badge/RAM%20Footprint-~30MB%20--%2060MB-brightgreen)](#performance--resource-footprint)
[![Telegram Bot](https://img.shields.io/badge/Telegram%20Bot-Notifications-blue?logo=telegram)](https://core.telegram.org/bots)
[![Wiki Docs](https://img.shields.io/badge/Wiki-Documentation-purple?logo=github)](https://github.com/Akai-Abd/Aria-Ariang-Server-Lite/wiki)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

<p align="center">
  <img src="assets/preview.png" alt="Aria-Ariang Server Lite Dashboard Preview" width="100%"/>
</p>


---

## 💡 Why Lite?

Standard seedbox/download stacks often bundle heavy web dashboards, resource-intensive file managers, and monitoring containers that consume **350MB – 500MB+ RAM** at idle.

**Aria-Ariang Lite** strips away all unnecessary abstractions (YAGNI principle):
* ❌ **No Heavy FileBrowser Container**: Replaced with Nginx's native, zero-RAM HTTP `autoindex` engine for directory browsing and downloading.
* ❌ **No Constant Rclone Web GUI Daemon**: Rclone runs as a lightweight CLI process triggered only when downloads complete.
* ❌ **No Heavy Bot Frameworks**: Zero-dependency Telegram notifications using native `curl` in standard bash.
* ❌ **No Portainer or Node.js Dashboards**: Managed directly via native Docker CLI commands.

**Result**: A complete download & cloud-sync server running in **just 2 containers** consuming **~30MB - 60MB RAM total**. Perfect for 512MB or 1GB RAM cloud VPS (Oracle Free Tier, DigitalOcean, Linode, AWS EC2).

---

## 🏗 Architecture

```
                       ┌─────────────────────────┐
                       │   Nginx Reverse Proxy   │ (Port 80/443)
                       │      (nginx-proxy)      │
                       └───────────┬─────────────┘
                                   │
         ┌─────────────────────────┼────────────────────────┐
         │                         │                        │
         ▼                         ▼                        ▼
┌─────────────────┐       ┌─────────────────┐      ┌──────────────────┐
│    AriaNg UI    │       │ Aria2 JSON-RPC  │      │ Direct Downloads │
│ (Static HTML/JS)│       │  (aria2-pro)    │      │ (Nginx Autoindex)│
└─────────────────┘       └─────────────────┘      └──────────────────┘
                                   │
                                   ├───────────────► 🤖 Telegram Bot Alerts
                                   │ (on download/upload/error)
                                   ▼ (on download complete)
                          ┌──────────────────┐
                          │ Rclone Auto-Sync │ (Background CLI)
                          └──────────────────┘
```

---

## 🚀 Installation & Deployment Guide

### 📋 Prerequisites
- **Docker** (v20.10+) and **Docker Compose v2** installed on your server.
- Open port **80** (HTTP) on your server firewall.

---

### Option A: Docker Hub Deployment (Recommended & Fastest)

[![Docker Hub](https://img.shields.io/docker/pulls/baba2580/aria-ariang-lite?logo=docker&label=Docker%20Hub)](https://hub.docker.com/r/baba2580/aria-ariang-lite)

Deploy instantly using the pre-built multi-architecture Docker image (`baba2580/aria-ariang-lite:latest`) — no `git clone` or local building required.

#### Method 1: Using Docker Compose (Recommended)

1. **Download the Docker Compose configuration:**
   ```bash
   mkdir -p aria-lite && cd aria-lite
   curl -O https://raw.githubusercontent.com/Akai-Abd/Aria-Ariang-Server-Lite/main/docker-compose.docker-hub.yml
   ```

2. **(Optional) Create a `.env` file to customize credentials:**
   ```bash
   cat <<EOF > .env
   RPC_SECRET=YourSuperSecretRPCKey
   BASIC_AUTH_USER=admin
   BASIC_AUTH_PASS=YourStrongPassword
   TZ=Asia/Kolkata
   TELEGRAM_BOT_TOKEN=
   TELEGRAM_CHAT_ID=
   EOF
   ```

3. **Start the container:**
   ```bash
   docker compose -f docker-compose.docker-hub.yml up -d
   ```

#### Method 2: Using Docker CLI (`docker run`)

Run a single command to create persistent volumes and launch the server:

```bash
docker run -d \
  --name aria-ariang-lite \
  -p 80:80 \
  -e RPC_SECRET=YourSuperSecretRPCKey \
  -e BASIC_AUTH_USER=admin \
  -e BASIC_AUTH_PASS=YourStrongPassword \
  -e TZ=Asia/Kolkata \
  -v ./config:/config \
  -v ./downloads:/downloads \
  --restart always \
  baba2580/aria-ariang-lite:latest
```

---

### Option B: Build from Source (Git Clone)

For full control over source files, scripts, and local custom builds:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Akai-Abd/Aria-Ariang-Server-Lite.git
   cd Aria-Ariang-Server-Lite
   ```

2. **Configure Environment Variables:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` to set your credentials and optional Telegram notifications:
   ```env
   RPC_SECRET=YourSuperSecretRPCKey
   BASIC_AUTH_USER=admin
   BASIC_AUTH_PASS=YourStrongPassword
   TZ=Asia/Kolkata
   
   # Optional Telegram Bot Alerts
   TELEGRAM_BOT_TOKEN=123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ
   TELEGRAM_CHAT_ID=123456789
   ```

3. **Generate Nginx Web Authentication:**
   ```bash
   htpasswd -c .htpasswd admin
   ```

4. **Build & Start the Stack:**
   ```bash
   docker compose up -d
   ```

---

### ⚙️ Environment Variables Reference

| Environment Variable | Default | Description |
| :--- | :--- | :--- |
| `RPC_SECRET` | `changeme` | Aria2 RPC authentication secret token |
| `BASIC_AUTH_USER` | `admin` | Nginx Web UI basic auth username |
| `BASIC_AUTH_PASS` | `changeme` | Nginx Web UI basic auth password |
| `TZ` | `UTC` | Server Timezone (e.g. `Asia/Kolkata`, `America/New_York`) |
| `PUID` | `1000` | User ID for file permissions |
| `PGID` | `1000` | Group ID for file permissions |
| `TELEGRAM_BOT_TOKEN` | *(empty)* | Optional Telegram bot token for instant alerts |
| `TELEGRAM_CHAT_ID` | *(empty)* | Optional Telegram chat ID for instant alerts |

---

### ✅ Post-Installation Verification

1. **Web Dashboard**: Open `http://<your-server-ip>/` in your browser. Log in with your `BASIC_AUTH_USER` and `BASIC_AUTH_PASS`.
2. **AriaNg Connection**: Ensure AriaNg shows **Connected** status in the bottom left corner (uses `/jsonrpc` automatically).
3. **Direct Downloads**: Browse downloads directly at `http://<your-server-ip>/download/`.

---

## 🤖 Telegram Bot Notifications Guide

The server includes zero-dependency, real-time Telegram Bot notifications for task tracking and issue reporting:

### Features Supported
- 📥 **Download Complete**: Instant alert when Aria2 completes a file/torrent download.
- ☁️ **Upload Complete**: Instant alert when Rclone successfully moves files to your cloud drive.
- 🚨 **Issue Reports**:
  - **Upload Error Alert**: Notifies if Rclone upload fails.
  - **Download Error Alert**: Notifies if Aria2 fails to download a file/torrent.
  - **Health Check Alert**: Notifies if containers are offline or storage space is critical.

### Quick Setup
1. Create a bot using [@BotFather](https://t.me/BotFather) on Telegram and get your `TELEGRAM_BOT_TOKEN`.
2. Get your Chat ID from [@userinfobot](https://t.me/userinfobot) (or channel ID) as `TELEGRAM_CHAT_ID`.
3. Add both values to your `.env` file.
4. Restart docker containers: `docker compose up -d`

---

## 🌐 Service Endpoints

| Service | Access URL | Description | Auth |
| :--- | :--- | :--- | :--- |
| **AriaNg** | `https://your-domain.com/` | Web dashboard for Aria2 downloads | Basic Auth |
| **Direct Downloads** | `https://your-domain.com/download/` | Clean HTTP directory browser & downloader | Basic Auth |
| **Aria2 JSON-RPC** | `https://your-domain.com/jsonrpc` | RPC endpoint for browser extensions & scripts | RPC Secret |

---

## 🩺 System Health Check & Alerts

Run the built-in diagnostic script to inspect trackers, disk space, container status, and memory footprint:

```bash
./check.sh
```

To run a health check and send Telegram issue reports automatically if any service is down or storage is low (>90%):

```bash
./check.sh --notify
```

---

## ☁️ Cloud Auto-Upload Setup

To enable auto-uploading completed downloads to Google Drive, OneDrive, Mega, S3, or 40+ cloud providers:

1. Configure your Rclone remotes in `./rclone/rclone.conf`.
2. Map your destination remotes in `./cloud-destinations.json`.
3. When Aria2 finishes a download, `./script/upload.sh` automatically transfers the file in the background and sends a Telegram notification.

---

## 🔄 Updating Guide

Keep your deployment up-to-date with the latest Docker Hub image or Git updates.

### Option A: Docker Hub Update (Recommended)

**With Docker Compose:**
```bash
docker compose -f docker-compose.docker-hub.yml pull
docker compose -f docker-compose.docker-hub.yml up -d
```

**With Docker Run:**
```bash
docker pull baba2580/aria-ariang-lite:latest
docker stop aria-ariang-lite
docker rm aria-ariang-lite
# Re-run your docker run command
```

### Option B: Git Update

```bash
git pull
docker compose up -d --build
```

---

## 🛠️ Troubleshooting & FAQ

For full diagnostic steps and error solutions, visit the official **[Troubleshooting Guide Wiki Page](https://github.com/Akai-Abd/Aria-Ariang-Server-Lite/wiki/Troubleshooting-Guide)**.

| Issue | Quick Fix |
| :--- | :--- |
| **AriaNg Disconnected / RPC Error** | Check `RPC_SECRET` in `.env` and verify RPC Address is `/jsonrpc`. |
| **Rclone Auto-Upload Fails** | Run `docker exec -it aria2-pro cat /config/upload.log` and verify `./cloud-destinations.json`. |
| **Telegram Alerts Not Arriving** | Send `/start` to your bot, verify `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` in `.env`, and run `./script/telegram.sh "test"`. |
| **Nginx 502 Bad Gateway / 401** | Re-create `.htpasswd` via `htpasswd -c .htpasswd admin` and run `docker compose restart`. |
| **Slow BT Downloads / 0 Seeds** | Update BT trackers by running `./script/tracker.sh`. |

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).

---

<p align="center">
  Built with ❤️ by <b>ABDURRAHMAN</b><br/>
  ⭐ <i>Star this repository if you find it helpful!</i>
</p>
