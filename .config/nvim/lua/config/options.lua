-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- copied from .config/nvim/lua/config/options.lu
-- url: https://github.com/JazzyGrim/dotfiles/blob/master/.config/nvim/lua/config/options.lua

vim.g.mapleader = " "
vim.g.maplocalleader = ";"

vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

if os.getenv("SHELL") == "/usr/local/bin/fish" or vim.opt.shell == "/usr/local/bin/fish" then
  vim.opt.shell = "/bin/sh"
else
  -- Else default to the system current shell.
  vim.opt.shell = os.getenv("SHELL")
end
vim.opt.number = true

vim.opt.title = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.hlsearch = true
vim.opt.backup = false
vim.opt.showcmd = true
vim.opt.showmode = false
vim.opt.cmdheight = 0
vim.opt.laststatus = 0
vim.opt.expandtab = true
vim.opt.scrolloff = 10
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smarttab = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.wrap = false
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "cursor"
vim.opt.mouse = ""
-- Disabling annoying error, and I dont use folding…
vim.opt.foldenable = false
-- Add asterisks in block comments
vim.opt.formatoptions:append({ "r" })
