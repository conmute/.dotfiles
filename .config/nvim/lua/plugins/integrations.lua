return {

  -- {
  --   "vhyrro/luarocks.nvim",
  --   -- explicit tell Lazy the module name due to error on calling
  --   --  the module with the suffix ‘.nvim’; in this way Lazy will call < require “luarocks”.setup({}) >
  --   name = "luarocks",
  --   priority = 1000,
  --   config = true,
  --   opts = {
  --     rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
  --   },
  -- },
  -- {
  --   "rest-nvim/rest.nvim",
  --   dependencies = { "luarocks" },
  --   ft = { "http", "https" },
  --   config = function(_, o)
  --     require("rest-nvim").setup(o)
  --   end,
  -- },

  -- {
  --   "vhyrro/luarocks.nvim",
  --   priority = 1000,
  --   name = "luarocks",
  --   opts = {
  --     rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
  --   },
  -- },
  -- {
  --   "rest-nvim/rest.nvim",
  --   ft = "http",
  --   dependencies = { "luarocks.nvim" },
  --   config = function()
  --     require("rest-nvim").setup()
  --   end,
  --   -- keys = {
  --   --   { "<leader>rr", "<cmd>Rest run<cr>", desc = "Run REST request" },
  --   -- },
  --   krrbinds = {
  --     -- {
  --     --   "<localleader>rr",
  --     --   "<cmd>Rest run<cr>",
  --     --   "Run request under the cursor",
  --     -- },
  --     -- {
  --     --   "<localleader>rl",
  --     --   "<cmd>Rest run last<cr>",
  --     --   "Re-run latest request",
  --     -- },
  --   },
  -- },
}
