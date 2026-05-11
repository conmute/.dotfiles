# Productforge Platform Contract

This is what productforge — the home server stack defined in
`raspberry.project/` — offers to **tenant apps** like `delve.network`. It is
the canonical reference for any tenant planning a deploy. Read it before
writing a deploy plan in your app repo.

> *"productforge is internal PaaS: it allocates shared resources and runs
> your container or static site behind a single ingress."*

---

## 1. Resource catalog

| Resource | Provisioned by | Returns |
|---|---|---|
| Postgres database + role | `scripts/provision-app.sh <app>` | `DATABASE_URL=postgres://<app>:<pw>@postgres:5432/<app>` |
| Postgres reset (drop + recreate) | `scripts/reset-app-db.sh <app>` | fresh `DATABASE_URL` with a new password |
| Redis cache namespace | (convention) | `REDIS_URL=redis://redis:6379/0`, prefix keys with `<app>:` |
| Redis durable namespace | (convention) | `REDIS_DURABLE_URL=redis://redis-durable:6379/0`, prefix keys with `<app>:` |
| Static site slot | `scripts/deploy-site.sh <site> <local-dir>` (allocates + ships on first run) | files at `/mnt/ssd/sites/<site>/`; labels snippet printed to stdout |
| Public hostname (HTTPS) | **manual** in the Cloudflare dashboard for now | TLS-terminated traffic arrives at productforge's Caddy as plain HTTP |

All commands above accept `PROFILE=home|remote` to choose the SSH path
(LAN mDNS vs Tailscale).

---

## 2. Deploy primitives

### 2.1 Ship a container — `scripts/deploy.sh <project-dir>`

`docker save | ssh | docker load`, scp's the compose file, runs
`docker compose up -d --remove-orphans` on the Pi.

Modes:
- **Single image:** `deploy.sh <image:tag> <compose-dir>`
- **Monorepo:** `deploy.sh <project-dir>` — auto-builds every service in
  `docker-compose.yml` that has a `build:` context and ships them all.

### 2.2 Ship a static site — `scripts/deploy-site.sh <site> <local-dir>`

Rsyncs `<local-dir>/` to `/mnt/ssd/sites/<site>/` on the Pi. The first run
allocates the slot; subsequent runs are incremental (`rsync --delete`).
Output includes the Caddy labels-only YAML snippet you paste into your
tenant compose so the site becomes routable.

---

## 3. Routing model

```
internet ─► Cloudflare edge (TLS) ─► cloudflared (Pi systemd)
                                   │   plain HTTP
                                   ▼
                                 caddy (caddy-docker-proxy)
                                   │   reads labels from any container
                                   │   on the "web" docker network
                  ┌────────────────┼────────────────┐
                  ▼                ▼                ▼
              your app:4000   labels-only      another tenant
              (containerized)   container       (containerized
                                ─► /sites/...    or static)
                                  static slot
```

**TLS terminates at the Cloudflare edge.** Your container speaks plain
HTTP inside the Pi. Forward `X-Forwarded-Proto` is set by Cloudflare so
your app's `force_ssl`/HSTS still works.

### 3.1 Declaring routes

Every container that wants traffic must:

1. Join the `web` external Docker network.
2. Carry Caddy labels.

Single-hostname app:

```yaml
labels:
  caddy: http://myapp.example.com
  caddy.reverse_proxy: "{{upstreams 4000}}"
```

Multiple hostnames (e.g. `dashboard.example.com` + wildcard
`*.example.com`):

```yaml
labels:
  caddy_0: http://dashboard.example.com
  caddy_0.reverse_proxy: "{{upstreams 4000}}"
  caddy_1: http://*.example.com
  caddy_1.reverse_proxy: "{{upstreams 4000}}"
```

The numeric suffix (`caddy_0`, `caddy_1`, …) groups labels per site block.

### 3.2 Serving a static slot

A "labels-only" container carries the routing for static files. It runs
`sleep infinity` and exists only to publish labels:

```yaml
my-landing-labels:
  image: busybox
  command: sleep infinity
  restart: unless-stopped
  networks: [web]
  labels:
    caddy: http://example.com
    caddy.root: "* /sites/my-landing"
    caddy.file_server:
```

`deploy-site.sh` prints this exact snippet (with your slot name filled
in) on first run.

### 3.3 Public hostnames in Cloudflare

For each hostname you want reachable from the internet, add a public
hostname in the Cloudflare Zero Trust dashboard:

