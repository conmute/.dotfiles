return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPre",
    enabled = true,
    opts = { mode = "cursor" },
  },
  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "markdown" })
        vim.treesitter.language.register("markdown", "mdx")
      end
      opts.ensure_installed = {
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
        "elixir",
      }
    end,
    -- query_linter = {
    --   enable = true,
    --   use_virtual_text = true,
    --   lint_events = { "BufWrite", "CursorHold" },
    -- },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      { "windwp/nvim-ts-autotag", opts = {} },
    },
  },
}
