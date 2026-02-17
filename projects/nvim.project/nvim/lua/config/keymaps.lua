-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<leader>yp", function()
--   vim.fn.setreg("+", vim.fn.expand("%:p"))
-- end, { desc = "Copy file path" })

-- Copy path with line range: /file/to/path:Lfrom-Lto
-- Normal mode: copy current line
vim.keymap.set("n", "<leader>yl", function()
  local path = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  local text = path .. ":L" .. line
  vim.fn.setreg("+", text)
  vim.notify("Copied: " .. text, vim.log.levels.INFO)
end, { desc = "Copy file path with current line" })

-- Visual mode: copy selected line range
vim.keymap.set("v", "<leader>yl", function()
  local path = vim.fn.expand("%:p")
  local line1 = vim.fn.line("'<")
  local line2 = vim.fn.line("'>")
  local range_str
  if line1 == line2 then
    range_str = "L" .. line1
  else
    range_str = "L" .. line1 .. "-L" .. line2
  end
  local text = path .. ":" .. range_str
  vim.fn.setreg("+", text)
  vim.notify("Copied: " .. text, vim.log.levels.INFO)
end, { desc = "Copy file path with line range" })
