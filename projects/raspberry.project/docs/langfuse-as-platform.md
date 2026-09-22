# Plan: Langfuse as a productforge platform resource

**Status:** plan-only — no code yet.
**Goal:** elevate Langfuse from per-tenant container to a shared platform
service, joining Postgres and Redis in productforge's resource catalog.

## 1. Why

Today each app that wants LLM observability would have to run its own
Langfuse container, manage its own NEXTAUTH secrets, and own its own
Langfuse URL. That duplicates infra and fragments traces across tenants.

Langfuse natively supports **multiple projects in one install** with
per-project API keys. A single Langfuse on productforge can serve every
tenant's AI apps cleanly, with project-level isolation.

## 2. End state

### What a tenant sees

```
$ ./scripts/provision-langfuse-project.sh delve
==> profile: home (ross@productforge.local)
==> Langfuse project provisioning for: delve

  Open: http://langfuse.productforge.local
  Create a project named: delve
  Copy the public+secret keys it gives you, then add to your .env:

LANGFUSE_HOST=http://langfuse.productforge.local
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
```

(v1 is "instruct the operator"; project creation in the Langfuse UI.
v2 can hit Langfuse's admin API once we've used it enough to know what
we want.)

### What the operator sees

- A Langfuse container in the productforge core stack alongside caddy /
  postgres / redis, started by the same Ansible flow.
- One-time UI bootstrap on first launch: create the admin user + org.
- Backups already covered by `backup-db.sh` (Langfuse data lives in
  shared Postgres under DB `langfuse`).

### What PLATFORM.md gains

A row in §1 (resource catalog):

| Resource | Provisioned by | Returns |
|---|---|---|
| Langfuse project + API keys | `scripts/provision-langfuse-project.sh <app>` | `LANGFUSE_HOST`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY` |

And a new §5.4 documenting the one-time admin bootstrap and project
isolation guarantees.

## 3. Architecture

```
internet                  no public exposure
                          (intranet-only resource)
                                  │
                                  ▼
LAN / Tailscale ─► langfuse.<resolution>:443 ─► caddy ─► langfuse:3000
                                                          │
                                                          ▼
                                                   shared postgres
                                                   (DB: langfuse)
```

Resource decisions locked with the operator:

- **Storage:** shared Postgres 16. Langfuse creates its own DB on first
  start; we pre-provision `langfuse` DB via the existing
  `provision-app.sh` flow during setup (one-time).
- **URL space:** intranet-only — no Cloudflare Tunnel hostname.
  Reachable from LAN and from Tailscale; **not** public.
- **Auth:** Langfuse's built-in NextAuth. We bootstrap one admin user
  manually. Project-level isolation prevents tenants from seeing each
  other's traces.

## 4. URL strategy — the DNS wrinkle to resolve

The operator's preference is `langfuse.<productforge-host>`. There's a
real DNS issue worth surfacing now:

- **mDNS** (`.local`) only handles single-label hostnames. Subdomains
  like `langfuse.productforge.local` do **not** resolve via Bonjour
  without help.
- **Tailscale Magic DNS** resolves machine names (e.g.
  `productforge.taile94c17.ts.net`) but doesn't give you CNAMEs/wildcards
  off them.

Three options, pick during execution (not now):

### Option A: per-device `/etc/hosts` entries (lowest infra)

Add `<pi-lan-ip> langfuse.productforge.local` to `/etc/hosts` on every
device that needs UI access. Same for the Tailscale IP and the
ts.net hostname. Caddy then routes by Host header normally.

- Pro: zero new infra; Caddy config is clean subdomain routing.
- Con: must repeat on every device (laptop, phone, ipad). Tedious.

### Option B: path-based URL (lowest friction)

Route `productforge.local/_langfuse/` and
`productforge.taile94c17.ts.net/_langfuse/` to Langfuse. No DNS
gymnastics; Caddy strips the prefix.

- Pro: works out of the box on every device.
- Con: Langfuse must be configured to live at a sub-path (it supports
  this via `NEXTAUTH_URL` + `BASE_PATH`). URL is uglier.

### Option C: dnsmasq on the Pi + DHCP advertisement (cleanest UX)

Run a tiny `dnsmasq` container that resolves `*.productforge.local` to
the Pi's LAN IP. Devices that use the home router's DHCP can be told
to use the Pi as their DNS server (or just point at it manually).

- Pro: any subdomain of `.productforge.local` works on the LAN.
- Con: more moving parts; Tailscale side still needs its own answer
  (Tailscale Split DNS pointing `*.productforge.taile94c17.ts.net` at
  a custom resolver, which is a separate setup).

**Default recommendation if no preference:** Option B for v1
(zero-friction), revisit if we hate the URL.

## 5. Changes required to deliver this

### 5.1 Productforge core stack

`configs/opt/productforge/stacks/core/docker-compose.yml` gains a
`langfuse` service:

```yaml
langfuse:
  image: langfuse/langfuse:latest
  restart: unless-stopped
  depends_on:
    postgres:
      condition: service_healthy
  environment:
    DATABASE_URL: postgresql://langfuse:${LANGFUSE_DB_PASSWORD}@postgres:5432/langfuse
    NEXTAUTH_SECRET: ${LANGFUSE_NEXTAUTH_SECRET}
    SALT: ${LANGFUSE_SALT}
    NEXTAUTH_URL: ${LANGFUSE_URL}          # depends on URL strategy choice
    TELEMETRY_ENABLED: "false"
    LANGFUSE_ENABLE_EXPERIMENTAL_FEATURES: "false"
  networks: [web, internal]
  labels:
    caddy: <hostname-or-path-prefix>       # depends on URL strategy choice
    caddy.reverse_proxy: "{{upstreams 3000}}"
