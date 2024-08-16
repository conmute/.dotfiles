-- bootstrap lazy.nvim, LazyVim and your plugins

vim.cmd("language en_US")
require("config.lazy")
require("config.workflows")

-- require("cmp").setup({
--   formatting = { format = require("tailwindcss-colorizer-cmp").formatter },
-- })
