-- bootstrap lazy.nvim, LazyVim and your plugins
if vim.loader then
  vim.loader.enable()
end

_G.dd = function(...)
  require("util.debug").dump(...)
end
vim.print = _G.dd

require("config.lazy")

local projectInit = vim.fn.findfile(".nvim/init.lua", ".;")

if projectInit ~= "" then
  require(vim.fn.expand("%:p") .. "/.nvim")
end

-- -- Function to load project-specific init.lua if it exists
-- local function loadProjectConfig()
--   local projectInit = vim.fn.findfile(".nvim/init.lua", ".;")
--   if projectInit ~= "" then
--     vim.cmd("luafile " .. projectInit)
--   end
-- end
--
-- -- Autocommand to call loadProjectConfig when entering a directory
-- vim.cmd("autocmd BufEnter * lua loadProjectConfig()")
