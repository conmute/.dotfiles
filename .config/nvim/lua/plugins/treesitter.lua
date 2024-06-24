return {
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "yaml",
        "tsx",
        "markdown",
        "markdown_inline",
        "javascript",
        "typescript",
        "css",
        "gitignore",
        "graphql",
        "http",
        "json",
        "scss",
        -- "sql",
        "vim",
        "lua",
        "xml",
      },
      -- query_linter = {
      --   enable = true,
      --   use_virtual_text = true,
      --   lint_events = { "BufWrite", "CursorHold" },
      -- },
    },
  },
}
