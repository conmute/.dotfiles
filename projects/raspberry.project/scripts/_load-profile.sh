#!/bin/bash
# Sourced by setup.sh and scripts/*.sh to load the active profile.
#
# Reads PROFILE (default: home) and sources:
#   1. setup.conf            — base config + secrets
#   2. setup.conf.$PROFILE   — overlay (typically only PI_HOST)
#
# Exports PI_HOST, PI_USER, SSH_KEY (~ expanded) so Ansible's
# inventory/hosts.yml can pick them up via lookup('env', ...).
#
# Usage:
#   source "$(dirname "$0")/_load-profile.sh"

_LP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
PROFILE="${PROFILE:-home}"

_lp_die() {
  echo "Error: $1" >&2
  # works whether this file is sourced or executed
  return 1 2>/dev/null || exit 1
}

if [ ! -f "$_LP_DIR/setup.conf" ]; then
  _lp_die "$_LP_DIR/setup.conf not found — cp setup.conf.example setup.conf and fill it in"
fi
# shellcheck disable=SC1091
source "$_LP_DIR/setup.conf"

_LP_OVERLAY="$_LP_DIR/setup.conf.$PROFILE"
if [ -f "$_LP_OVERLAY" ]; then
  # shellcheck disable=SC1090
  source "$_LP_OVERLAY"
elif [ "$PROFILE" != "home" ]; then
  _lp_die "profile config not found: $_LP_OVERLAY — cp setup.conf.$PROFILE.example setup.conf.$PROFILE and edit"
fi

# Expand ~ for downstream consumers (ssh, ansible).
SSH_KEY="${SSH_KEY/#\~/$HOME}"

export PROFILE PI_HOST PI_USER SSH_KEY

if [ -z "${LOAD_PROFILE_QUIET:-}" ]; then
  echo "==> profile: $PROFILE  ($PI_USER@$PI_HOST)" >&2
fi
