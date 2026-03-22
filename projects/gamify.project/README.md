# gamify.project — Hollow Knight Workflow Sounds

> Replace gaming dopamine with coding dopamine.
> Every action gives feedback, just like farming minions on the wave.

All sounds are from **Hollow Knight** audio dump (`~/Downloads/Hollow Knight Audio Files/`).

## Install

```bash
# From dotfiles root
./scripts/bindprojects.sh
```

Creates:
- `~/bin/hk-action` → 3-layer random combat sound script
- `~/.local/share/gamify/sounds/` → sound files symlink

## Structure

```
gamify.project/
├── bind.sh              # symlinks bin + sounds into place
├── bin/
│   └── hk-action        # 3-layer random combat sound script
└── sounds/
    ├── app-start.wav        # claude launch (geo deplete)
    ├── attention-{1-4}.wav  # Hornet yells (random rotation)
    ├── commit.wav           # git commit (miner hum, 13s)
    ├── message-sent.wav     # user sends message (geo deplete)
    ├── nvim-start.wav       # nvim launch (geo deplete)
    ├── work-done-{1-4}.wav  # Grub King cheers (random rotation)
    └── user-action/         # 3-layer combat mix for hk-action
        ├── voice/           # shaw, adido, garama, flourish
        ├── movement/        # dash, jump, needle-throw, hero-dash
        └── hit/             # sword, parry, needle-catch, enemy-damage, hero-parry
```

## hk-action

Picks one random file from each layer (voice + movement + hit) and plays all 3 simultaneously.

```bash
hk-action
```

4 voices × 4 movements × 5 hits = **80 unique combos**.
Drop any `.wav` into a layer folder to expand the pool.

## Sound Map

| Event | Sound | Duration |
|-------|-------|----------|
| Shell command (fish) | `hk-action` 3-layer combat mix | 0.2-1.1s |
| `claude` launched | Geo deplete countdown (`app-start.wav`) | 1.17s |
| User sends message in Claude | Geo deplete countdown (`message-sent.wav`) | 1.17s |
| Claude asks a question | Hornet yell random (`attention-{1-4}.wav`) | 0.8-1.3s |
| Claude finishes work | Grub King cheer random (`work-done-{1-4}.wav`) | 0.9-1.7s |
| Claude notification | Hornet yell random | 0.8-1.3s |
| `git commit` | Miner's hum (`commit.wav`) | 13s (looped) |
| `nvim` opened | Geo deplete countdown (`nvim-start.wav`) | 1.17s |
| tmux window/pane switch | `hk-action` 3-layer combat mix | 0.2-1.1s |

## Hook Locations

### Claude Code (`~/.claude/settings.json` + `~/.caleb/settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [{"matcher": "AskUserQuestion", "hooks": [{"type": "command", "command": "afplay ~/.local/share/gamify/sounds/attention-$(jot -r 1 1 4).wav &"}]}],
    "UserPromptSubmit": [{"matcher": "", "hooks": [{"type": "command", "command": "afplay ~/.local/share/gamify/sounds/message-sent.wav &"}]}],
    "Stop": [{"matcher": "", "hooks": [{"type": "command", "command": "afplay ~/.local/share/gamify/sounds/work-done-$(jot -r 1 1 4).wav &"}]}],
    "Notification": [{"matcher": "", "hooks": [{"type": "command", "command": "afplay ~/.local/share/gamify/sounds/attention-$(jot -r 1 1 4).wav &"}]}]
  }
}
```

Random rotation: `jot -r 1 1 4` (macOS built-in).

### Git (`~/.git-hooks/post-commit`)

```sh
#!/bin/sh
afplay ~/.local/share/gamify/sounds/commit.wav &
```

Global hooks path: `git config --global core.hooksPath ~/.git-hooks`

### Fish (`~/.config/fish/config.fish`)

```fish
# Gamified claude — play geo deplete on launch
function claude --wraps=claude
    afplay ~/.local/share/gamify/sounds/app-start.wav &
    command claude $argv
end

# Gamified shell — random HK combat sound on every command (interactive only)
function __gamify_preexec --on-event fish_preexec
    hk-action
end
```

### Tmux (`~/.tmux.conf`)

```tmux
set-hook -g window-linked       'run-shell "~/bin/hk-action"'
set-hook -g after-select-window 'run-shell "~/bin/hk-action"'
set-hook -g after-select-pane   'run-shell "~/bin/hk-action"'
```

### Neovim (`autocmds.lua`)

```lua
vim.defer_fn(function()
  vim.fn.jobstart({ "afplay", vim.fn.expand("~/.local/share/gamify/sounds/nvim-start.wav") })
end, 100)
```

## Replacing Sounds

```bash
# Search HK audio dump by name
ls ~/Downloads/Hollow\ Knight\ Audio\ Files/ | grep -i "keyword"

# Check duration
ffprobe -v error -show_entries format=duration -of csv=p=0 "path/to/file.wav"

# Copy into dotfiles (persists across machines)
cp ~/Downloads/Hollow\ Knight\ Audio\ Files/new_sound.wav sounds/target.wav

# Trim + fade out
ffmpeg -y -i source.wav -t 1.0 -af "afade=t=out:st=0.7:d=0.3" -ar 44100 target.wav

# Loop (for longer sounds like commit)
ffmpeg -y -stream_loop 1 -i source.wav -t 13 -af "afade=t=out:st=11:d=2.0" -ar 44100 target.wav
```

## Rotation Details

**Attention** (Hornet yells):
1. `Hornet_Fight_Yell_04.wav` — sharp combat yell
2. `Hornet_Fight_Yell_06.wav` — longer intense yell
3. `Hornet_Final_Boss_yell_02.wav` — boss yell
4. `Hornet_Greenpath_01.wav` — iconic first encounter

**Work done** (Grub King):
1. `Grub_king_cheer_01.wav` — big cheer
2. `Grub_king_cheer_02.wav` — short cheer
3. `Grub_king_cheer_03.wav` — mid cheer
4. `Grub_King_wave.wav` — royal wave

**Combat layers** (`user-action/`):

| Layer | Folder | Files |
|-------|--------|-------|
| Voice | `voice/` | shaw, adido, garama, flourish |
| Movement | `movement/` | dash, jump, needle-throw, hero-dash |
| Hit | `hit/` | sword, parry, needle-catch, enemy-damage, hero-parry |

## Future Ideas
- Sound for test suite passing (green) vs failing (red)
- Sound for PR merged
- Sound for Jira ticket moved to Done
- Different sounds per project (Podium vs DecideWell)
- Volume/intensity scales with streak days
