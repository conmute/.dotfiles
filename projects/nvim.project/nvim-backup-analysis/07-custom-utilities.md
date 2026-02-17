# Custom Utilities Worth Preserving

## From nvim.bak (Craftzdog Setup)

### 1. Discipline Module
**Location:** `nvim.bak/lua/craftzdog/discipline.lua`
**Purpose:** Prevent bad Vim habits by limiting use of certain keys

```lua
-- Usage in keymaps.lua:
require("craftzdog.discipline").cowboy()
```

This utility discourages using hjkl repetitively and encourages proper Vim motions.

### 2. HSL Color Utilities
**Location:** `nvim.bak/lua/craftzdog/hsl.lua`
**Purpose:** Convert hex colors to HSL format

**Keymap:**
```lua
vim.keymap.set("n", "<leader>r", function()
  require("craftzdog.hsl").replaceHexWithHSL()
end, { desc = "Replace hex with HSL" })
```

Useful for working with CSS/Tailwind and converting color formats.

### 3. LSP Inlay Hints Toggle
**Location:** `nvim.bak/lua/craftzdog/lsp.lua`
**Purpose:** Toggle LSP inlay hints on/off

**Keymap:**
```lua
vim.keymap.set("n", "<leader>i", function()
  require("craftzdog.lsp").toggleInlayHints()
end, { desc = "Toggle inlay hints" })
```

### 4. Enhanced Keymap Patterns

**Register-Aware Paste Operations:**
```lua
-- Paste from register 0 (yank register) instead of default
vim.keymap.set("n", "p", '"0p')
vim.keymap.set("n", "P", '"0P')
vim.keymap.set("v", "p", '"0p')
vim.keymap.set("n", "gp", '"0p')
vim.keymap.set("n", "gP", '"0P')
```

**Delete Without Polluting Registers:**
```lua
-- Delete operations go to black hole register
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "c", '"_c')
vim.keymap.set("n", "C", '"_C')
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("n", "D", '"_D')
```

**Window Navigation with s+hjkl:**
```lua
vim.keymap.set("n", "sh", "<C-w>h")
vim.keymap.set("n", "sk", "<C-w>k")
vim.keymap.set("n", "sj", "<C-w>j")
vim.keymap.set("n", "sl", "<C-w>l")
```

**Custom Increment/Decrement:**
```lua
vim.keymap.set("n", "+", "<C-a>")
vim.keymap.set("n", "-", "<C-x>")
```

## From nvim.bak.2025.10 (Obsidian Setup)

### 5. Obsidian Workflow System
**Location:** `nvim.bak.2025.10/lua/config/workflows.lua`
**Purpose:** Complete knowledge management integration

**Key Features:**
- Navigate to vault: `<leader>oo`
- Create note from template: `<leader>on`
- Format note title: `<leader>ot`
- Find files in notes: `<leader>of`
- Search notes: `<leader>or`
- Move to zettelkasten: `<leader>ok`
- Delete note: `<leader>odd`

**Smart Directory Moving:**
```lua
-- Detects if parent directory matches file name
-- Moves entire directory structure appropriately
function()
  local current_file = vim.fn.expand("%:t:r")
  local parent_dir = vim.fn.expand("%:p:h:t")

  if current_file == parent_dir then
    -- Move entire directory
  else
    -- Move just the file
  end
end
```

### 6. Enhanced Options Configuration

**From nvim.bak.2025.10:**
```lua
vim.g.maplocalleader = ";"  -- Local leader key
vim.opt.showmode = false    -- Hide mode indicator
vim.opt.cmdheight = 0       -- Hide command line
vim.opt.laststatus = 0      -- Hide status line
vim.opt.mouse = ""          -- Disable mouse
vim.opt.foldenable = false  -- Disable folding
```

**Fish Shell Compatibility:**
```lua
if vim.fn.executable("fish") == 1 then
  vim.opt.shell = "fish"
else
  vim.opt.shell = "/bin/sh"
end
```

## Implementation Guide

### To Use Craftzdog Utilities:

1. Create directory structure:
```bash
mkdir -p nvim/lua/craftzdog
```

2. Copy utility files:
```bash
cp nvim.bak/lua/craftzdog/*.lua nvim/lua/craftzdog/
```

3. Add keymaps to `nvim/lua/config/keymaps.lua`

### To Use Obsidian Workflow:

1. Copy workflow configuration:
```bash
cp nvim.bak.2025.10/lua/config/workflows.lua nvim/lua/config/
```

2. Copy obsidian plugin config:
```bash
cp nvim.bak.2025.10/lua/plugins/obsidian.lua nvim/lua/plugins/
```

3. Update vault path in obsidian.lua:
```lua
workspaces = {
  {
    name = "GTD",
    path = "/path/to/your/obsidian/vault",
  },
}
```

4. Source workflows in your init or config file:
```lua
require("config.workflows")
```
