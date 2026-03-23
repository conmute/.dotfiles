# Productforge Architecture

## Hardware

- Raspberry Pi 5, 16GB RAM, 2TB SSD
- microSD: OS only (Raspberry Pi OS Lite 64-bit)
- SSD mounted at `/mnt/ssd`: all Docker data, app volumes, backups

## Request flow

```
User browser
    ↓
DNS (Cloudflare)
    myapp.yourdomain.com CNAME → <tunnel-id>.cfargotunnel.com
    ↓
Cloudflare Edge
    Terminates SSL, DDoS protection
    Forwards through encrypted tunnel
    ↓
cloudflared daemon (Pi, outbound connection only)
    Receives request, forwards to localhost:80
    ↓
Caddy (caddy-docker-proxy, port 80)
    Reads Host header, matches Docker container labels
    Routes to correct container
    ↓
App container (e.g. :3000)
    Handles request, returns response
    ↓
    Connects to shared services via internal network:
    ├── postgres:5432 (shared PostgreSQL)
    ├── redis:6379 (shared cache)
    └── redis-durable:6379 (shared sessions/queues)
```

SSL terminates at Cloudflare. All traffic inside the Pi is plain HTTP on localhost.

**Important**: Caddy labels must use `http://` prefix (e.g. `http://myapp.conmute.com`) to disable Caddy's automatic HTTPS. Without this, Caddy redirects HTTP → HTTPS, causing an infinite redirect loop with Cloudflare Tunnel which delivers traffic as HTTP.

## Docker networking

```
                    ┌─────────────────────────────┐
                    │        web network           │
                    │                              │
                    │  Caddy ◄──► App containers   │
                    │  (discovers via labels)      │
                    └─────────────────────────────┘
                                 │
                          apps join both
                                 │
                    ┌─────────────────────────────┐
                    │      internal network        │
                    │                              │
                    │  App containers ──► Postgres  │
                    │                 ──► Redis     │
                    │                 ──► Redis     │
                    │                     (durable) │
                    └─────────────────────────────┘
```

- `web` network: Caddy discovers and proxies app containers via Docker labels
- `internal` network: apps connect to shared databases
- Apps join both networks. Databases join only `internal` — not reachable from the internet.

## Network access

| From | How | What's accessible |
|------|-----|-------------------|
| Home network (192.168.0.0/24) | SSH on port 22 | Full SSH access, always available |
| Your devices anywhere | Tailscale (100.x.x.x) | SSH + all app ports |
| GitHub Actions CI | Tailscale (OAuth) | SSH for deployments |
| Public internet | Cloudflare Tunnel | Only apps with Caddy labels |

No ports are open to the internet. UFW blocks all incoming except SSH from LAN and Tailscale interface.

### Why Tailscale has all ports open

Tailscale is a private encrypted mesh network — only your authenticated devices can reach the Pi through it. All ports are open on the Tailscale interface for practical reasons:

| Port | Use case |
|------|----------|
| 22 | SSH, Claude Code from iPad |
| 80/443 | Test apps via Tailscale before exposing via Cloudflare |
| 3000, 4000, 8080 | Hit app containers directly without going through Caddy |

### Database access

Database ports (PostgreSQL 5432, Redis 6379/6380) are bound to `localhost` only — Docker does not expose them on any network interface, preventing Docker's iptables bypass of UFW.

Access from your Mac via SSH tunnel:

```bash
# PostgreSQL
ssh -i ~/.ssh/id_productforge -L 5432:localhost:5432 ross@productforge.local
# Then connect DB client to localhost:5432

# Redis cache
ssh -i ~/.ssh/id_productforge -L 6379:localhost:6379 ross@productforge.local

# Redis durable
ssh -i ~/.ssh/id_productforge -L 6380:localhost:6380 ross@productforge.local
```

## What runs on the Pi

### Core (managed by Ansible)

| Service | Purpose | Runs as |
|---------|---------|--------|
| Docker | Container runtime, data-root on SSD | systemd service |
| Caddy | Reverse proxy, auto-discovers containers via Docker labels | Docker container |
| PostgreSQL 16 | Shared database — one cluster, one database per app | Docker container |
| Redis (cache) | Shared cache — 512MB, LRU eviction, ephemeral | Docker container |
| Redis (durable) | Shared sessions/queues — 256MB, AOF persistence | Docker container |
| cloudflared | Tunnel to Cloudflare, outbound only | systemd service |
| Tailscale | Private mesh network for remote access | systemd service |
| fail2ban | Blocks brute-force SSH attempts | systemd service |
| unattended-upgrades | Auto-installs security patches | systemd service |

