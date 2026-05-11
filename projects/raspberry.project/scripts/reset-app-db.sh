#!/bin/bash
set -euo pipefail

# Drop and recreate an app's PostgreSQL database and role.
# Usage: ./reset-app-db.sh <appname> [--yes]
#
# For pre-public iteration: wipes state, reprovisions with a new password,
# prints fresh DATABASE_URL.
#
#   ./reset-app-db.sh myapp           # prompts for typed confirmation
#   ./reset-app-db.sh myapp --yes     # skip prompt (scripted use)
#   PROFILE=remote ./reset-app-db.sh myapp   # via Tailscale

# shellcheck source=_load-profile.sh
source "$(dirname "$0")/_load-profile.sh"

APP="${1:?Usage: reset-app-db.sh <appname> [--yes]}"
SKIP_PROMPT="${2:-}"

if [[ ! "$APP" =~ ^[a-z][a-z0-9_-]{0,62}$ ]]; then
  echo "Error: app name must start with a letter and contain only lowercase letters, digits, underscores, or hyphens (max 63 chars)" >&2
  exit 1
fi

SSH="ssh -i $SSH_KEY $PI_USER@$PI_HOST"

echo "==> Resetting database: $APP"
echo "  ! This will DROP DATABASE \"$APP\" and DROP USER \"$APP\""

if [ "$SKIP_PROMPT" != "--yes" ]; then
  read -r -p "  Type the app name to confirm: " CONFIRM
  if [ "$CONFIRM" != "$APP" ]; then
    echo "  Aborted (got: $CONFIRM)" >&2
    exit 1
  fi
fi

echo "==> Terminating active connections to $APP"
$SSH "docker exec -i postgres psql -U admin -d postgres" <<SQL >/dev/null
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$APP' AND pid <> pg_backend_pid();
SQL

echo "==> Dropping database and role"
$SSH "docker exec -i postgres psql -U admin -d postgres" <<SQL >/dev/null
DROP DATABASE IF EXISTS "$APP";
DROP USER IF EXISTS "$APP";
SQL

echo "==> Reprovisioning..."
echo ""
exec "$(dirname "$0")/provision-app.sh" "$APP"
