#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE="$SCRIPT_DIR/setup.conf"

# --- Helpers ---

ok()   { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo ""; echo "    $2"; exit 1; }
skip() { echo "  - $1 (skipped)"; }
step() { echo ""; echo "==> $1"; }

ssh_pi() {
  ssh -i "$SSH_KEY_EXPANDED" -o ConnectTimeout=5 "$PI_USER@$PI_HOST" "$@"
}

# --- Load config ---

if [ ! -f "$CONF_FILE" ]; then
  echo "Error: setup.conf not found"
  echo ""
  echo "  cp setup.conf.example setup.conf"
  echo "  # Fill in your values"
  echo "  ./setup.sh"
  exit 1
fi

source "$CONF_FILE"

# --- Validate config ---

step "Validating config"

ERRORS=""
if [ -z "${PI_HOST:-}" ]; then ERRORS="$ERRORS\n  - PI_HOST is empty"; fi
if [ -z "${PI_USER:-}" ]; then ERRORS="$ERRORS\n  - PI_USER is empty"; fi
if [ -z "${SSH_KEY:-}" ]; then ERRORS="$ERRORS\n  - SSH_KEY is empty"; fi
if [ -z "${SSD_DISK:-}" ]; then ERRORS="$ERRORS\n  - SSD_DISK is empty"; fi
if [ -z "${DOMAIN:-}" ]; then ERRORS="$ERRORS\n  - DOMAIN is empty"; fi
if [ -z "${POSTGRES_ADMIN_PASSWORD:-}" ]; then ERRORS="$ERRORS\n  - POSTGRES_ADMIN_PASSWORD is empty (generate with: openssl rand -hex 32)"; fi

if [ -n "$ERRORS" ]; then
  echo "Missing required values in setup.conf:"
  echo -e "$ERRORS"
  exit 1
fi

SSH_KEY_EXPANDED="${SSH_KEY/#\~/$HOME}"
if [ ! -f "$SSH_KEY_EXPANDED" ]; then
  fail "SSH key not found" "File does not exist: $SSH_KEY"
fi
ok "SSH key exists: $SSH_KEY"

