--------------
-- obsidian --
--------------
--
-- >>> oo # from shell, navigate to vault (optional)
--
-- # NEW NOTE
-- >>> on "Note Name" # call my "obsidian new note" shell script (~/bin/on)
-- >>>
-- >>> ))) <leader>on # inside vim now, format note as template
-- >>> ))) # add tag, e.g. fact / blog / video / etc..
-- >>> ))) # add hubs, e.g. [[python]], [[machine-learning]], etc...
-- >>> ))) <leader>of # format title
--
-- # END OF DAY/WEEK REVIEW
-- >>> or # review notes in inbox
-- >>>
-- >>> ))) <leader>ok # inside vim now, move to zettelkasten
-- >>> ))) <leader>odd # or delete
-- >>>
-- >>> og # organize saved notes from zettelkasten into notes/[tag] folders
-- >>> ou # sync local with Notion - TBD

-- local obsidianRoot = os.getenv("OBSIDIAN_ROOT")
local obsidianRoot = vim.env.OBSIDIAN_ROOT

if obsidianRoot then
  -- navigate to vault
  vim.keymap.set("n", "<leader>oo", ":cd " .. obsidianRoot .. "<cr>")
  --
  -- convert note to template and remove leading white space
  vim.keymap.set("n", "<leader>on", ":ObsidianTemplate note<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>")
  -- strip date from note title and replace dashes with spaces
  -- must have cursor on title
  vim.keymap.set("n", "<leader>ot", ":s/\\(# \\)[^_]*_/\\1/ | s/-/ /g<cr>")
  --
  -- search for files in full vault
  vim.keymap.set("n", "<leader>of", ':Telescope find_files search_dirs={"' .. obsidianRoot .. '/notes"}<cr>')
  vim.keymap.set("n", "<leader>or", ':Telescope live_grep search_dirs={"' .. obsidianRoot .. '/notes"}<cr>')

  --
  --
  -- search for files in notes (ignore zettelkasten)
  -- vim.keymap.set("n", "<leader>ois", ":Telescope find_files search_dirs={\"/Users/alex/library/Mobile\\ Documents/iCloud~md~obsidian/Documents/ZazenCodes/notes\"}<cr>")
  -- vim.keymap.set("n", "<leader>oiz", ":Telescope live_grep search_dirs={\"/Users/alex/library/Mobile\\ Documents/iCloud~md~obsidian/Documents/ZazenCodes/notes\"}<cr>")
  --
  -- for review workflow
  -- move file in current buffer to zettelkasten folder
  vim.keymap.set("n", "<leader>ok", ":!mv '%:p' " .. obsidianRoot .. "/zettelkasten<cr>:bd<cr>")
  -- delete file in current buffer
  vim.keymap.set("n", "<leader>odd", ":!rm '%:p'<cr>:bd<cr>")
else
  print("Environment variable OBSIDIAN_ROOT is not set.")
end
