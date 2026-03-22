-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Welcome message on startup
local function show_welcome()
  local argc = vim.fn.argc()
  local argv = vim.fn.argv()

  -- Show welcome if no args, or if the only arg is current directory
  if argc == 0 or (argc == 1 and (argv[1] == "." or argv[1] == vim.fn.getcwd())) then
    vim.notify("Welcome back! 󰚄", vim.log.levels.INFO, { title = "LazyVim" })
  end
end

-- Since this file loads on VeryLazy (after UIEnter), just show the notification and play sound
vim.defer_fn(function()
  show_welcome()
  vim.fn.jobstart({
    "gamify",
    "play",
    "nvim-start",
  })
end, 100)

-- Auto-reload files changed outside of Neovim
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("auto_reload_files", { clear = true }),
  command = "checktime",
})