### Apps (deployed per-repo)

Each app is a Docker Compose stack in `/mnt/ssd/stacks/<project>/`. Apps use shared PostgreSQL and Redis — no per-app database containers.

### Static sites (landing pages)

Served directly by Caddy from `/mnt/ssd/sites/<site-name>/`. No Docker containers — just files. Deployed via `rsync`, configured via Caddy labels on the core stack.

## Filesystem layout

```
/mnt/ssd/
├── docker/          Docker data-root (images, layers, containers)
├── stacks/          Compose files per project
│   ├── core/        Caddy + PostgreSQL + Redis (deployed by Ansible)
│   ├── myapp/       Single-app stack
│   └── myproject/   Monorepo stack (multiple services)
├── sites/           Static sites served directly by Caddy
│   ├── landing-a/   HTML + assets
│   └── landing-b/
├── volumes/         Persistent data
│   ├── caddy/
│   ├── caddy-config/
│   ├── postgres/    Shared PostgreSQL data
│   ├── redis/       Shared Redis cache
│   ├── redis-durable/ Shared Redis durable (sessions, queues)
│   └── myapp/       App-specific files (uploads, etc.)
└── backups/         PostgreSQL dumps (per-app or full)

/opt/productforge/
└── configs/         Version-controlled configs synced from repo
    └── etc/docker/daemon.json → symlinked to /etc/docker/daemon.json
```

## Resources available to apps

| Resource | Available | Notes |
|----------|-----------|-------|
| RAM | ~14.5GB usable | After OS + Docker + Caddy + PostgreSQL + Redis (~700MB overhead) |
| CPU | 4 cores ARM Cortex-A76 | Shared across all containers |
| Disk | ~2TB | SSD, shared via Docker volumes |
| PostgreSQL | Shared instance | One database per app, provisioned via `provision-app.sh` |
| Redis (cache) | Shared instance, 512MB max | Ephemeral cache, key-prefix per app, LRU eviction |
| Redis (durable) | Shared instance, 256MB max | Sessions/queues, AOF persistence, key-prefix per app |
| Network | Outbound unrestricted | Inbound only via Cloudflare Tunnel |

## App deployment

### Repo structures supported

**Single app:**
```
my-app/
├── Dockerfile
├── docker-compose.yml
├── .env
└── .github/workflows/deploy.yml
```

**Monorepo (multiple services):**
```
my-project/
├── apps/
│   ├── landing/Dockerfile
│   ├── api/Dockerfile
│   └── dashboard/Dockerfile
├── packages/              # shared code
├── docker-compose.yml     # all services defined here
├── .env
└── .github/workflows/deploy.yml
```

### docker-compose.yml — single app

```yaml
services:
  app:
    image: myapp:latest
    restart: unless-stopped
    networks: [web, internal]
    labels:
      caddy: http://myapp.${DOMAIN}
      caddy.reverse_proxy: "{{upstreams 3000}}"
    env_file: .env

networks:
  web:
    external: true
  internal:
    external: true
```

### docker-compose.yml — monorepo

```yaml
services:
  landing:
    build: ./apps/landing
    image: myproject-landing:latest
    networks: [web, internal]
    labels:
      caddy: http://myproject.${DOMAIN}
      caddy.reverse_proxy: "{{upstreams 3000}}"
    env_file: .env

  api:
    build: ./apps/api
    image: myproject-api:latest
    networks: [web, internal]
    labels:
      caddy: http://api.myproject.${DOMAIN}
      caddy.reverse_proxy: "{{upstreams 4000}}"
    env_file: .env

  dashboard:
    build: ./apps/dashboard
    image: myproject-dashboard:latest
    networks: [web, internal]
    labels:
      caddy: http://app.myproject.${DOMAIN}
      caddy.reverse_proxy: "{{upstreams 3001}}"
    env_file: .env

networks:
  web:
    external: true
  internal:
    external: true
```

Services can communicate internally via service names (e.g. `http://api:4000` from dashboard).

### Deployment paths

**From GitHub Actions (automatic on push to main):**
```
git push → CI builds all images → Tailscale → ships to Pi → docker compose up -d
```

**From MacBook (manual):**
```bash
# Single app
./scripts/deploy.sh myapp:latest .

# Monorepo (auto-builds all services with build: context)
./scripts/deploy.sh ./my-project
```

The deploy script auto-detects mode:
- Directory argument → monorepo mode: builds all services, ships all images in one `docker save`, deploys
- Image:tag argument → single mode: ships one image, deploys

