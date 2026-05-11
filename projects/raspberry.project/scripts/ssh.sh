#!/bin/bash
set -euo pipefail
# shellcheck source=_load-profile.sh
source "$(dirname "$0")/_load-profile.sh"
ssh -i "$SSH_KEY" "$PI_USER@$PI_HOST" "$@"
