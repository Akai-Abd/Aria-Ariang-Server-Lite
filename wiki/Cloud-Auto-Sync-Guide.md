# ☁️ Cloud Auto-Sync Guide

**Aria-Ariang-Server-Lite** includes automatic post-download sync capabilities powered by **Rclone**. Once Aria2 completes downloading a file or torrent, it automatically triggers Rclone to upload the completed file to your cloud storage provider and cleans up the local download folder.

---

## 🛠️ Configuration Steps

### 1. Configure Rclone Remotes

Create or edit your Rclone configuration file at `./rclone/rclone.conf`:

```ini
[onedrive]
type = onedrive
token = {"access_token":"...","token_type":"Bearer",...}
drive_id = b!xxxxxx
drive_type = personal

[gdrive]
type = drive
scope = drive
token = {"access_token":"...","token_type":"Bearer",...}
```

> 💡 **Tip:** You can generate `rclone.conf` on your local PC by running `rclone config` and copying the configuration section into `./rclone/rclone.conf`.

---

### 2. Configure Target Destinations

Edit `./cloud-destinations.json` to enable target cloud destinations:

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

- **remote**: Name of the remote specified in square brackets `[remote]` in `rclone.conf`.
- **path**: Directory path inside your cloud drive.
- **enabled**: Set to `true` to activate the remote destination.

---

### 3. How Auto-Sync Operates

1. **Download Completion**: Aria2 finishes downloading a file/torrent batch and fires the `on-download-complete` event hook.
2. **Execution**: Aria2 executes `./script/upload.sh`.
3. **Validation**: The script checks if remaining `.aria2` control files exist (in case of batch multi-file downloads).
4. **Cloud Transfer**: If all control files are cleared, Rclone moves the downloaded payload to your specified cloud remote.
5. **Notification**: Sends a Telegram notification (if configured) on success or failure.
6. **Local Cleanup**: Removes local file copy from `/downloads` upon successful transfer to conserve disk space.
