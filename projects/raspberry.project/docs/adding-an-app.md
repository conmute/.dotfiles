# Adding a New App to Productforge

## Step 1: Provision database

Run from your Mac:

```bash
./scripts/provision-app.sh myapp
```

This creates a PostgreSQL database + user with a random password and outputs env vars:

```
DATABASE_URL=postgres://myapp:a1b2c3...@postgres:5432/myapp
REDIS_URL=redis://redis:6379/0
REDIS_DURABLE_URL=redis://redis-durable:6379/0
```

Save these for your `.env` file. Re-running updates the password.

## Step 2: Create your app repo

### Single app structure

```
my-app/
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .env                          (not committed)
└── .github/workflows/deploy.yml
```

### Monorepo structure

```
my-project/
├── apps/
│   ├── landing/Dockerfile
│   ├── api/Dockerfile
│   └── dashboard/Dockerfile
├── packages/                     (shared code)
├── docker-compose.yml
├── .env.example
├── .env                          (not committed)
└── .github/workflows/deploy.yml
```

### Dockerfile

Use multi-stage builds to keep images small:

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

### docker-compose.yml — single app

Apps use shared PostgreSQL and Redis — no per-app database containers:

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

### .env.example

```
DOMAIN=example.com
DATABASE_URL=postgres://myapp:password@postgres:5432/myapp
REDIS_URL=redis://redis:6379/0
REDIS_DURABLE_URL=redis://redis-durable:6379/0
SECRET_KEY=
```

### GitHub Actions workflow

Copy from `docs/deploy-template/.github/workflows/deploy.yml.example`.

Required GitHub Secrets:
- `TS_OAUTH_CLIENT_ID` — Tailscale OAuth client ID
- `TS_OAUTH_SECRET` — Tailscale OAuth secret
- `SSH_PRIVATE_KEY` — contents of `~/.ssh/id_productforge`
- `PI_HOST` — Tailscale IP of the Pi (e.g. `100.x.x.x`)
- `DOMAIN` — your domain name
- `DATABASE_URL` — from `provision-app.sh` output
- `REDIS_URL` — from `provision-app.sh` output
- `SECRET_KEY` — app-specific secret

The workflow writes `.env` on the Pi from these secrets during deployment.

## Step 3: Deploy

### From GitHub (automatic)
Push to `main` — GitHub Actions builds all images, ships to Pi, deploys.

### From MacBook (manual)

```bash
# Single app
docker build -t myapp:latest .
./scripts/deploy.sh myapp:latest .

# Monorepo (auto-builds all services with build: context)
./scripts/deploy.sh ./my-project
```

## Shared services

Apps connect to shared infrastructure via the `internal` Docker network:

| Service | Docker host | Container port | Use |
|---------|-------------|---------------|-----|
| PostgreSQL | `postgres` | 5432 | One database per app, provisioned via `provision-app.sh` |
| Redis (cache) | `redis` | 6379 | Ephemeral cache, LRU eviction, use key prefix `myapp:` |
| Redis (durable) | `redis-durable` | 6379 | Sessions, queues — AOF persistence enabled |

### Access from Mac via SSH tunnel

Database ports are bound to localhost only on the Pi. Access via SSH tunnel:

```bash
# PostgreSQL
ssh -i ~/.ssh/id_productforge -L 5432:localhost:5432 ross@productforge.local

# Redis cache
ssh -i ~/.ssh/id_productforge -L 6379:localhost:6379 ross@productforge.local

# Redis durable
ssh -i ~/.ssh/id_productforge -L 6380:localhost:6380 ross@productforge.local
```

## Redis key namespacing

Use your app name as a key prefix to avoid collisions:

```
myapp:cache:users:123
myapp:session:abc
otherapp:cache:products:456
```

## Backups

```bash
./scripts/backup-db.sh              # backup all databases
./scripts/backup-db.sh myapp        # backup single app
```

Dumps are saved atomically to `/mnt/ssd/backups/` on the Pi.

## Static sites (landing pages)

For simple HTML sites with assets, no Docker containers needed. Caddy serves them directly from files.

### Step 1: Deploy files

```bash
# Build your site locally, then sync
./scripts/deploy-site.sh my-landing ./dist
```

Files are synced to `/mnt/ssd/sites/my-landing/` on the Pi.

### Step 2: Add Caddy labels

Edit `configs/opt/productforge/stacks/core/docker-compose.yml` and add labels to the caddy service:

```yaml
services:
  caddy:
    labels:
      # Existing app labels...

      # Static site — use incrementing numbers (caddy_0, caddy_1, ...)
      caddy_0: http://my-landing.${DOMAIN}
      caddy_0.root: "* /sites/my-landing"
      caddy_0.file_server:

      caddy_1: http://another-landing.${DOMAIN}
      caddy_1.root: "* /sites/another-landing"
      caddy_1.file_server:
```

Then redeploy the core stack:

```bash
ansible-playbook site.yml --tags stacks
# or manually on Pi:
cd /mnt/ssd/stacks/core && docker compose up -d
```

### Step 3: Update files

Just rsync again — no restart needed, Caddy serves from the mounted directory:

```bash
./scripts/deploy-site.sh my-landing ./dist
```

### GitHub Actions for static sites

```yaml
- name: Deploy static site
  run: |
    rsync -avz --delete \
      -e "ssh -i ~/.ssh/id_pi -o StrictHostKeyChecking=no" \
      ./dist/ "ross@${{ secrets.PI_HOST }}:/mnt/ssd/sites/my-landing/"
```

No Docker build needed. Just rsync the files.

## Important notes

- Apps join both `web` (for Caddy routing) and `internal` (for database access) networks
- Add `caddy` and `caddy.reverse_proxy` labels for public access
- Do NOT run per-app PostgreSQL/Redis containers — use the shared instances
- Persistent app-specific data (uploads, files) → `/mnt/ssd/volumes/<appname>/`
- Monorepo services must have both `build:` and `image:` keys for the deploy script to work