if [ ${#POSTGRES_ADMIN_PASSWORD} -lt 16 ]; then
  fail "POSTGRES_ADMIN_PASSWORD is too short (${#POSTGRES_ADMIN_PASSWORD} chars)" \
       "Use at least 16 characters. Generate with: openssl rand -hex 32"
fi
ok "PostgreSQL password length: ${#POSTGRES_ADMIN_PASSWORD} chars"

ok "Config valid"
echo "    Pi: $PI_USER@$PI_HOST"
echo "    SSD: $SSD_DISK"
echo "    Domain: $DOMAIN"

# --- Check SSH connection ---

step "Checking SSH connection"
if ! ssh_pi "echo ok" >/dev/null 2>&1; then
  fail "Cannot connect to $PI_HOST" \
       "Check that the Pi is powered on and connected to your network."
fi
ok "SSH connected to $PI_HOST"

PI_MODEL=$(ssh_pi "cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo unknown")
ok "Device: $PI_MODEL"

if ! ssh_pi "ping -c1 -W3 1.1.1.1 >/dev/null 2>&1"; then
  fail "Pi has no internet access" \
       "Check WiFi or ethernet connection on the Pi."
fi
ok "Pi has internet access"

# --- Check and prepare SSD ---

step "Checking SSD"

if ! ssh_pi "test -b $SSD_DISK" 2>/dev/null; then
  echo ""
  echo "  SSD disk $SSD_DISK not found. Available devices:"
  echo ""
  ssh_pi "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT"
  echo ""
  fail "SSD disk not found" \
       "Update SSD_DISK in setup.conf with the correct disk path from the list above."
fi
ok "SSD disk found: $SSD_DISK"

SSD_SIZE_BYTES=$(ssh_pi "lsblk -bno SIZE $SSD_DISK 2>/dev/null | head -1 || echo 0")
SSD_SIZE_GB=$((SSD_SIZE_BYTES / 1073741824))
if [ "$SSD_SIZE_GB" -lt 100 ]; then
  echo "  ! Warning: SSD is only ${SSD_SIZE_GB}GB"
fi
ok "SSD size: ${SSD_SIZE_GB}GB"

# Determine partition path (nvme uses p1, sda uses 1)
if echo "$SSD_DISK" | grep -q "nvme"; then
  SSD_PARTITION="${SSD_DISK}p1"
else
  SSD_PARTITION="${SSD_DISK}1"
fi

# Create partition if it doesn't exist
if ! ssh_pi "test -b $SSD_PARTITION" 2>/dev/null; then
  echo "  No partition found. Creating partition..."
  ssh_pi "sudo parted $SSD_DISK --script mklabel gpt mkpart primary ext4 0% 100%"
  ssh_pi "sudo partprobe $SSD_DISK || sudo udevadm settle"
  sleep 1
  if ! ssh_pi "test -b $SSD_PARTITION" 2>/dev/null; then
    fail "Partition $SSD_PARTITION not found after creating" \
         "SSH into the Pi and run 'lsblk' to check."
  fi
  ok "Partition created: $SSD_PARTITION"
else
  ok "Partition exists: $SSD_PARTITION"
fi

# Format if needed
SSD_FSTYPE=$(ssh_pi "lsblk -no FSTYPE $SSD_PARTITION 2>/dev/null || true")
if [ -z "$SSD_FSTYPE" ]; then
  echo "  Formatting as ext4..."
  ssh_pi "sudo mkfs.ext4 -F $SSD_PARTITION"
  ok "Formatted as ext4"
elif [ "$SSD_FSTYPE" != "ext4" ]; then
  fail "SSD has unexpected filesystem: $SSD_FSTYPE" \
       "Expected ext4. Back up data and reformat if needed."
else
  ok "Already formatted (ext4)"
fi

# Check if mounted elsewhere
SSD_MOUNT_CURRENT=$(ssh_pi "lsblk -no MOUNTPOINT $SSD_PARTITION 2>/dev/null || true")
if [ -n "$SSD_MOUNT_CURRENT" ] && [ "$SSD_MOUNT_CURRENT" != "/mnt/ssd" ]; then
  fail "SSD is mounted at $SSD_MOUNT_CURRENT (expected /mnt/ssd)" \
       "Unmount first: sudo umount $SSD_PARTITION"
fi
if [ "$SSD_MOUNT_CURRENT" = "/mnt/ssd" ]; then
  ok "Already mounted at /mnt/ssd"
else
  ok "Ready to mount"
fi

# --- Check Ansible ---

step "Checking Ansible"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "  Installing Ansible..."
  "$SCRIPT_DIR/install.sh"
  ok "Ansible installed"
else
  ANSIBLE_VER=$(ansible-playbook --version | head -1)
  ok "$ANSIBLE_VER"
fi

if ! ansible-galaxy collection list 2>/dev/null | grep -q "community\.docker"; then
  echo "  Installing Ansible collections..."
  ansible-galaxy collection install -r "$SCRIPT_DIR/requirements.yml"
  ok "Collections installed"
else
  ok "Ansible collections present"
fi

# --- Run Ansible (provisioning only, skip deploy) ---

step "Running Ansible playbook (provisioning)"

cd "$SCRIPT_DIR"
ansible-playbook site.yml \
  -e "ssd_device=$SSD_PARTITION" \
  --skip-tags deploy

ok "Provisioning complete"

# --- Write .env on Pi ---

step "Writing core stack .env"

ssh_pi "cat > /mnt/ssd/stacks/core/.env" <<EOF
DOMAIN=$DOMAIN
POSTGRES_ADMIN_USER=admin
POSTGRES_ADMIN_PASSWORD=$POSTGRES_ADMIN_PASSWORD
EOF

ok "Core .env written"

# --- Run Ansible (full, including deploy) ---

step "Deploying core stack"

ansible-playbook site.yml -e "ssd_device=$SSD_PARTITION"

# Verify core services
RUNNING=$(ssh_pi "docker ps --format '{{.Names}}' 2>/dev/null | sort | tr '\n' ' '")
ok "Running containers: $RUNNING"

for EXPECTED in caddy postgres redis redis-durable; do
  if echo "$RUNNING" | grep -q "$EXPECTED"; then
    ok "$EXPECTED is running"
  else
    fail "$EXPECTED is not running" \
         "Check logs: ssh $PI_USER@$PI_HOST 'docker logs $EXPECTED'"
  fi
done

# --- Tailscale ---

step "Tailscale"

if [ -n "${TAILSCALE_AUTH_KEY:-}" ]; then
  if ssh_pi "tailscale status >/dev/null 2>&1"; then
    TS_IP=$(ssh_pi "tailscale ip -4")
    ok "Already connected: $TS_IP"
  else
    ssh_pi "sudo tailscale up --auth-key=$TAILSCALE_AUTH_KEY --ssh --accept-routes"
    TS_IP=$(ssh_pi "tailscale ip -4")
    ok "Connected: $TS_IP"
  fi
  echo "    Use $TS_IP as PI_HOST in GitHub Secrets."
else
  skip "No auth key provided"
  echo "    Set up later: ssh into Pi and run 'sudo tailscale up --ssh --accept-routes'"
fi

# --- Cloudflare Tunnel ---

step "Cloudflare Tunnel"

if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
  if ssh_pi "systemctl is-active cloudflared >/dev/null 2>&1"; then
    ok "Already running"
  else
    ssh_pi "sudo cloudflared service install $CLOUDFLARE_TUNNEL_TOKEN"
    ssh_pi "sudo systemctl start cloudflared"
    ok "Tunnel started"
  fi
else
  skip "No token provided"
  echo "    Set up later — see docs/architecture.md"
fi

# --- Final verification ---

step "Final verification"

ok "Hostname: $(ssh_pi 'hostname')"

DOCKER_VER=$(ssh_pi "docker --version")
ok "$DOCKER_VER"

SSD_FREE=$(ssh_pi "df -h /mnt/ssd | tail -1 | awk '{print \$4}'")
ok "SSD free space: $SSD_FREE"

RAM_FREE=$(ssh_pi "free -h | grep Mem | awk '{print \$7}'")
ok "RAM available: $RAM_FREE"

# --- Done ---

echo ""
echo "========================================="
echo "  Productforge is ready!"
echo "========================================="
echo ""
echo "  SSH:      ssh -i $SSH_KEY $PI_USER@$PI_HOST"
echo "  Domain:   $DOMAIN"
if [ -n "${TS_IP:-}" ]; then
echo "  Tailscale: $TS_IP"
fi
echo ""
echo "  Core services:"
echo "    ✓ Caddy (reverse proxy)"
echo "    ✓ PostgreSQL (shared, localhost:5432)"
echo "    ✓ Redis cache (localhost:6379)"
echo "    ✓ Redis durable (localhost:6380)"
echo ""
echo "  Next steps:"
echo "    1. Provision an app:  ./scripts/provision-app.sh myapp"
echo "    2. Deploy an app:     ./scripts/deploy.sh myapp:latest /path/to/app"
echo "    3. Deploy a site:     ./scripts/deploy-site.sh landing ./dist"
echo ""
