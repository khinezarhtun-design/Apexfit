#!/bin/bash

# =============================================================
# ApexFit — Production Admin Seeder
#
# Creates:
#   Email:    admin@apexfit.com
#   Username: admin
#   Role:     admin
#
# Usage:
#   ./scripts/seed-admin-production.sh
#
# Production setup:
#   Backend EC2 + systemd + remote PostgreSQL
# =============================================================

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[seed]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[seed]${NC} $1"
}

fail() {
    echo -e "${RED}[seed]${NC} $1"
    exit 1
}

# -------------------------------------------------------------
# Configuration
# -------------------------------------------------------------

PROJECT_DIR="/home/ubuntu/ApexFit"
SERVICE_DIR="$PROJECT_DIR/services/user-service"
ENV_FILE="$SERVICE_DIR/.env"

# -------------------------------------------------------------
# Validate directories
# -------------------------------------------------------------

[[ -d "$PROJECT_DIR" ]] || fail "Project directory not found: $PROJECT_DIR"

[[ -d "$SERVICE_DIR" ]] || fail "User service directory not found: $SERVICE_DIR"

[[ -f "$ENV_FILE" ]] || fail "Environment file not found: $ENV_FILE"

# -------------------------------------------------------------
# Load environment variables
# -------------------------------------------------------------

log "Loading production environment..."

set -a
source "$ENV_FILE"
set +a

# -------------------------------------------------------------
# Validate database configuration
# -------------------------------------------------------------

[[ -n "${DB_HOST:-}" ]] || fail "DB_HOST is not set"

[[ -n "${DB_PORT:-}" ]] || fail "DB_PORT is not set"

[[ -n "${DB_NAME:-}" ]] || fail "DB_NAME is not set"

[[ -n "${DB_USER:-}" ]] || fail "DB_USER is not set"

[[ -n "${DB_PASSWORD:-}" ]] || fail "DB_PASSWORD is not set"

log "Database host: ${DB_HOST}:${DB_PORT}"
log "Database name: ${DB_NAME}"
log "Database user: ${DB_USER}"

# -------------------------------------------------------------
# Check Node.js
# -------------------------------------------------------------

command -v node >/dev/null 2>&1 || fail "Node.js is not installed"

log "Node version: $(node --version)"

# -------------------------------------------------------------
# Check required Node modules
# -------------------------------------------------------------

cd "$SERVICE_DIR"

node -e "require('pg'); require('bcryptjs')" \
    || fail "Required Node modules (pg/bcryptjs) are not installed."

# -------------------------------------------------------------
# Seed admin user
# -------------------------------------------------------------

log "Checking for existing admin user..."

node <<'NODE'
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 5432),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
});

const email = 'admin@apexfit.com';
const username = 'admin';
const role = 'admin';

async function seedAdmin() {
    try {
        const existing = await pool.query(
            'SELECT id, email, role FROM users WHERE email = $1',
            [email]
        );

        if (existing.rows.length > 0) {
            const user = existing.rows[0];

            console.log(
                `[seed] Admin already exists — id: ${user.id}, email: ${user.email}, role: ${user.role}`
            );

            return;
        }

        /*
         * For production, provide the password through an
         * environment variable instead of hardcoding it.
         *
         * Example:
         *
         * ADMIN_PASSWORD='YourPassword' ./scripts/seed-admin-production.sh
         */

        const password = process.env.ADMIN_PASSWORD;

        if (!password) {
            throw new Error(
                'ADMIN_PASSWORD environment variable is not set.'
            );
        }

        const passwordHash = await bcrypt.hash(password, 12);

        const result = await pool.query(
            `
            INSERT INTO users
                (email, username, password_hash, role, is_active)
            VALUES
                ($1, $2, $3, $4, TRUE)
            RETURNING id, email, role
            `,
            [email, username, passwordHash, role]
        );

        const user = result.rows[0];

        console.log(
            `[seed] Admin created successfully — id: ${user.id}, email: ${user.email}, role: ${user.role}`
        );

    } finally {
        await pool.end();
    }
}

seedAdmin().catch((error) => {
    console.error(`[seed] Failed: ${error.message}`);
    process.exit(1);
});
NODE

log "Admin seed operation completed successfully."