### Adding a new app

```bash
# 1. Provision database
./scripts/provision-app.sh myapp
# Outputs DATABASE_URL, REDIS_URL, REDIS_DURABLE_URL

# 2. Create .env with the output + your app secrets

# 3. Deploy
./scripts/deploy.sh myapp:latest .
# or for monorepo:
./scripts/deploy.sh ./my-project
```

### DNS setup (one-time per domain)

In Cloudflare, CNAME `*.yourdomain.com` → tunnel. After that, any new app with a Caddy label on a subdomain works instantly — no DNS changes per app.

## Shared services

| Service | Docker host | Container port | Network | Access from Mac |
|---------|-------------|---------------|---------|-----------------|
| PostgreSQL | `postgres` | 5432 | `internal` | SSH tunnel → localhost:5432 |
| Redis (cache) | `redis` | 6379 | `internal` | SSH tunnel → localhost:6379 |
| Redis (durable) | `redis-durable` | 6379 | `internal` | SSH tunnel → localhost:6380 |

Apps connect using container hostnames and container ports:
```
DATABASE_URL=postgres://myapp:password@postgres:5432/myapp
REDIS_URL=redis://redis:6379/0
REDIS_DURABLE_URL=redis://redis-durable:6379/0
```

Use key prefix `myapp:` in Redis to namespace keys per app.

## Backups

```bash
./scripts/backup-db.sh              # backup all PostgreSQL databases
./scripts/backup-db.sh myapp        # backup single app database
```

Dumps are saved atomically to `/mnt/ssd/backups/` on the Pi. Backups use stream compression and atomic writes — a partial dump will never appear as a completed backup file.

Redis cache does not need backups (ephemeral). Redis durable persists via AOF — data survives container restarts.

## Security summary

- No open ports to internet
- SSH: key-only, no passwords, no root login
- Firewall: UFW deny all incoming, allow SSH from LAN (192.168.0.0/24), allow Tailscale interface
- Database ports: bound to localhost only (Docker iptables bypass mitigated)
- fail2ban: blocks repeated SSH failures (1h ban after 5 attempts)
- Auto-updates: unattended-upgrades for security patches
- Cloudflare: DDoS protection, SSL termination
- Docker socket: mounted read-only in Caddy
- Provisioning script: validates app names, pipes SQL via stdin (no credential exposure in process args)
- Ansible playbook: validates that default PostgreSQL password has been changed before deploying

## Provisioning from scratch

### Prerequisites

1. Flash SD card with Raspberry Pi Imager (Lite 64-bit, WiFi, SSH, key auth)
2. Connect SSD to the Pi (NVMe or USB)
3. Boot Pi and verify SSH works: `ssh -i ~/.ssh/id_productforge ross@productforge.local`

### SSD preparation

Find your SSD disk path:

```bash
ssh -i ~/.ssh/id_productforge ross@productforge.local "lsblk"

# Common paths:
#   /dev/nvme0n1   — NVMe SSD (Pi 5 PCIe)
#   /dev/sda       — USB SSD
```

The setup script handles partitioning and formatting automatically. You just need the disk path.

### Setup

```bash
cd projects/raspberry.project

# 1. Create and fill config
cp setup.conf.example setup.conf
# Edit setup.conf:
#   SSD_DISK=/dev/nvme0n1         (whole disk, from lsblk — NOT the partition)
#   DOMAIN=productforge.local     (or your real domain)
#   POSTGRES_ADMIN_PASSWORD=      (run: openssl rand -hex 32)
#   TAILSCALE_AUTH_KEY=           (optional, from tailscale.com admin)
#   CLOUDFLARE_TUNNEL_TOKEN=     (optional, from cloudflare zero trust)

# 2. Run setup — handles everything
./setup.sh
```

The setup script will:
- Validate config, SSH key, and connection
- Check SSD, create partition if needed, format as ext4
- Install Ansible and collections if missing
- Run the Ansible playbook (base, security, SSD, Docker, Tailscale, Cloudflare)
- Write core `.env` with your PostgreSQL password
- Deploy core stack (Caddy, PostgreSQL, Redis)
- Set up Tailscale and Cloudflare if tokens provided
- Verify all services are running

The script is idempotent — safe to re-run at any time.

## Plan B: Cloudflare Tunnel alternatives

If Cloudflare TOS becomes an issue (e.g. video content), swap to [frp](https://github.com/fatedier/frp) (105k stars, Go, mature). Requires a cheap VPS (~$3/mo) as relay. Caddy routing stays the same — only the tunnel layer changes.
