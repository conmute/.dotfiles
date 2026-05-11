#!/bin/bash
set -euo pipefail

# Deploy a static site to productforge
# Usage: ./deploy-site.sh <site-name> <local-dir>
#
# Host is picked from the active profile (default: home).
# For Tailscale: PROFILE=remote ./deploy-site.sh <site-name> <local-dir>

# shellcheck source=_load-profile.sh
source "$(dirname "$0")/_load-profile.sh"

SITE="${1:?Usage: deploy-site.sh <site-name> <local-dir>}"
LOCAL_DIR="${2:?Provide path to the static site directory}"
HOST="$PI_HOST"

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
echo "To make it routable, add a labels-only container to your tenant's"
echo "docker-compose.yml (NOT to productforge's core compose):"
echo ""
echo "    $SITE-labels:"
echo "      image: busybox"
echo "      command: sleep infinity"
echo "      restart: unless-stopped"
echo "      networks: [web]"
echo "      labels:"
echo "        caddy: http://<your-hostname>           # e.g. http://example.com"
echo "        caddy.root: \"* /sites/$SITE\""
echo "        caddy.file_server:"
echo ""
echo "Then redeploy with: ./scripts/deploy.sh <your-tenant-dir>"
echo "(See docs/PLATFORM.md §3.2 for context.)"
