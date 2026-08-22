#!/bin/bash
# Stop execution immediately if any command returns a non-zero exit status (error)
set -e

# ------------------------------------------------------------------------------
# CONFIGURATION & PATH DEFINITIONS
# ------------------------------------------------------------------------------
APP_DIR="/home/ubuntu/ApexFit/frontend/member-app"
BACKUP_DIR="/home/ubuntu/ApexFit/frontend/backups/member-app"
ARCHIVE="/tmp/member-app-release.tar.gz" 
# ------------------------------------------------------------------------------
# STEP 1: CREATE BACKUP OF CURRENT LIVE APP
# ------------------------------------------------------------------------------
echo "==> [1/3] Backing up current live application files..."

# Clear out any previous backup folder to ensure a clean state
rm -rf "$BACKUP_DIR"

# Ensure the parent directory for the backup exists before copying
mkdir -p "$(dirname "$BACKUP_DIR")"

# If the active application directory exists, copy its full content to the backup directory
if [ -d "$APP_DIR" ]; then
  cp -r "$APP_DIR" "$BACKUP_DIR"
fi

# ------------------------------------------------------------------------------
# STEP 2: EXTRACT AND APPLY NEW BUILD
# ------------------------------------------------------------------------------
echo "==> [2/3] Deploying new build archive..."

mkdir -p "$APP_DIR"
rm -rf "${APP_DIR:?}"/*

# Extract the source code
tar -xzf "$ARCHIVE" -C "$APP_DIR"
rm -f "$ARCHIVE"

# Go into the app folder and generate the 'dist' folder
echo "==> Installing dependencies and building..."
cd "$APP_DIR"
npm install
npm run build
# ------------------------------------------------------------------------------
# STEP 3: RELOAD WEB SERVER
# ------------------------------------------------------------------------------
echo "==> [3/3] Reloading Nginx web server..."

# Gracefully reload Nginx to serve the updated static assets without downtime
sudo systemctl reload nginx

echo "==> Deployment completed successfully!"
