#!/bin/bash
set -euo pipefail

# Provision a new app's database and Redis namespace
# Usage: ./provision-app.sh <appname> [host]
#
# Creates:
#   - PostgreSQL database + user with random password
#   - Outputs .env vars for the app
#
# Examples:
#   ./provision-app.sh myapp
#   ./provision-app.sh myapp productforge.local

APP="${1:?Usage: provision-app.sh <appname> [host]}"
HOST="${2:-productforge.local}"
SSH_KEY="$HOME/.ssh/id_productforge"
SSH="ssh -i $SSH_KEY ross@$HOST"

# Validate app name — only lowercase letters, digits, underscores, hyphens
if [[ ! "$APP" =~ ^[a-z][a-z0-9_-]{0,62}$ ]]; then
  echo "Error: app name must start with a letter and contain only lowercase letters, digits, underscores, or hyphens (max 63 chars)"
  exit 1
fi

DB_PASSWORD=$(openssl rand -hex 16)

echo "==> Provisioning PostgreSQL database and user for: $APP"

# Create or update user, create database — piped via stdin to avoid credential exposure
$SSH "docker exec -i postgres psql -U admin" <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$APP') THEN
    CREATE USER "$APP" WITH PASSWORD '$DB_PASSWORD';
  ELSE
    ALTER USER "$APP" WITH PASSWORD '$DB_PASSWORD';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE "$APP" OWNER "$APP"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$APP')\gexec

GRANT ALL PRIVILEGES ON DATABASE "$APP" TO "$APP";
SQL

echo ""
echo "==> Done. Add these to your app's .env file:"
echo ""
echo "DATABASE_URL=postgres://$APP:$DB_PASSWORD@postgres:5432/$APP"
echo "REDIS_URL=redis://redis:6379/0"
echo "REDIS_DURABLE_URL=redis://redis-durable:6379/0"
echo ""
echo "Note: Use key prefix '$APP:' in Redis to namespace your keys."
echo "Note: If re-running for an existing app, the password has been updated. Update your .env accordingly."
