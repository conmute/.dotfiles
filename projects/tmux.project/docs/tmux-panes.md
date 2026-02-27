# Tmux Session Recovery

How to persist, backup, and restore tmux sessions.

## Automatic Recovery (tmux-resurrect + continuum)

### How It Works

Two plugins handle this automatically:

- **tmux-resurrect** — saves/restores windows, panes, layouts, and working directories
- **tmux-continuum** — auto-saves resurrect state every 15 minutes

Current config (`.tmux.conf`):

```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'
```

### Keybindings

| Key            | Action                        |
|----------------|-------------------------------|
| `prefix + C-s` | Save sessions (manual)       |
| `prefix + C-r` | Restore sessions (manual)    |

> Prefix is `C-a` in this config.

### Where Resurrect Stores Data

Default path: `~/.tmux/resurrect/`

Files inside:
- `last` — symlink to the most recent save
- `tmux_resurrect_YYYYMMDDTHHMMSS.txt` — timestamped snapshots

To check the last save:

```sh
ls -la ~/.tmux/resurrect/last
cat ~/.tmux/resurrect/last
```

## Manual Snapshot (`~/.tmux-snapshot`)

A human-readable backup created with Claude Code. Useful when resurrect files are missing or corrupted.

Location: `~/.tmux-snapshot`

### Format

```
# tmux snapshot — 2026-02-23 18:35:58

## Session: <name>

### Window <n>: <window_name> (active)
    layout: <layout_string>
    pane 1: (active) <WxH> cmd=<command> dir=<path>
    pane 2: <WxH> cmd=<command> dir=<path>
```

### Emergency Restore from Snapshot

When resurrect fails and you need to rebuild sessions manually:

**1. Parse the snapshot and recreate sessions:**

```sh
# Create a session
tmux new-session -d -s "session_name" -c "/working/directory"

# Create additional windows
tmux new-window -t "session_name" -c "/working/directory"

# Split panes (horizontal |, vertical -)
tmux split-window -h -t "session_name:1" -c "/pane/directory"
tmux split-window -v -t "session_name:1" -c "/pane/directory"
```

**2. Apply saved layout string:**

```sh
# Use the exact layout string from the snapshot
tmux select-layout -t "session_name:1" "7c35,215x60,0,0{107x60,0,0,31,107x60,108,0,30}"
```

**3. Send commands to panes (e.g. start yazi, nvim):**

```sh
tmux send-keys -t "session_name:1.2" "yazi" Enter
tmux send-keys -t "session_name:1.1" "nvim" Enter
```

**4. Full restore script example:**

```sh
#!/usr/bin/env bash
# Emergency restore from ~/.tmux-snapshot
# Adapt this to your current snapshot contents

# --- Session: _dotfiles ---
tmux new-session -d -s "_dotfiles" -c "$HOME/.ghq/github.com/conmute/.dotfiles"
tmux split-window -h -t "_dotfiles:1" -c "$HOME/.ghq/github.com/conmute/.dotfiles"
tmux select-layout -t "_dotfiles:1" "7347,215x60,0,0{107x60,0,0,0,107x60,108,0,44}"

# --- Session: decidewell ---
tmux new-session -d -s "decidewell" -c "$HOME/.ghq/github.com/conmute/decidewell/apps/mobile"
tmux split-window -v -t "decidewell:1" -c "$HOME/.ghq/github.com/conmute/decidewell/apps/api"
tmux split-window -v -t "decidewell:1" -c "$HOME/.ghq/github.com/conmute/decidewell/packages/db"
tmux split-window -h -t "decidewell:1" -c "$HOME/.ghq/github.com/conmute/decidewell"
tmux select-layout -t "decidewell:1" "329a,215x58,0,0{107x58,0,0[107x29,0,0,4,107x13,0,30,8,107x14,0,44,9],107x58,108,0,7}"
tmux new-window -t "decidewell" -c "$HOME/.ghq/github.com/conmute/decidewell"

# Attach
tmux attach-session -t "_dotfiles"
```

### Tips

- Layout strings are exact — they encode pane sizes and positions. Apply them with `select-layout` after creating all panes in the window.
- Create all panes in a window **before** applying the layout, otherwise tmux rejects the layout string (pane count must match).
- The snapshot `cmd=` field tells you what was running. For shells (`fish`, `zsh`, `bash`) no action needed — they start by default. For tools (`yazi`, `nvim`, `node`), send the command with `send-keys`.
- `select-layout` may fail if terminal size differs from when the snapshot was taken. Resize your terminal to match (check the `WxH` in the layout) or skip and arrange manually.
