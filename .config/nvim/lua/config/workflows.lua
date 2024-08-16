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
-- >>> oinbox # review notes in inbox
-- >>>
-- >>> ))) <leader>ok # inside vim now, move to zettelkasten
-- >>> ))) <leader>odd # or delete
-- >>>
-- >>> og # organize saved notes from zettelkasten into notes/[tag] folders
-- >>> ou # sync local with Notion - TBD

-- local obsidianRoot = os.getenv("OBSIDIAN_ROOT")
local obsidianRoot = vim.env.OBSIDIAN_ROOT
local okDirName = "21 ZETTELKASTEN"
local notesDirName = "notes"
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
  vim.keymap.set(
    "n",
    "<leader>of",
    ':Telescope find_files search_dirs={"' .. obsidianRoot .. "/" .. notesDirName .. '"}<cr>'
  )
  vim.keymap.set(
    "n",
    "<leader>or",
    ':Telescope live_grep search_dirs={"' .. obsidianRoot .. "/" .. notesDirName .. '"}<cr>'
  )

  --
  --
  -- search for files in notes (ignore zettelkasten)
  -- vim.keymap.set("n", "<leader>ois", ":Telescope find_files search_dirs={\"/Users/alex/library/Mobile\\ Documents/iCloud~md~obsidian/Documents/ZazenCodes/notes\"}<cr>")
  -- vim.keymap.set("n", "<leader>oiz", ":Telescope live_grep search_dirs={\"/Users/alex/library/Mobile\\ Documents/iCloud~md~obsidian/Documents/ZazenCodes/notes\"}<cr>")
  --
  -- for review workflow
  -- move file in current buffer to zettelkasten folder
  -- vim.keymap.set("n", "<leader>ok", ":!mv '%:p' " .. obsidianRoot .. "/" .. okDirName .. "<cr>:bd<cr>")
  vim.keymap.set("n", "<leader>ok", function()
    -- Get the full path of the current file
    local current_file_path = vim.fn.expand("%:p")
    -- Get the parent directory path
    local parent_dir_path = vim.fn.fnamemodify(current_file_path, ":h")
    -- Get the parent directory name
    local parent_dir_name = vim.fn.fnamemodify(parent_dir_path, ":t")
    -- Get the current file name without the extension
    local file_name = vim.fn.expand("%:t:r")

    local command = "mv '" .. current_file_path .. "' '" .. obsidianRoot .. "/" .. okDirName .. "'"
    local successMessage = "Moved file: " .. file_name .. " to " .. okDirName
    local failedMessage = "Failed to move file: " .. file_name

    -- Check if the parent directory name and the file name are the same
    if parent_dir_name == file_name then
      -- Define the command to move the current file
      command = "mv '" .. parent_dir_path .. "' '" .. obsidianRoot .. "/" .. okDirName .. "'"

      successMessage = "Moved directory: " .. parent_dir_path .. " to " .. okDirName
      failedMessage = "Failed to move directory: " .. parent_dir_path
    end
    -- vim.api.nvim_command(command)
    -- Execute the move command
    local result = os.execute(command)

    -- Check the result and notify the user
    if result == 0 then
      vim.notify(successMessage, vim.log.levels.INFO)
    else
      vim.notify(failedMessage, vim.log.levels.ERROR)
    end

    -- Close the buffer
    vim.api.nvim_command("bd")
  end)
  -- delete file in current buffer
  vim.keymap.set("n", "<leader>odd", ":!rm '%:p'<cr>:bd<cr>")
else
  print("Environment variable OBSIDIAN_ROOT is not set.")
end
