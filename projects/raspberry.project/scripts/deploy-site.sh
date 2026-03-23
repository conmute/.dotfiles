#!/bin/bash
set -euo pipefail

# Deploy a static site to productforge
# Usage: ./deploy-site.sh <site-name> <local-dir> [host]
#
# Examples:
#   ./deploy-site.sh landing-a ./dist
#   ./deploy-site.sh landing-b ./build productforge.local

SITE="${1:?Usage: deploy-site.sh <site-name> <local-dir> [host]}"
LOCAL_DIR="${2:?Provide path to the static site directory}"
HOST="${3:-productforge.local}"
PI_USER="ross"
SSH_KEY="$HOME/.ssh/id_productforge"

if [ ! -d "$LOCAL_DIR" ]; then
  echo "Error: $LOCAL_DIR is not a directory"
  exit 1
fi

echo "==> Deploying static site: $SITE"
rsync -avz --delete --no-owner --no-group --chmod=D755,F644 \
  -e "ssh -i $SSH_KEY" \
  "$LOCAL_DIR/" "$PI_USER@$HOST:/mnt/ssd/sites/$SITE/"

echo "==> Done. Files synced to /mnt/ssd/sites/$SITE/"
echo ""
echo "To make it accessible, add these labels to the caddy service in core/docker-compose.yml:"
echo ""
echo '    labels:'
echo '      caddy_N: http://'"$SITE"'.${DOMAIN}'
echo '      caddy_N.root: "* /sites/'"$SITE"'"'
echo '      caddy_N.file_server:'
echo ""
echo "Replace N with the next available number (0, 1, 2, ...)"
