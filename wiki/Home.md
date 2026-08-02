# ⚡ Aria-Ariang-Server-Lite Wiki

Welcome to the official documentation for **Aria-Ariang-Server-Lite** — an ultra-lightweight, high-performance download & cloud auto-sync server powered by Docker, Aria2, AriaNg, Nginx, and Rclone with a **~30MB - 60MB RAM footprint**.

---

## 📚 Wiki Guides & Documentation

- 🚀 **[Quick Start & Deployment](Quick-Start-&-Deployment)**
  Prerequisites, Docker Compose setup, environment variables, Nginx basic authentication, and SSL setup.

- ☁️ **[Cloud Auto-Sync Guide](Cloud-Auto-Sync-Guide)**
  Configure Rclone remotes (OneDrive, Google Drive, Mega, S3, 40+ providers) and automatic post-download uploads.

- 🤖 **[Telegram Bot Notifications](Telegram-Bot-Notifications)**
  Real-time alerts for Download Complete, Upload Complete, Download/Upload Errors, and System Health issue reports.

- 🩺 **[System Health & Maintenance](System-Health-&-Maintenance)**
  Using `./check.sh`, automated tracker updates, configuration backups, disk space cleanup, and memory optimization.

---

## 🏗 Architecture Overview

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

## 💡 Why Lite Edition?

Standard download stacks bundle heavy web UI file browsers, persistent Rclone GUI daemons, and Node.js management servers that idle at **350MB – 500MB+ RAM**.

**Aria-Ariang Lite** strips unnecessary bloat:
* **Native Nginx Autoindex**: Instant HTTP directory browsing without running a separate FileBrowser container.
* **On-Demand Rclone**: Rclone runs as a background CLI process only when downloads complete.
* **Native Bash & Curl Notifications**: Telegram notifications use standard Linux utilities without requiring heavy Python or Node.js bot runtimes.

Result: A complete seedbox stack operating comfortably on **512MB RAM VPS** instances!
