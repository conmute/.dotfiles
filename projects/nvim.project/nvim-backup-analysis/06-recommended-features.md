# Recommended Features to Consider Restoring

## High Priority (Productivity)

### 1. Harpoon
**Source:** nvim.bak.2025.10
**Why:** Quick file marking and navigation - very useful for projects with few key files you frequently switch between

```lua
-- From: nvim.bak.2025.10/lua/plugins/*.lua
{
  "ThePrimeagen/harpoon",
  dependencies = { "nvim-lua/plenary.nvim" },
  -- Add configuration here
}
```

### 2. Telescope File Browser
**Source:** nvim.bak, nvim.bak.2, nvim.bak.2025.10
**Why:** Better file exploration than default, integrated with Telescope workflow

Already partially in current setup at `nvim/lua/config/editor.lua`

### 3. Incremental Rename (inc-rename.nvim)
**Source:** nvim.bak, nvim.bak.2025.10
**Why:** More reliable LSP rename with live preview

```lua
{
  "smjonas/inc-rename.nvim",
  keys = {
    {
      "<leader>rn",
      function()
        return ":IncRename " .. vim.fn.expand("<cword>")
      end,
      expr = true,
      desc = "Incremental rename",
    },
  },
}
```

### 4. Vim Fugitive
**Source:** nvim.bak.2025.10
**Why:** Powerful Git integration with :Git commands and workflows

```lua
{ "tpope/vim-fugitive" }
```

## Medium Priority (Code Quality)

### 5. Refactoring.nvim
**Source:** nvim.bak, nvim.bak.2025.10
**Why:** Automated refactoring operations

```lua
{
  "ThePrimeagen/refactoring.nvim",
  keys = {
    {
      "<leader>r",
      function()
        require("refactoring").select_refactor()
      end,
      mode = "v",
      noremap = true,
      silent = true,
      expr = false,
    },
  },
}
```

### 6. Hardtime.nvim
**Source:** nvim.bak.2025.10
**Why:** Learning tool to improve Vim usage and break bad habits

```lua
{
  "m4xshen/hardtime.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  opts = {},
}
```

### 7. Precognition.nvim
**Source:** nvim.bak.2025.10
**Why:** Visual hints for Vim motions - great learning tool

```lua
{
  "tris203/precognition.nvim",
  opts = {},
}
```

## Lower Priority (UI/UX)

### 8. Incline.nvim
**Source:** nvim.bak
**Why:** Floating window file indicator

### 9. Tailwindcss Colorizer
**Source:** nvim.bak, nvim.bak.2
**Why:** Color preview in completions for Tailwind classes

```lua
{ "roobert/tailwindcss-colorizer-cmp.nvim" }
```

### 10. Nvim Colorizer
**Source:** nvim.bak.2025.10
**Why:** Real-time color code highlighting (#hex, rgb, etc.)

```lua
{
  "norcalli/nvim-colorizer.lua",
  config = function()
    require("colorizer").setup()
  end,
}
```

## Special Features

### 11. Obsidian.nvim Integration
**Source:** nvim.bak.2025.10
**Why:** Full knowledge management system with vault integration

See `04-nvim-bak-2025-10.md` for complete configuration and workflow system.

### 12. Custom Craftzdog Utilities
**Source:** nvim.bak
**Why:** HSL color conversion, discipline module, enhanced keymaps

See `07-custom-utilities.md` for implementation details.

## Not Recommended (Already Better Alternatives)

- **nvim-cmp** → Current setup uses blink.cmp (better performance)
- **neo-tree** → Current setup has other file navigation
- **LuaSnip** → Current setup works without snippets
- **nvim-notify** → LazyVim handles notifications well
