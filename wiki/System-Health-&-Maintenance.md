# 🩺 System Health & Maintenance Guide

Keep your **Aria-Ariang-Server-Lite** instance running smoothly with built-in scripts for diagnostic checks, tracker updates, backups, and disk cleanup.

---

## 🔍 System Health Diagnostic Script (`./check.sh`)

Inspect active BitTorrent trackers, storage consumption, Docker container online state, and memory usage:

```bash
./check.sh
```

To perform a health check and send Telegram issue alerts if container services are down or disk usage exceeds 90%:

```bash
./check.sh --notify
```

---

## 📡 Automatic BitTorrent Tracker Updates (`tracker.sh`)

Update Aria2's active BT tracker list with high-speed, validated trackers:

```bash
./script/tracker.sh /config/aria2.conf RPC localhost:6800 YourSuperSecretKey
```

> 💡 **Tip:** Add a cron job to update trackers daily:
> ```bash
> 0 4 * * * docker exec -it aria2-pro /config/script/tracker.sh
> ```

---

## 💾 Configuration Backups (`backup.sh`)

Backup configuration files (`aria2.conf`, `script.conf`, `upload.sh`, `delete.sh`, `clean.sh`, `tracker.sh`) to your configured Rclone remote:

```bash
docker exec -it aria2-pro /config/script/backup.sh
```

---

## 🧹 Disk Cleanup Script (`clean.sh`)

Remove residual temporary files (`.aria2`, `.torrent`, empty directories) after torrent downloads finish:

```bash
docker exec -it aria2-pro /config/script/clean.sh
```

---

## ⚡ Memory & Performance Tuning

- **Standard Idle Footprint**: ~30MB – 60MB RAM total across both `aria2-pro` and `nginx-proxy` containers.
- **Docker Stats Verification**:
  ```bash
  docker stats aria2-pro nginx-proxy
  ```
