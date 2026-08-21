#!/bin/bash
# =============================================================
# ApexFit — Seed Default Admin User
# Creates: admin@apexfit.com / Admin@123  (role: admin)
#
# Usage (Local):          ./scripts/seed-admin.sh
# Usage (Docker):         ./scripts/seed-admin.sh --docker
# Usage (Kubernetes/k3s): ./scripts/seed-admin.sh --k8s
# =============================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[seed]${NC} $1"; }
warn() { echo -e "${YELLOW}[seed]${NC} $1"; }
fail() { echo -e "${RED}[seed]${NC} $1"; exit 1; }

MODE="local"

if [[ "$1" == "--docker" ]]; then
  MODE="docker"
elif [[ "$1" == "--k8s" ]]; then
  MODE="k8s"
fi

NODE_SCRIPT="
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

(async () => {
  const email    = 'admin@apexfit.com';
  const username = 'admin';
  const password = 'Admin@123';
  const role     = 'admin';

  const { rows } = await pool.query(
    'SELECT id FROM users WHERE email = \\\$1',
    [email]
  );

  if (rows.length > 0) {
    console.log('[seed] Admin user already exists (id: ' + rows[0].id + '). Skipping.');
    await pool.end();
    return;
  }

  const password_hash = await bcrypt.hash(password, 12);

  const result = await pool.query(
    'INSERT INTO users (email, username, password_hash, role, is_active) VALUES (\\\$1, \\\$2, \\\$3, \\\$4, TRUE) RETURNING id, email, role',
    [email, username, password_hash, role]
  );

  const user = result.rows[0];

  console.log('[seed] ✅ Admin created — id: ' + user.id + ', email: ' + user.email + ', role: ' + user.role);

  await pool.end();

})().catch(err => {
  console.error('[seed] ❌ Failed:', err.message);
  process.exit(1);
});
"

if [[ "$MODE" == "k8s" ]]; then
  # ── Kubernetes / k3s mode ─────────────────────────────────
  NAMESPACE="apexfit"
  POD_SELECTOR="app=apexfit-backend-user-service"

  POD=$(kubectl get pod -n "$NAMESPACE" -l "$POD_SELECTOR" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

  if [[ -z "$POD" ]]; then
    POD=$(kubectl get pod -n "$NAMESPACE" --no-headers 2>/dev/null | awk '/apexfit-backend-user-service/{print $1}' | head -1)
  fi

  [[ -z "$POD" ]] && fail "Could not find user-service pod in namespace '$NAMESPACE'. Is it running?"

  log "Targeting pod: $POD (namespace: $NAMESPACE)"
  log "Seeding default admin user..."

  kubectl exec -n "$NAMESPACE" "$POD" -- node -e "$NODE_SCRIPT"

elif [[ "$MODE" == "docker" ]]; then
  # ── Docker Compose mode ───────────────────────────────────
  CONTAINER="apexfit-user-service"

  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    fail "Container '${CONTAINER}' is not running. Start with: docker compose up -d"
  fi

  log "Targeting container: $CONTAINER"
  log "Seeding default admin user..."

  docker exec "$CONTAINER" node -e "$NODE_SCRIPT"

else
  # ── Local mode ─────────────────────────────────────────────

  USER_SERVICE_DIR="$(cd "$(dirname "$0")/../services/user-service" && pwd)"

  [[ -d "$USER_SERVICE_DIR" ]] || fail "User service directory not found: $USER_SERVICE_DIR"

  log "Running locally..."
  log "Using user-service: $USER_SERVICE_DIR"

  (
    cd "$USER_SERVICE_DIR"

    if [[ -f ".env" ]]; then
      log "Loading .env"
      set -a
      source .env
      set +a
    else
      fail ".env not found in $USER_SERVICE_DIR"
    fi

    node -e "$NODE_SCRIPT"
  )
fi

log "Done."
log "Login with: admin@apexfit.com / Admin@123"
