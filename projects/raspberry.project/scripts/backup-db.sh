#!/bin/bash
set -euo pipefail

# Backup PostgreSQL databases
# Usage: ./backup-db.sh [appname] [host]
#
# Without appname: dumps ALL databases
# With appname: dumps only that database
#
# Examples:
#   ./backup-db.sh                    # backup all
#   ./backup-db.sh myapp              # backup only myapp
#   ./backup-db.sh myapp 100.x.x.x   # via Tailscale

APP="${1:-}"
HOST="${2:-productforge.local}"
SSH_KEY="$HOME/.ssh/id_productforge"
SSH="ssh -i $SSH_KEY ross@$HOST"
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
