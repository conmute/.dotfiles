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
# Pin the controller Python: uv otherwise picks the newest it can find, and
# ansible-core lags behind (2.21 crashes on 3.15 with
# "module 'dataclasses' has no attribute '_is_type'").
ANSIBLE_PYTHON="${ANSIBLE_PYTHON:-3.13}"
export PATH="$UV_BIN_DIR:$PATH"

# --- uv ---
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Installing uv"
  # Official installer, not `brew install uv` (that may compile Rust too).
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
echo "==> $(uv --version)"

# --- Ansible ---
install_ansible() {
  uv tool install --force --python "$ANSIBLE_PYTHON" ansible-core --with ansible
}

if ! uv tool list 2>/dev/null | grep -q '^ansible-core '; then
  echo "==> Installing Ansible (Python $ANSIBLE_PYTHON)"
  install_ansible
elif [ "${1:-}" = "--upgrade" ]; then
  echo "==> Upgrading Ansible (Python $ANSIBLE_PYTHON)"
  # reinstall rather than `uv tool upgrade`, which keeps the old interpreter
  install_ansible
elif ! "$UV_BIN_DIR/ansible-playbook" --version >/dev/null 2>&1; then
  echo "==> Existing Ansible is broken (wrong Python?), reinstalling on $ANSIBLE_PYTHON"
  install_ansible
else
  echo "==> Ansible already installed via uv (pass --upgrade to upgrade)"
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