```

Exact label depends on §4 decision.

### 5.2 setup.conf

Add four bootstrap values:

```bash
# Langfuse (productforge platform resource)
LANGFUSE_DB_PASSWORD=<set by setup.sh via provision-app.sh>
LANGFUSE_NEXTAUTH_SECRET=<openssl rand -hex 32>
LANGFUSE_SALT=<openssl rand -hex 32>
LANGFUSE_URL=http://langfuse.productforge.local   # or path-based equivalent
```

Update `setup.conf.example` to match.

### 5.3 setup.sh

During initial setup, after core stack is up:

1. Run `provision-app.sh langfuse` to create the Postgres DB + role.
   Capture the password into `LANGFUSE_DB_PASSWORD` in setup.conf
   automatically (or instruct operator to copy it).
2. Generate `LANGFUSE_NEXTAUTH_SECRET` and `LANGFUSE_SALT` if not set
   (`openssl rand -hex 32`).
3. Bring up the Langfuse container.
4. Print a one-time message: "Visit <URL>/auth/sign-up to create the
   admin user, then create your first project."

### 5.4 New script: `scripts/provision-langfuse-project.sh <app>`

```bash
#!/bin/bash
# Instruct the operator to create a Langfuse project for <app>.
# v1: manual UI step. v2: API-driven.

source "$(dirname "$0")/_load-profile.sh"

APP="${1:?Usage: provision-langfuse-project.sh <appname>}"

# Validate name like provision-app.sh

echo "==> Langfuse project provisioning for: $APP"
echo ""
echo "  1. Open: $LANGFUSE_URL"
echo "  2. Sign in (create admin account on first run)"
echo "  3. Create a new project named: $APP"
echo "  4. Copy the public + secret keys"
echo ""
echo "Add these to your tenant's .env file:"
echo ""
echo "LANGFUSE_HOST=$LANGFUSE_URL"
echo "LANGFUSE_PUBLIC_KEY=pk-lf-..."
echo "LANGFUSE_SECRET_KEY=sk-lf-..."
echo ""
echo "(v2: this will be API-driven and return real keys directly.)"
```

`LANGFUSE_URL` comes from the profile loader (sourced from
`setup.conf`).

### 5.5 Ansible

`roles/stacks/tasks/main.yml` already templates the core compose.
Adding `langfuse:` to the compose template (5.1) is enough — Ansible
just `docker compose up -d`s the changed stack. No new role.

### 5.6 PLATFORM.md

Add the resource row in §1, a §5.4 documenting the manual project
flow + project-isolation note, and a §6.1-style mention in §7
("Langfuse is intranet-only; reachable on LAN/Tailscale, not public").

### 5.7 NOT changing

- No Cloudflare Tunnel hostname for Langfuse.
- No new role; reusing `roles/stacks`.
- No backup-specific work; `backup-db.sh` already covers the langfuse DB.

## 6. Bootstrap flow (one-time, operator)

```
1. Decide URL strategy (Option A/B/C from §4).
2. Update setup.conf with LANGFUSE_URL + secrets.
3. Re-run setup.sh — pre-provisions langfuse DB, brings up container.
4. Visit LANGFUSE_URL/auth/sign-up.
5. Create admin user (only the first signup becomes admin).
6. Create an organization.
7. (Per tenant) Run provision-langfuse-project.sh <app>; follow the
   on-screen UI steps.
```

After bootstrap, every new tenant onboarding just runs step 7.

## 7. Open questions to settle at execution time

1. **URL strategy** (§4) — A vs B vs C. Recommend B for first cut.
2. **Langfuse v2 vs v3** — v3 wants ClickHouse for trace storage at
   scale. v2 with Postgres is fine for prototype volume. Pick the v2
   image tag explicitly to avoid surprise upgrades.
3. **Disable open signups after admin is created** — Langfuse env var
   `AUTH_DISABLE_SIGNUP=true` (or similar; verify exact name). Otherwise
   anyone on LAN/Tailscale can register, which is fine for a single-user
   household but we should make the choice explicit.
4. **Telemetry** — set `TELEMETRY_ENABLED=false` so Langfuse doesn't
   phone home with anonymous usage data.

## 8. Deferred

- API-driven project provisioning (requires admin token management).
- ClickHouse storage for trace volume at scale.
- Public exposure via Cloudflare Tunnel + auth proxy.
- Cross-tenant cost dashboards.
- Retention policy / trace pruning automation.

## 9. Effort estimate

Once the URL decision is made: ~1–2 hours of focused work.

- Compose service: 15 min
- setup.sh DB pre-provision + secret gen: 30 min
- New script: 15 min
- PLATFORM.md update: 15 min
- Bootstrap dry-run + project test: 30 min
- Document the URL gotcha in adding-an-app.md or PLATFORM.md: 10 min
