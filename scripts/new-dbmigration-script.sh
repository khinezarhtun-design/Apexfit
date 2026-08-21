#!/bin/bash

# =============================================================
# ApexFit — Production Database Migration
#
# Runs database migrations using the native Node.js services.
#
# Production setup:
#   Backend EC2 + systemd
#   Database EC2 + PostgreSQL
#
# Usage:
#   ./scripts/db-migration-production.sh
# =============================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[migrate]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[migrate]${NC} $1"
}

fail() {
    echo -e "${RED}[migrate]${NC} $1"
    exit 1
}

# -------------------------------------------------------------
# Project configuration
# -------------------------------------------------------------

PROJECT_DIR="/home/ubuntu/ApexFit"
SERVICES_DIR="$PROJECT_DIR/services"

USER_SERVICE="$SERVICES_DIR/user-service"
MEMBERSHIP_SERVICE="$SERVICES_DIR/membership-service"
ADMIN_SERVICE="$SERVICES_DIR/admin-service"

# -------------------------------------------------------------
# Check project directories
# -------------------------------------------------------------

[[ -d "$PROJECT_DIR" ]] \
    || fail "Project directory not found: $PROJECT_DIR"

[[ -d "$USER_SERVICE" ]] \
    || fail "User service directory not found: $USER_SERVICE"

[[ -d "$MEMBERSHIP_SERVICE" ]] \
    || fail "Membership service directory not found: $MEMBERSHIP_SERVICE"

[[ -d "$ADMIN_SERVICE" ]] \
    || fail "Admin service directory not found: $ADMIN_SERVICE"

# -------------------------------------------------------------
# Check Node.js
# -------------------------------------------------------------

command -v node >/dev/null 2>&1 \
    || fail "Node.js is not installed."

log "Node version: $(node --version)"

# -------------------------------------------------------------
# Check PostgreSQL connectivity
# -------------------------------------------------------------

if [[ -f "$USER_SERVICE/.env" ]]; then
    set -a
    source "$USER_SERVICE/.env"
    set +a
else
    fail "User service .env file not found."
fi

[[ -n "${DB_HOST:-}" ]] \
    || fail "DB_HOST is not configured."

[[ -n "${DB_PORT:-}" ]] \
    || fail "DB_PORT is not configured."

[[ -n "${DB_NAME:-}" ]] \
    || fail "DB_NAME is not configured."

[[ -n "${DB_USER:-}" ]] \
    || fail "DB_USER is not configured."

[[ -n "${DB_PASSWORD:-}" ]] \
    || fail "DB_PASSWORD is not configured."

log "Database: ${DB_HOST}:${DB_PORT}"
log "Database name: ${DB_NAME}"
log "Database user: ${DB_USER}"

# -------------------------------------------------------------
# Test PostgreSQL connection
# -------------------------------------------------------------

if command -v nc >/dev/null 2>&1; then

    if nc -z -w 5 "$DB_HOST" "$DB_PORT"; then
        log "PostgreSQL network connection successful."
    else
        fail "Cannot connect to PostgreSQL at ${DB_HOST}:${DB_PORT}"
    fi

else
    warn "nc is not installed. Skipping network connectivity test."
fi

echo ""

# -------------------------------------------------------------
# User Service Migration
# -------------------------------------------------------------

log "Running migration: user-service..."

cd "$USER_SERVICE"

[[ -f "src/db/migrate.js" ]] \
    || fail "Migration file not found in user-service."

node src/db/migrate.js \
    || fail "User-service migration failed."

log "User-service migration completed successfully."

echo ""

# -------------------------------------------------------------
# Membership Service Migration
# -------------------------------------------------------------

log "Running migration: membership-service..."

cd "$MEMBERSHIP_SERVICE"

[[ -f "src/db/migrate.js" ]] \
    || fail "Migration file not found in membership-service."

node src/db/migrate.js \
    || fail "Membership-service migration failed."

log "Membership-service migration completed successfully."

echo ""

# -------------------------------------------------------------
# Admin Service Migration
# -------------------------------------------------------------

log "Running migration: admin-service..."

cd "$ADMIN_SERVICE"

[[ -f "src/db/migrate.js" ]] \
    || fail "Migration file not found in admin-service."

node src/db/migrate.js \
    || fail "Admin-service migration failed."

log "Admin-service migration completed successfully."

echo ""

# -------------------------------------------------------------
# Finished
# -------------------------------------------------------------

log "=============================================="
log "All ApexFit database migrations completed."
log "=============================================="
