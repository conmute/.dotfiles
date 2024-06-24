return {
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },

    -- key mappings, below are the defaults
    mappings = {
      -- overrides the 'gf' mapping to work on markdown/wiki links within your vault
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- toggle check-boxes
      -- ["<leader>ch"] = {
      --   action = function()
      --     return require("obsidian").util.toggle_checkbox()
      --   end,
      --   opts = { buffer = true },
      -- },
    },

    opts = {

      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },

      notes_subdir = "inbox",
      new_notes_location = "notes_subdir",

      disable_frontmatter = true,

      templates = {

        -- subdir = "templates",
        subdir = "Utility/Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M:%S",
      },

      workspaces = {
        {
          name = "GTD",
          path = "/Users/ross/.ghq/github.com/conmute/GTD",
        },
      },

      -- see below for full list of options 👇
    },
  },
}
