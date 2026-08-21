#!/bin/bash
set -e

APP_DIR="/home/ubuntu/ApexFit/services/admin-service"
BACKUP_DIR="/home/ubuntu/ApexFit/services/admin-service.backup"
CONFIG_FILE="/home/ubuntu/backend-configs/admin-service.env"
ARCHIVE="/tmp/admin-service-release.tar.gz"

echo "==> [1/4] Backing up current live application files..."
rm -rf "$BACKUP_DIR"
if [ -d "$APP_DIR" ]; then
  cp -r "$APP_DIR" "$BACKUP_DIR"
fi

echo "==> [2/4] Deploying new build archive..."
mkdir -p "$APP_DIR"
tar -xzf "$ARCHIVE" -C "$APP_DIR"
rm -f "$ARCHIVE"

echo "==> [3/4] Restoring environment variables..."
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "$APP_DIR/.env"
fi

echo "==> [4/4] Restarting admin-service via Systemd..."
sudo systemctl restart admin-service
