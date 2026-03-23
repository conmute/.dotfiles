#!/bin/bash
set -euo pipefail

# Deploy app(s) to productforge
#
# Usage:
#   Single image:  ./deploy.sh <image:tag> <compose-dir> [host]
#   Monorepo:      ./deploy.sh <project-dir> [host]
#
# Single image examples:
#   ./deploy.sh myapp:latest .
#   ./deploy.sh myapp:v1.2.3 ./deploy productforge.local
#
# Monorepo examples (auto-builds all services with build: in docker-compose.yml):
#   ./deploy.sh ./my-project
#   ./deploy.sh ./my-project productforge.local

SSH_KEY="$HOME/.ssh/id_productforge"
PI_USER="ross"

deploy_single() {
  local IMAGE="$1"
  local COMPOSE_DIR="$2"
  local HOST="${3:-productforge.local}"
  local SSH="ssh -i $SSH_KEY $PI_USER@$HOST"
  local APP_NAME
  APP_NAME=$(echo "$IMAGE" | cut -d: -f1 | sed 's|.*/||')
  local REMOTE_DIR="/mnt/ssd/stacks/$APP_NAME"

  echo "==> Saving and loading image: $IMAGE"
  docker save "$IMAGE" | $SSH "docker load"

  echo "==> Ensuring remote directory: $REMOTE_DIR"
  $SSH "mkdir -p $REMOTE_DIR"

  echo "==> Copying compose files"
  scp -i "$SSH_KEY" "$COMPOSE_DIR/docker-compose.yml" "$PI_USER@$HOST:$REMOTE_DIR/"

  if [ -f "$COMPOSE_DIR/.env" ]; then
    scp -i "$SSH_KEY" "$COMPOSE_DIR/.env" "$PI_USER@$HOST:$REMOTE_DIR/"
  fi

  echo "==> Starting stack"
  $SSH "cd $REMOTE_DIR && docker compose up -d --remove-orphans"

  echo "==> Done. $APP_NAME is running on $HOST"
}

deploy_monorepo() {
  local PROJECT_DIR="$1"
  local HOST="${2:-productforge.local}"
  local SSH="ssh -i $SSH_KEY $PI_USER@$HOST"
  local COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"

  if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: $COMPOSE_FILE not found"
    exit 1
  fi

  local PROJECT_NAME
  PROJECT_NAME=$(basename "$(cd "$PROJECT_DIR" && pwd)")
  local REMOTE_DIR="/mnt/ssd/stacks/$PROJECT_NAME"

  echo "==> Deploying monorepo: $PROJECT_NAME"

  # Build all images
  echo "==> Building all services"
  docker compose -f "$COMPOSE_FILE" build

  # Extract images for services that have a build context (using JSON for reliability)
  local -a IMAGES_TO_SHIP=()
  local CONFIG_JSON
  CONFIG_JSON=$(docker compose -f "$COMPOSE_FILE" config --format json)

  while IFS= read -r IMAGE; do
    if [ -n "$IMAGE" ]; then
      IMAGES_TO_SHIP+=("$IMAGE")
      echo "    Built: $IMAGE"
    fi
  done < <(echo "$CONFIG_JSON" | jq -r '.services[] | select(.build != null) | .image // empty')

  if [ ${#IMAGES_TO_SHIP[@]} -eq 0 ]; then
    echo "Error: No services with build: found in $COMPOSE_FILE"
    exit 1
  fi

  # Ship all built images in one docker save
  echo "==> Shipping ${#IMAGES_TO_SHIP[@]} images to Pi"
  docker save "${IMAGES_TO_SHIP[@]}" | $SSH "docker load"

  # Copy compose and env files
  echo "==> Copying compose files"
  $SSH "mkdir -p $REMOTE_DIR"
  scp -i "$SSH_KEY" "$COMPOSE_FILE" "$PI_USER@$HOST:$REMOTE_DIR/"

  if [ -f "$PROJECT_DIR/.env" ]; then
    scp -i "$SSH_KEY" "$PROJECT_DIR/.env" "$PI_USER@$HOST:$REMOTE_DIR/"
  fi

  # Deploy
  echo "==> Starting stack"
  $SSH "cd $REMOTE_DIR && docker compose up -d --remove-orphans"

  echo "==> Done. $PROJECT_NAME is running on $HOST"
}

# --- Main ---

FIRST_ARG="${1:?Usage: deploy.sh <image:tag> <compose-dir> OR deploy.sh <project-dir> [host]}"

if [ -d "$FIRST_ARG" ]; then
  deploy_monorepo "$@"
else
  deploy_single "$@"
fi
