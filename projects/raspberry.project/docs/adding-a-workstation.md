# Adding a Workstation

How to set up another computer to manage Productforge (SSH, deploy, provision,
backup). This is a **client-only** setup: the Pi is already provisioned, nothing
on it gets reinstalled.

> Do **not** run `./setup.sh` from a new workstation. It is first-time
> provisioning and overwrites the core stack `.env` on the Pi with whatever is
> in that machine's `setup.conf`.

## Prerequisites

- An existing workstation that can already SSH into the Pi (needed to authorize
  the new key, because the Pi accepts SSH keys only, no passwords).
- This repo cloned on the new machine.

## Step 1: Generate an SSH key on the new machine

One key per machine, so each one can be revoked on its own.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_productforge -C "productforge-<machine-name>"
cat ~/.ssh/id_productforge.pub
```

Naming it `id_productforge` matches the default `SSH_KEY` in `setup.conf`.

## Step 2: Authorize the key on the Pi

> Run this on the **existing** workstation, not the new one. The new machine
> can't reach the Pi yet: it has no `setup.conf` (Step 3) and the Pi doesn't
> know its key. Running it there fails with `setup.conf not found`.

Send the new public key to the existing workstation (it's public, so chat or
email is fine), then run there:

```bash
./scripts/ssh.sh "echo '<paste new pubkey>' >> ~/.ssh/authorized_keys"
```

`authorized_keys` is not managed by Ansible, so playbook runs won't remove it.

To revoke a machine later, delete its line (find it by the `-C` comment):

```bash
./scripts/ssh.sh "sed -i '/productforge-<machine-name>/d' ~/.ssh/authorized_keys"
```

## Step 3: Copy the gitignored config

These are not in git. Transfer them securely from the existing workstation
(AirDrop, password manager, `scp` over Tailscale), and never commit them.

| File | Contents | Needed for |
|------|----------|------------|
| `setup.conf` | `PI_HOST`, `PI_USER`, `SSH_KEY` + secrets (Postgres admin password, Tailscale/Cloudflare tokens) | Everything |
| `setup.conf.home` | `PI_HOST=productforge.local` | LAN access |
| `setup.conf.remote` | `PI_HOST=productforge.<tailnet>.ts.net` | Tailscale access |

### Example: copy over Tailscale with `scp`

If both machines are Macs on the same tailnet, turn on Remote Login on the
**new** machine (System Settings → General → Sharing → Remote Login, or):

```bash
sudo systemsetup -setremotelogin on
```

Find its Tailscale name with `tailscale status`, then from the **existing**
workstation (it asks for the new machine's login password):

```bash
cd ~/.ghq/github.com/conmute/.dotfiles/projects/raspberry.project && \
  scp setup.conf setup.conf.home setup.conf.remote \
  <user>@<new-machine>:~/.ghq/github.com/conmute/.dotfiles/projects/raspberry.project/
```

For example `ross@roman-koss-mac-2019`. Turn Remote Login back off afterwards
if you don't need it.

For SSH-only use, `setup.conf` just needs `PI_HOST`, `PI_USER` and `SSH_KEY`.
The secrets are only needed for `setup.sh` and the DB scripts.

## Step 4: Install tooling

**Ansible** is only needed to run playbooks (`setup.sh`, `ansible-playbook`).
`ssh.sh`, `deploy.sh`, `deploy-site.sh`, `provision-app.sh` and `backup-db.sh`
need nothing but `ssh`.

```bash
./install.sh            # macOS and Linux; re-run safe
./install.sh --upgrade  # upgrade Ansible later
```

It installs [uv](https://docs.astral.sh/uv/) (official installer) if missing,
then `uv tool install --python 3.13 ansible-core --with ansible` into `~/.local/bin`, then
the collections from `requirements.yml`. uv uses its own prebuilt Python and
wheels, so nothing compiles. Open a new shell afterwards so `~/.local/bin` is
on `PATH`.

> **Python is pinned to 3.13** (override with `ANSIBLE_PYTHON=3.12 ./install.sh`).
> Unpinned, uv picks the newest Python it can find. ansible-core 2.21 crashes on
> 3.15 with `module 'dataclasses' has no attribute '_is_type'`, and there are no
> prebuilt `cryptography` wheels for it, so that also compiles. Re-running
> `./install.sh` detects a broken install and reinstalls it.

> **Don't use `brew install ansible` on older macOS** (e.g. a 2019 Mac).
> Without prebuilt bottles, Homebrew compiles `cryptography` → `rust` →
> `llvm` → `z3` from source, which takes hours. Same for `brew install uv`.
> Clean up a half-finished brew build with `brew autoremove && brew cleanup`.

> **macOS hint:** on a fresh Mac, `git` (and Homebrew, if you use it) need
> the Xcode Command Line Tools. If you hit an `xcrun`/developer tools error,
> run `xcode-select --install`, finish the installer dialog, then retry.

Check it can reach the Pi (after Steps 2–3):

```bash
source scripts/_load-profile.sh   # exports PI_HOST/PI_USER/SSH_KEY for the inventory
ansible -i inventory/hosts.yml productforge -m ping
```

**Tailscale** (needed for the `remote` profile): install it and log into the
same tailnet as the Pi.

## Step 5: Verify

```bash
./scripts/ssh.sh hostname                 # home profile: LAN / mDNS
PROFILE=remote ./scripts/ssh.sh hostname  # remote profile: Tailscale
```

`hostname` here is not a placeholder, it's the literal command run on the Pi.
The host to connect to comes from `PI_HOST` in the active profile. Expected
output:

```console
$ ./scripts/ssh.sh hostname
==> profile: home  (ross@productforge.local)
productforge

$ PROFILE=remote ./scripts/ssh.sh hostname
==> profile: remote  (ross@productforge.taile94c17.ts.net)
productforge
```

Any other command works the same way, e.g. `./scripts/ssh.sh uptime`, or
`./scripts/ssh.sh` with no arguments for an interactive shell.

Both should print `productforge`. After that, `deploy.sh`, `deploy-site.sh`,
`provision-app.sh` and `backup-db.sh` work from this machine too.

## Troubleshooting

### Home profile: connection refused or times out

UFW only allows SSH from `192.168.0.0/24` (see `roles/security`). If the
machine is on a different subnet or network, use `PROFILE=remote`.

### Remote profile: `Could not resolve hostname ...ts.net`

Tailscale isn't running on **this** machine. Start it (`tailscale up` or the
menu bar app) and check with `tailscale status`.

### Remote profile: `Operation timed out`, Pi shows `offline` in `tailscale status`

The Pi's Tailscale node key most likely expired (180 days by default). Fix it
over the LAN:

```bash
./scripts/ssh.sh 'tailscale status'   # "Logged out." confirms it
./scripts/ssh.sh -t 'sudo tailscale up --ssh --accept-routes'
```

Open the printed login URL in a browser and approve the device. The command
finishes with `Success.` and the Pi keeps its old name and `100.x` address.

If you're not on the LAN, you can't fix it remotely. To keep this from
happening, in the Tailscale admin console go to **Machines → productforge →
⋯ → Disable key expiry**.

If the console shows a stale offline `productforge` next to a new
`productforge-1`, delete the old one and rename the new one, or update
`setup.conf.remote`.
