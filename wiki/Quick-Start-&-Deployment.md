# 🚀 Quick Start & Deployment Guide

This guide covers setting up **Aria-Ariang-Server-Lite** on your Linux server or Cloud VPS (DigitalOcean, Linode, AWS EC2, Oracle Free Tier).

---

## 📋 Prerequisites

1. **Operating System**: Linux (Ubuntu 20.04+, Debian 11+, CentOS/RHEL 8+, Alpine).
2. **Software**: Docker & Docker Compose v2 installed.
3. **Hardware**: 512MB+ RAM, 1 CPU core, 10GB+ free storage.
4. **Domain** (Optional): A/AAAA records pointing to server IP for HTTPS/SSL.

---

## 🛠️ Step-by-Step Installation

### 1. Clone Repository
```bash
git clone https://github.com/Akai-Abd/Aria-Ariang-Server-Lite.git
cd Aria-Ariang-Server-Lite
```

### 2. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Edit `.env` values:
```env
# Aria2 RPC Secret Key
RPC_SECRET=YourSuperSecretKey123

# Container User/Group IDs (match host user)
PUID=1001
PGID=1001

# System Timezone
TZ=Asia/Kolkata

# Domain Name
DOMAIN=your-domain.com

# Telegram Bot Notifications (Optional)
TELEGRAM_BOT_TOKEN=123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ
TELEGRAM_CHAT_ID=123456789
```

### 3. Generate Basic Auth Credentials
Secure the web interface using Nginx Basic Auth (`.htpasswd`):
```bash
# Install htpasswd utility if needed (apache2-utils on Debian/Ubuntu)
sudo apt-get install -y apache2-utils

# Create credentials file
htpasswd -c .htpasswd admin
```

### 4. Deploy Docker Containers
Start the containers in detached mode:
```bash
docker compose up -d
```

Verify service status:
```bash
docker compose ps
```

---

## 🌐 Service Access & Endpoints

| Service | Access URL | Authentication |
| :--- | :--- | :--- |
| **AriaNg Web Dashboard** | `https://your-domain.com/` | Nginx Basic Auth |
| **Direct File Downloads** | `https://your-domain.com/download/` | Nginx Basic Auth |
| **Aria2 JSON-RPC Endpoint** | `https://your-domain.com/jsonrpc` | `RPC_SECRET` token |

---

## 🔒 SSL / TLS Configuration

1. Place your SSL certificate and key in `./certs/`:
   - Full chain: `./certs/fullchain.pem`
   - Private key: `./certs/privkey.pem`
2. Restart Nginx container:
   ```bash
   docker compose restart nginx-proxy
   ```
