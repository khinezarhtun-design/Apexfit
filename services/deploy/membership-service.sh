#!/bin/bash
set -e

APP_DIR="/home/ubuntu/ApexFit/services/membership-service"
BACKUP_DIR="/home/ubuntu/ApexFit/services/membership-service.backup"
CONFIG_FILE="/home/ubuntu/backend-configs/membership-service.env"
ARCHIVE="/tmp/membership-service-release.tar.gz"

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

echo "==> [4/4] Restarting membership-service via Systemd..."
sudo systemctl restart membership-service