- **Subdomain:** e.g. `dashboard`
- **Domain:** the tenant's domain (must be in a CF zone)
- **Service:** `http://localhost:80` (productforge Caddy's published port)

Wildcards are supported (`*` as subdomain). For app domains that aren't
already CF zones, add the zone first.

---

## 4. Tenant requirements

Your service must:

- Build for `linux/arm64` (RP5 is ARM). Build on the Pi or use
  `docker buildx --platform linux/arm64` from your laptop.
- **Speak plain HTTP**, not HTTPS. Cloudflare terminates TLS.
- **Preserve no assumptions about the Host header.** Caddy passes
  `Host` through unchanged — *your app must accept whatever hostname
  reached the edge.* If your app dispatches on `Host` (e.g. for
  subdomain routing), verify with
  `curl -H "Host: <ns>.example.com" http://localhost:80` on the Pi.
- Join `networks: [web]` (and `internal` if it needs `postgres`,
  `redis`, `redis-durable`).
- Declare its routes via Caddy labels (Section 3.1).
- Connect to shared services by container name: `postgres`, `redis`,
  `redis-durable`.
- Set `X-Forwarded-Proto` trust where relevant (Phoenix:
  `force_ssl: [rewrite_on: [:x_forwarded_proto]]`).

You **must not**:

- Publish ports to the host (only productforge's core stack publishes 80/443).
- Bind volumes outside `/mnt/ssd/stacks/<your-app>/` without coordinating.
- Connect to Postgres or Redis with credentials other than those from
  `provision-app.sh`.

---

## 5. Database lifecycle

### 5.1 Provision (first time)

```bash
./scripts/provision-app.sh delve
```

Creates database `delve`, role `delve` with a random 32-hex-char
password, grants all on the DB. Re-running rotates the password (role
already exists → `ALTER USER`); the database is preserved.

### 5.2 Reset (drop + recreate, fresh state)

```bash
./scripts/reset-app-db.sh delve
```

For pre-public iteration when you'd rather not chase migrations.
Behaviour:

1. Confirms by asking you to type the app name back.
2. Terminates every active connection to `<app>`.
3. `DROP DATABASE IF EXISTS <app>; DROP USER IF EXISTS <app>;`
4. Re-runs `provision-app.sh <app>` to recreate fresh.
5. Prints a new `DATABASE_URL` (with a new password).

Update your tenant `.env` with the new password, then re-deploy.

Flags:
- `--yes` skips the typed confirmation (for scripted resets).

### 5.3 Backup

```bash
./scripts/backup-db.sh           # all databases
./scripts/backup-db.sh delve     # just one
```

Writes gzipped `pg_dump` output to `/mnt/ssd/backups/` on the Pi. No
cron is wired by default — schedule by hand if you need it.

---

## 6. Tenant compose template

See [`tenant-compose.example.yml`](./tenant-compose.example.yml) for the
canonical annotated example: an app container with subdomain +
wildcard Caddy labels, a labels-only container that publishes a static
apex landing, and the right network membership.

---

## 7. Constraints and what productforge does *not* do

- Single Pi, single tenant pool. No quotas, no autoscaling, no isolation
  beyond Postgres role privileges and Docker networks.
- TLS is provided by Cloudflare. No Let's Encrypt/DNS-01 on the Pi.
- No CI/CD wiring — you run `deploy.sh` from your laptop (or wire it
  into your own CI later).
- No log shipping — `docker compose logs <service>` on the Pi.
- Hostname registration with Cloudflare is manual today.
- Postgres version: **16**. If your app needs 17+ features, raise it
  before planning.

---

## 8. Quick reference for a tenant deploy plan

A new tenant's Phase-N-Deploy planner runs through this list:

1. `./scripts/provision-app.sh <app>` → capture `DATABASE_URL`.
2. Write `deploy/docker-compose.yml` in the tenant repo. Tenant
   container joins `web` + `internal`, declares Caddy labels for its
   hostnames, reads `DATABASE_URL` from `.env`.
3. (If apex / static site needed) `./scripts/deploy-site.sh <site>
   <local-dir>` → paste the printed labels-only snippet into the tenant
   compose.
4. Register Cloudflare public hostnames for each public domain →
   `http://localhost:80`.
5. `./scripts/deploy.sh <tenant-deploy-dir>` from your laptop.
6. Smoke-test (curl each hostname, confirm Host-header dispatch if your
   app uses one).

That is the contract.
