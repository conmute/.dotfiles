#!/bin/bash
# Install Ansible + required collections on a workstation (macOS or Linux).
#
# Uses uv instead of Homebrew: uv pulls prebuilt Python + wheels, so nothing
# is compiled. (On older macOS, `brew install ansible` builds cryptography →
# rust → llvm from source, which takes hours.)
#
# Idempotent: safe to re-run. Pass --upgrade to upgrade Ansible.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UV_BIN_DIR="$HOME/.local/bin"
export PATH="$UV_BIN_DIR:$PATH"

# --- uv ---
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  # Official installer, not `brew install uv` (that may compile Rust too).
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
echo "==> $(uv --version)"

# --- Ansible ---
if uv tool list 2>/dev/null | grep -q '^ansible-core '; then
  if [ "${1:-}" = "--upgrade" ]; then
    echo "==> Upgrading Ansible"
    uv tool upgrade ansible-core
  else
    echo "==> Ansible already installed via uv (pass --upgrade to upgrade)"
  fi
else
  echo "==> Installing Ansible"
  uv tool install ansible-core --with ansible
fi

# Make sure uv's tool bin dir is on PATH in future shells.
uv tool update-shell >/dev/null 2>&1 || true

ANSIBLE_BIN="$(uv tool dir --bin)"
case "$(command -v ansible-playbook)" in
  "$ANSIBLE_BIN"/*) ;;
  *) echo "  ! ansible-playbook on PATH is $(command -v ansible-playbook), not the uv one in $ANSIBLE_BIN" >&2
     echo "    (e.g. a Homebrew install — remove it with 'brew uninstall ansible' if unwanted)" >&2 ;;
esac

# --- Collections ---
echo "==> Installing Ansible collections"
"$ANSIBLE_BIN/ansible-galaxy" collection install -r "$SCRIPT_DIR/requirements.yml"

echo ""
echo "==> Done: $("$ANSIBLE_BIN/ansible-playbook" --version | head -1)"
echo "    Open a new shell (or: export PATH=\"$ANSIBLE_BIN:\$PATH\") to use it."
