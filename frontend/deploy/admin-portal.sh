#!/bin/bash
# Stop execution immediately if any command returns a non-zero exit status (error)
set -e

# ------------------------------------------------------------------------------
# CONFIGURATION & PATH DEFINITIONS
# ------------------------------------------------------------------------------
APP_DIR="/home/ubuntu/ApexFit/frontend/admin-portal"
BACKUP_DIR="/home/ubuntu/ApexFit/frontend/backups/admin-portal"
ARCHIVE="/tmp/admin-portal-release.tar.gz" 
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

# Ensure the target application directory exists
mkdir -p "$APP_DIR"

# Wipe existing static assets in APP_DIR so old hashed JavaScript/CSS files don't accumulate
rm -rf "${APP_DIR:?}"/*

# Unpack the new frontend release archive directly into the application folder
tar -xzf "$ARCHIVE" -C "$APP_DIR"

# Remove the temporary release archive file to conserve disk space
rm -f "$ARCHIVE"

# ------------------------------------------------------------------------------
# STEP 3: RELOAD WEB SERVER
# ------------------------------------------------------------------------------
echo "==> [3/3] Reloading Nginx web server..."

# Gracefully reload Nginx to serve the updated static assets without downtime
sudo systemctl reload nginx

echo "==> Deployment completed successfully!"
