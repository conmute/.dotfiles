#!/bin/bash
set -euo pipefail

# Backup PostgreSQL databases
# Usage: ./backup-db.sh [appname]
#
# Without appname: dumps ALL databases
# With appname: dumps only that database
#
# Host is picked from the active profile (default: home).
# For Tailscale: PROFILE=remote ./backup-db.sh
#
# Examples:
#   ./backup-db.sh                    # backup all (home profile)
#   ./backup-db.sh myapp              # backup only myapp
#   PROFILE=remote ./backup-db.sh     # via Tailscale

# shellcheck source=_load-profile.sh
source "$(dirname "$0")/_load-profile.sh"

APP="${1:-}"
SSH="ssh -i $SSH_KEY $PI_USER@$PI_HOST"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/ssd/backups"

$SSH "mkdir -p $BACKUP_DIR"

if [ -z "$APP" ]; then
  echo "==> Backing up ALL PostgreSQL databases"
  DUMP_FILE="pg_all_$TIMESTAMP.sql.gz"
  # Stream-compress and write atomically via temp file
  $SSH "docker exec postgres pg_dumpall -U admin | gzip > $BACKUP_DIR/$DUMP_FILE.tmp && mv $BACKUP_DIR/$DUMP_FILE.tmp $BACKUP_DIR/$DUMP_FILE"
  echo "==> Saved to $BACKUP_DIR/$DUMP_FILE"
else
  echo "==> Backing up database: $APP"
  DUMP_FILE="pg_${APP}_$TIMESTAMP.sql.gz"
  $SSH "docker exec postgres pg_dump -U admin $APP | gzip > $BACKUP_DIR/$DUMP_FILE.tmp && mv $BACKUP_DIR/$DUMP_FILE.tmp $BACKUP_DIR/$DUMP_FILE"
  echo "==> Saved to $BACKUP_DIR/$DUMP_FILE"
fi

echo "==> Done"
