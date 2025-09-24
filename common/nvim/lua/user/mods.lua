-- ============================================================================
-- Modules/Utility functions
-- ============================================================================

local M = {}

-- Shorten Function Names
local fn = vim.fn
local api = vim.api

--- Check if an executable exists
---@param name string The name of the executable to check
---@return boolean
function M.executable(name)
  return fn.executable(name) > 0
end

--- Check if a feature is available in Neovim
---@param feat string The feature to check (e.g., 'nvim-0.7')
---@return boolean
function M.has(feat)
  return fn.has(feat) == 1
end

--- Setup command aliases
---@param from string The alias
---@param to string The command to alias to
function M.setup_command_alias(from, to)
  local cmd = string.format('cnoreabbrev <expr> %s (getcmdtype() == ":" && getcmdline() == "%s") ? "%s" : "%s"',
    from, from, to, from)
  api.nvim_command(cmd)
end

--- Preserve cursor position while formatting
---@param cmd string The command to run
function M.preserve_cursor(cmd)
  local cursor = api.nvim_win_get_cursor(0)
  vim.cmd(cmd)
  api.nvim_win_set_cursor(0, cursor)
end

--- Toggle quickfix window
function M.toggle_quickfix()
  local qf_exists = false
  for _, win in pairs(fn.getwininfo()) do
    if win.quickfix == 1 then
      qf_exists = true
      break
    end
  end
  if qf_exists then
    vim.cmd('cclose')
  else
    vim.cmd('copen')
  end
end

--- Toggle location list
function M.toggle_location()
  local loc_exists = false
  for _, win in pairs(fn.getwininfo()) do
    if win.loclist == 1 then
      loc_exists = true
      break
    end
  end
  if loc_exists then
    vim.cmd('lclose')
  else
    vim.cmd('lopen')
  end
end

-- Setup command aliases
M.setup_command_alias('W', 'w')
M.setup_command_alias('Wq', 'wq')
M.setup_command_alias('WQ', 'wq')
M.setup_command_alias('Q', 'q')
M.setup_command_alias('Qa', 'qa')
M.setup_command_alias('QA', 'qa')

--------------------------------------------------

--- Check whether a feature exists in Nvim
--- @feat: string
---   the feature name, like `nvim-0.7` or `unix`.
--- return: bool
M.has = function(feat)
  if fn.has(feat) == 1 then
    return true
  end

  return false
end

--------------------------------------------------

-- Format on save
local format_augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local ok, null_ls = pcall(require, "null-ls")
if ok then
  null_ls.setup({
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = format_augroup,
          buffer = bufnr,
          callback = function()
            if vim.lsp.buf.format then
              vim.lsp.buf.format({ bufnr = bufnr })
            else
              vim.lsp.buf.formatting_seq_sync()
            end
          end,
        })
      end
    end,
  })
end

vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]])


--------------------------------------------------

---Determine if a value of any type is empty
---@param item any
---@return boolean?

--- Checks if an item is considered "empty".
--
-- An item is considered empty if:
-- - It is nil.
-- - It is an empty string.
-- - It is an empty table.
-- - It is a number equal to 0 (you might want to adjust this based on your definition of "empty" for numbers).
--
-- @param item any The item to check.
-- @return boolean True if the item is empty, false otherwise.
function M.empty(item)
  -- Case 1: item is nil
  if item == nil then
    return true
  end

  local item_type = type(item)

  -- Case 2: empty string
  if item_type == "string" then
    return item == ""
  end

  if item_type == "table" then
    return vim.tbl_isempty(item)
  end
  if item_type == "number" then
    return item == 0 -- Changed from item <= 0 for a stricter "empty" definition for numbers
  end

  if item_type == "boolean" then
    return not item -- Returns true if item is false, false if item is true
  end

  return false
end


--------------------------------------------------

--- Create a dir if it does not exist
function M.may_create_dir(dir)
  local res = fn.isdirectory(dir)

  if res == 0 then
    fn.mkdir(dir, "p")
  end
end

--------------------------------------------------

--- Toggle cmp completion
vim.g.cmp_toggle_flag = false -- initialize
local normal_buftype = function()
  return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
end
M.toggle_completion = function()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    local next_cmp_toggle_flag = not vim.g.cmp_toggle_flag
    if next_cmp_toggle_flag then
      print("completion on")
    else
      print("completion off")
    end
    cmp.setup({
      enabled = function()
        vim.g.cmp_toggle_flag = next_cmp_toggle_flag
        if next_cmp_toggle_flag then
          return normal_buftype
        else
          return next_cmp_toggle_flag
        end
      end,
    })
  else
    print("completion not available")
  end
end

--------------------------------------------------

--- Make sure using latest neovim version
function M.get_nvim_version()
  local actual_ver = vim.version()

  local nvim_ver_str = string.format("%d.%d.%d", actual_ver.major, actual_ver.minor, actual_ver.patch)
  return nvim_ver_str
end

function M.add_pack(name)
  local status, error = pcall(vim.cmd, "packadd " .. name)

  return status
end

--------------------------------------------------

-- Define a global function to retrieve LSP clients based on Neovim version
function M.get_lsp_clients(bufnr)
  local mods = require("user.mods")
  --local expected_ver = '0.10.0'
  local nvim_ver = mods.get_nvim_version()

  local version_major, version_minor = string.match(nvim_ver, "(%d+)%.(%d+)")
  version_major = tonumber(version_major)
  version_minor = tonumber(version_minor)

  if version_major > 0 or (version_major == 0 and version_minor >= 10) then
    return vim.lsp.get_clients({ buffer = bufnr })
  else
    return vim.lsp.buf_get_clients()
  end
end

--------------------------------------------------

--- Toggle autopairs on/off (requires "windwp/nvim-autopairs")
function M.Toggle_autopairs()
  local ok, autopairs = pcall(require, "nvim-autopairs")
  if ok then
    if autopairs.state.disabled then
      autopairs.enable()
      print("autopairs on")
    else
      autopairs.disable()
      print("autopairs off")
    end
  else
    print("autopairs not available")
  end
end

--------------------------------------------------

--- Make vim-rooter message disappear after making it's changes
--vim.cmd([[
--let timer = timer_start(1000, 'LogTrigger', {})
--func! LogTrigger(timer)
--  silent!
--endfunc
--]])
--
--vim.cmd([[
--function! ConfigureChDir()
--  echo ('')
--endfunction
--" Call after vim-rooter changes the root dir
--autocmd User RooterChDir :sleep! | call LogTrigger(timer) | call ConfigureChDir()
--]])

function M.findFilesInCwd()
  vim.cmd("let g:rooter_manual_only = 1") -- Toggle the rooter plugin
  require("plugins.telescope").findhere()
  vim.defer_fn(function()
    vim.cmd("let g:rooter_manual_only = 0") -- Change back to automatic rooter
  end, 100)
end

--function M.findFilesInCwd()
--  vim.cmd("let g:rooter_manual_only = 1") -- Toggle the rooter plugin
--  require("plugins.telescope").findhere()
--  --vim.cmd("let g:rooter_manual_only = 0") -- Change back to automatic rooter
--end

--------------------------------------------------

-- Toggle the executable permission
function M.Toggle_executable()
  local current_file = vim.fn.expand("%:p")
  local executable = vim.fn.executable(current_file) == 1

  if executable then
    -- File is executable, unset the executable permission
    vim.fn.system("chmod -x " .. current_file)
    --print(current_file .. ' is no longer executable.')
    print("No longer executable")
  else
    -- File is not executable, set the executable permission
    vim.fn.system("chmod +x " .. current_file)
    --print(current_file .. ' is now executable.')
    print("Now executable")
  end
end

--------------------------------------------------

-- Set bare dotfiles repository git environment variables dynamically

-- Set git enviornment variables
--function M.Set_git_env_vars()
--  local git_dir_job = vim.fn.jobstart({ "git", "rev-parse", "--git-dir" })
--  local command_status = vim.fn.jobwait({ git_dir_job })[1]
--  if command_status > 0 then
--    vim.env.GIT_DIR = vim.fn.expand("$HOME/.cfg")
--    vim.env.GIT_WORK_TREE = vim.fn.expand("~")
--  else
--    vim.env.GIT_DIR = nil
--    vim.env.GIT_WORK_TREE = nil
--  end
--  -- Launch terminal emulator with Git environment variables set
--  --require("toggleterm").exec(string.format([[%s %s]], os.getenv("SHELL"), "-i"))
--end

------

local prev_cwd = ""

function M.Set_git_env_vars()
  local cwd = vim.fn.getcwd()
  if prev_cwd == "" then
    -- First buffer being opened, set prev_cwd to cwd
    prev_cwd = cwd
  elseif cwd ~= prev_cwd then
    -- Working directory has changed since last buffer was opened
    prev_cwd = cwd
    local git_dir_job = vim.fn.jobstart({ "git", "rev-parse", "--git-dir" })
    local command_status = vim.fn.jobwait({ git_dir_job })[1]
    if command_status > 0 then
      vim.env.GIT_DIR = vim.fn.expand("$HOME/.cfg")
      vim.env.GIT_WORK_TREE = vim.fn.expand("~")
    else
      vim.env.GIT_DIR = nil
      vim.env.GIT_WORK_TREE = nil
    end
  end
end

vim.cmd([[augroup my_git_env_vars]])
vim.cmd([[  autocmd!]])
vim.cmd([[  autocmd BufEnter * lua require('user.mods').Set_git_env_vars()]])
vim.cmd([[  autocmd VimEnter * lua require('user.mods').Set_git_env_vars()]])
vim.cmd([[augroup END]])

--------------------------------------------------

--- Update Tmux Status Vi-mode
function M.update_tmux_status()
  -- Check if the current buffer has a man filetype
  if vim.bo.filetype == "man" then
    return
  end
  local mode = vim.api.nvim_eval("mode()")
  -- Determine the mode name based on the mode value
  local mode_name
  if mode == "n" then
    mode_name = "-- NORMAL --"
  elseif mode == "i" or mode == "ic" then
    mode_name = "-- INSERT --"
  else
    mode_name = "-- NORMAL --" --'-- COMMAND --'
  end

  -- Write the mode name to the file
  local file = io.open(os.getenv("HOME") .. "/.vi-mode", "w")
  file:write(mode_name)
  file:close()
  if nvim_running then
    -- Neovim is running, update the mode file and refresh tmux
    VI_MODE = "" -- Clear VI_MODE to show Neovim mode
    vim.cmd("silent !tmux refresh-client -S")
  end
  ---- Force tmux to update the status
  vim.cmd("silent !tmux refresh-client -S")
end

vim.cmd([[
  augroup TmuxStatus
    autocmd!
    autocmd InsertLeave,InsertEnter * lua require("user.mods").update_tmux_status()
    autocmd VimEnter * lua require("user.mods").update_tmux_status()
    autocmd BufEnter * lua require("user.mods").update_tmux_status()
    autocmd ModeChanged * lua require("user.mods").update_tmux_status()
    autocmd WinEnter,WinLeave * lua require("user.mods").update_tmux_status()
  augroup END
]])

-- Add autocmd for <esc>
-- Add autocmd to check when tmux switches panes/windows
--autocmd InsertLeave,InsertEnter * lua require("user.mods").update_tmux_status()
--autocmd BufEnter * lua require("user.mods").update_tmux_status()
--autocmd WinEnter,WinLeave * lua require("user.mods").update_tmux_status()

--autocmd WinEnter,WinLeave * lua require("user.mods").update_tmux_status()
--autocmd VimResized * lua require("user.mods").update_tmux_status()
--autocmd FocusGained * lua require("user.mods").update_tmux_status()
--autocmd FocusLost * lua require("user.mods").update_tmux_status()
--autocmd CmdwinEnter,CmdwinLeave * lua require("user.mods").update_tmux_status()

--------------------------------------------------

-- function OpenEmulatorList()
-- 	local emulatorsBuffer = vim.api.nvim_create_buf(false, true)
-- 	vim.api.nvim_buf_set_lines(emulatorsBuffer, 0, 0, true, {"Some text"})
-- 	vim.api.nvim_open_win(
-- 		emulatorsBuffer,
-- 		false,
-- 		{
-- 			relative='win', row=3, col=3, width=12, height=3
-- 		}
-- 	)
-- end
--
-- vim.api.nvim_create_user_command('OpenEmulators', OpenEmulatorList, {})

--local api = vim.api
--local fn = vim.fn
--local cmd = vim.cmd
--
--local function bufremove(opts)
--  local target_buf_id = api.nvim_get_current_buf()
--
--  -- Do nothing if buffer is in modified state.
--  if not opts.force and api.nvim_buf_get_option(target_buf_id, 'modified') then
--    return false
--  end
--
--  -- Hide target buffer from all windows.
--  vim.tbl_map(function(win_id)
--    win_id = win_id or 0
--
--    local current_buf_id = api.nvim_win_get_buf(win_id)
--
--    api.nvim_win_call(win_id, function()
--      -- Try using alternate buffer
--      local alt_buf_id = fn.bufnr('#')
--      if alt_buf_id ~= current_buf_id and fn.buflisted(alt_buf_id) == 1 then
--        api.nvim_win_set_buf(win_id, alt_buf_id)
--        return
--      end
--
--      -- Try using previous buffer
--      cmd('bprevious')
--      if current_buf_id ~= api.nvim_win_get_buf(win_id) then
--        return
--      end
--
--      -- Create new listed scratch buffer
--      local new_buf = api.nvim_create_buf(true, true)
--      api.nvim_win_set_buf(win_id, new_buf)
--    end)
--
--    return true
--  end, fn.win_findbuf(target_buf_id))
--
--  cmd(string.format('bdelete%s %d', opts.force and '!' or '', target_buf_id))
--end
--
---- Assign bufremove to a global variable
--_G.bufremove = bufremove

--vim.cmd([[
--  augroup NvimTreeDelete
--    autocmd!
--    autocmd FileType NvimTree lua require('user.mods').enew_on_delete()
--  augroup END
--]])
--
--function M.enew_on_delete()
--  if vim.bo.buftype == 'nofile' then
--    vim.cmd('enew')
--  end
--end

-- Update Neovim
--function M.Update_neovim()
--  -- Run the commands to download and extract the latest version
--  os.execute("curl -L -o nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz")
--  os.execute("tar xzvf nvim-linux64.tar.gz")
--  -- Replace the existing Neovim installation with the new version
--  os.execute("rm -rf $HOME/.local/bin/nvim")
--  os.execute("mv nvim-linux64 $HOME/.local/bin/nvim")
--
--  -- Clean up the downloaded file
--  os.execute("rm nvim-linux64.tar.gz")
--
--  -- Print a message to indicate the update is complete
--  print("Neovim has been updated to the latest version.")
--end
--
---- Bind a keymap to the update_neovim function (optional)
--vim.api.nvim_set_keymap('n', '<leader>u', '<cmd> lua require("user.mods").Update_neovim()<CR>', { noremap = true, silent = true })

-- Define a function to create a floating window and run the update process inside it
function M.Update_neovim()
  -- Create a new floating window
  local bufnr, winid = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = 80,
    height = 20,
    row = 2,
    col = 2,
    style = "minimal",
    border = "single",
  })

  -- Function to append a line to the buffer in the floating window
  local function append_line(line)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  end

  -- Download the latest version of Neovim
  append_line("Downloading the latest version of Neovim...")
  os.execute(
  "curl -L -o nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz")
  append_line("Download complete.")

  -- Extract the downloaded archive
  append_line("Extracting the downloaded archive...")
  os.execute("tar xzvf nvim-linux64.tar.gz")
  append_line("Extraction complete.")

  -- Replace the existing Neovim installation with the new version
  append_line("Replacing the existing Neovim installation...")
  os.execute("rm -rf $HOME/nvim")
  os.execute("mv nvim-linux64 $HOME/nvim")
  append_line("Update complete.")

  -- Clean up the downloaded file
  append_line("Cleaning up the downloaded file...")
  os.execute("rm nvim-linux64.tar.gz")
  append_line("Cleanup complete.")

  -- Close the floating window after a delay
  vim.defer_fn(function()
    vim.api.nvim_win_close(winid, true)
  end, 5000) -- Adjust the delay as needed
end

-- Bind a keymap to the update_neovim function (optional)
vim.api.nvim_set_keymap("n", "<leader>U", '<cmd> lua require("user.mods").Update_neovim()<CR>',
  { noremap = true, silent = true })

--------------------------------------------------

-- Fix or suppress closing nvim error message (/src/unix/core.c:147: uv_close: Assertion `!uv__is_closing(handle)' failed.)
vim.api.nvim_create_autocmd({ "VimLeave" }, {
  callback = function()
    vim.fn.jobstart("!notify-send 2>/dev/null &", { detach = true })
  end,
})

--------------------------------------------------

-- Rooter
--vim.cmd([[autocmd BufEnter * lua vim.cmd('Rooter')]])

--------------------------------------------------

-- Nvim-tree
local modifiedBufs = function(bufs) -- nvim-tree is also there in modified buffers so this function filter it out
  local t = 0
  for k, v in pairs(bufs) do
    if v.name:match("NvimTree_", "NvimTree1") == nil then
      t = t + 1
    end
  end
  return t
end

-- Deleting current file opened behaviour
function M.DeleteCurrentBuffer()
  local cbn = vim.api.nvim_get_current_buf()
  local buffers = vim.fn.getbufinfo({ buflisted = true })
  local size = #buffers
  local idx = 0

  for n, e in ipairs(buffers) do
    if e.bufnr == cbn then
      idx = n
      break -- Exit loop as soon as we find the buffer
    end
  end

  if idx == 0 then
    return
  end

  if idx == size then
    vim.cmd("bprevious")
  else
    vim.cmd("bnext")
  end

  vim.cmd("silent! bdelete " .. cbn)

  -- Open a new blank window
  vim.cmd("silent! enew") -- Opens a new vertical split
  -- OR
  -- vim.cmd("new")  -- Opens a new horizontal split
  -- Delay before opening a new split
  --vim.defer_fn(function()
  --  vim.cmd("enew") -- Opens a new vertical split
  --end, 100)         -- Adjust the delay as needed (in milliseconds)
  -- Delay before closing the nvim-tree window
end


-- On :bd nvim-tree should behave as if it wasn't opened
-- Only run DeleteCurrentBuffer if NvimTree is loaded
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function()
    local ok, mods = pcall(require, "user.mods")
    if ok and type(mods.DeleteCurrentBuffer) == "function" then
      mods.DeleteCurrentBuffer()
    end
  end,
})

-- Handle NvimTree window closure safely
vim.api.nvim_create_autocmd("BufEnter", {
  nested = true,
  callback = function()
    local ok_utils, utils = pcall(require, "nvim-tree.utils")
    if not ok_utils then return end

    if #vim.api.nvim_list_wins() == 1 and utils.is_nvim_tree_buf() then
      local ok_api, api = pcall(require, "nvim-tree.api")
      if not ok_api then return end

      vim.defer_fn(function()
        -- Safely toggle tree off and on
        pcall(api.tree.toggle, { find_file = true, focus = true })
        pcall(api.tree.toggle, { find_file = true, focus = true })
        vim.cmd("wincmd p")
      end, 0)
    end
  end,
})

-- Dismiss notifications when opening nvim-tree window
local function isNvimTreeOpen()
  local win = vim.fn.win_findbuf(vim.fn.bufnr("NvimTree"))
  return vim.fn.empty(win) == 0
end

function M.DisableNotify()
  if isNvimTreeOpen() then
    require("notify").dismiss()
  end
end

vim.cmd([[
  autocmd! WinEnter,WinLeave * lua require('user.mods').DisableNotify()
]])

--------------------------------------------------

-- Toggle Dashboard
function M.toggle_dashboard()
  if vim.bo.filetype == "dashboard" then
    vim.cmd("bdelete")
  else
    vim.cmd("Dashboard")
  end
end

--------------------------------------------------

-- Helper function to suppress errors
local function silent_execute(cmd)
  vim.fn["serverlist"]() -- Required to prevent 'Press ENTER' prompt
  local result = vim.fn.system(cmd .. " 2>/dev/null")
  vim.fn["serverlist"]()
  return result
end

--------------------------------------------------

-- Toggle Codi
-- Define a global variable to track Codi's state
local is_codi_open = false

function M.toggleCodi()
  if is_codi_open then
    -- Close Codi
    vim.cmd("Codi!")
    is_codi_open = false
    print("Codi off")
  else
    -- Open Codi
    vim.cmd("Codi")
    is_codi_open = true
    print("Codi on")
  end
end

--------------------------------------------------

---- Function to create or toggle a scratch buffer
-- Define global variables to store the scratch buffer and window
local scratch_buf = nil
local scratch_win = nil

-- Other global variables
local scratch_date = os.date("%Y-%m-%d")
local scratch_dir = vim.fn.expand("~/notes/private")
local scratch_file = "scratch-" .. scratch_date .. ".md"

-- Function to close and delete a buffer
function CloseAndDeleteBuffer(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_command("silent! bwipe " .. bufnr)
  end
end

function M.Scratch(Split_direction)
  -- Check if the directory exists, and create it if it doesn't
  if vim.fn.isdirectory(scratch_dir) == 0 then
    vim.fn.mkdir(scratch_dir, "p")
  end

  -- Determine the window type based on Split_direction
  local current_window_type = "float"
  if Split_direction == "float" then
    current_window_type = "float"
  elseif Split_direction == "vertical" then
    current_window_type = "vertical"
  elseif Split_direction == "horizontal" then
    current_window_type = "horizontal"
  end

  local file_path = scratch_dir .. "/" .. scratch_file

  if scratch_win and vim.api.nvim_win_is_valid(scratch_win) then
    -- Window exists, save buffer to file and close it
    WriteScratchBufferToFile(scratch_buf, file_path)
    vim.cmd(":w!")
    vim.api.nvim_win_close(scratch_win, true)
    CloseAndDeleteBuffer(scratch_buf)
    scratch_win = nil
    scratch_buf = nil
  else
    if scratch_buf and vim.api.nvim_buf_is_valid(scratch_buf) then
      -- Buffer exists, reuse it and open a new window
      OpenScratchWindow(scratch_buf, current_window_type)
    else
      -- Buffer doesn't exist, create it and load the file if it exists
      scratch_buf = OpenScratchBuffer(file_path)
      OpenScratchWindow(scratch_buf, current_window_type)
    end
  end
end

-- Function to write buffer contents to a file
function WriteScratchBufferToFile(buf, file_path)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    local escaped_file_path = vim.fn.fnameescape(file_path)

    -- Write the buffer content to the file
    local file = io.open(escaped_file_path, "w")
    if file then
      file:write(content)
      file:close()
    end
  end
end

-- Function to create or open the scratch buffer
function OpenScratchBuffer(file_path)
  local buf = vim.api.nvim_create_buf(true, false)

  -- Set the file name for the buffer
  local escaped_file_path = vim.fn.fnameescape(file_path)
  vim.api.nvim_buf_set_name(buf, escaped_file_path)

  -- Check if the file exists and load it if it does
  if vim.fn.filereadable(file_path) == 1 then
    local file_contents = vim.fn.readfile(file_path)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, file_contents)
  else
    -- Insert initial content
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, {
      "# Quick Notes - " .. scratch_date,
      "--------------------------",
      "",
    })

    -- Save the initial content to the file
    vim.cmd(":w")
  end

  return buf
end

-- Function to open the scratch buffer in a window
function OpenScratchWindow(buf, current_window_type)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    if current_window_type == "float" then
      local opts = {
        relative = "win",
        width = 120,
        height = 10,
        border = "single",
        row = 20,
        col = 20,
      }
      scratch_win = vim.api.nvim_open_win(buf, true, opts)
      -- Go to the last line of the buffer
      vim.api.nvim_win_set_cursor(scratch_win, { vim.api.nvim_buf_line_count(buf), 1 })
    elseif current_window_type == "vertical" then
      vim.cmd("vsplit")
      vim.api.nvim_win_set_buf(0, buf)
      scratch_win = 0
    elseif current_window_type == "horizontal" then
      vim.cmd("split")
      vim.api.nvim_win_set_buf(0, buf)
      scratch_win = 0
    end
  end
end

--------------------------------------------------

---- Intercept file open
--local augroup = vim.api.nvim_create_augroup("user-autocmds", { clear = true })
--local intercept_file_open = true
--vim.api.nvim_create_user_command("InterceptToggle", function()
--  intercept_file_open = not intercept_file_open
--  local intercept_state = "`Enabled`"
--  if not intercept_file_open then
--    intercept_state = "`Disabled`"
--  end
--  vim.notify("Intercept file open set to " .. intercept_state, vim.log.levels.INFO, {
--    title = "Intercept File Open",
--    ---@param win integer The window handle
--    on_open = function(win)
--      vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(win), "filetype", "markdown")
--    end,
--  })
--end, { desc = "Toggles intercepting BufNew to open files in custom programs" })

---- NOTE: Add "BufReadPre" to the autocmd events to also intercept files given on the command line, e.g.
---- `nvim myfile.txt`
--vim.api.nvim_create_autocmd({ "BufNew" }, {
--  group = augroup,
--  callback = function(args)
--    ---@type string
--    local path = args.match
--    ---@type integer
--    local bufnr = args.buf
--
--    ---@type string? The file extension if detected
--    local extension = vim.fn.fnamemodify(path, ":e")
--    ---@type string? The filename if detected
--    local filename = vim.fn.fnamemodify(path, ":t")
--
--    ---Open a given file path in a given program and remove the buffer for the file.
--    ---@param buf integer The buffer handle for the opening buffer
--    ---@param fpath string The file path given to the program
--    ---@param fname string The file name used in notifications
--    ---@param prog string The program to execute against the file path
--    local function open_in_prog(buf, fpath, fname, prog)
--      vim.notify(string.format("Opening `%s` in `%s`", fname, prog), vim.log.levels.INFO, {
--        title = "Open File in External Program",
--        ---@param win integer The window handle
--        on_open = function(win)
--          vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(win), "filetype", "markdown")
--        end,
--      })
--      local mods = require("user.mods")
--      local nvim_ver = mods.get_nvim_version()
--
--      local version_major, version_minor = string.match(nvim_ver, "(%d+)%.(%d+)")
--      version_major = tonumber(version_major)
--      version_minor = tonumber(version_minor)
--
--      if version_major > 0 or (version_major == 0 and version_minor >= 10) then
--        vim.system({ prog, fpath }, { detach = true })
--      else
--        vim.fn.jobstart({ prog, fpath }, { detach = true })
--      end
--      vim.api.nvim_buf_delete(buf, { force = true })
--    end
--
--    local extension_callbacks = {
--      ["pdf"] = function(buf, fpath, fname)
--        open_in_prog(buf, fpath, fname, "zathura")
--      end,
--      ["epub"] = function(buf, fpath, fname)
--        open_in_prog(buf, fpath, fname, "zathura")
--      end,
--      ["mobi"] = "pdf",
--      ["png"] = function(buf, fpath, fname)
--        open_in_prog(buf, fpath, fname, "vimiv")
--      end,
--      ["jpg"] = "png",
--      ["mp4"] = function(buf, fpath, fname)
--        open_in_prog(buf, fpath, fname, "vlc")
--      end,
--      ["gif"] = "mp4",
--    }
--
--    ---Get the extension callback for a given extension. Will do a recursive lookup if an extension callback is actually
--    ---of type string to get the correct extension
--    ---@param ext string A file extension. Example: `png`.
--    ---@return fun(bufnr: integer, path: string, filename: string?) extension_callback The extension callback to invoke, expects a buffer handle, file path, and filename.
--    local function extension_lookup(ext)
--      local callback = extension_callbacks[ext]
--      if type(callback) == "string" then
--        callback = extension_lookup(callback)
--      end
--      return callback
--    end
--
--    if extension ~= nil and not extension:match("^%s*$") and intercept_file_open then
--      local callback = extension_lookup(extension)
--      if type(callback) == "function" then
--        callback(bufnr, path, filename)
--      end
--    end
--  end,
--})

--------------------------------------------------

-- Delete [No Name] buffers
vim.api.nvim_create_autocmd("BufHidden", {
  desc = "Delete [No Name] buffers",
  callback = function(event)
    if event.file == "" and vim.bo[event.buf].buftype == "" and not vim.bo[event.buf].modified then
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, event.buf, {})
      end)
    end
  end,
})

--------------------------------------------------

local codeRunnerEnabled = false

function M.toggleCodeRunner()
  codeRunnerEnabled = not codeRunnerEnabled
  if codeRunnerEnabled then
    print("Code Runner enabled")
    M.RunCode() -- Execute when enabled
  else
    print("Code Runner disabled")
    -- Close the terminal window when disabled
    local buffers = vim.fn.getbufinfo()

    for _, buf in ipairs(buffers) do
      local type = vim.api.nvim_buf_get_option(buf.bufnr, "buftype")
      if type == "terminal" then
        vim.api.nvim_command("silent! bdelete " .. buf.bufnr)
      end
    end
  end
end

local function substitute(cmd)
  cmd = cmd:gsub("%%", vim.fn.expand("%"))
  cmd = cmd:gsub("$fileBase", vim.fn.expand("%:r"))
  cmd = cmd:gsub("$filePath", vim.fn.expand("%:p"))
  cmd = cmd:gsub("$file", vim.fn.expand("%"))
  cmd = cmd:gsub("$dir", vim.fn.expand("%:p:h"))
  cmd = cmd:gsub("#", vim.fn.expand("#"))
  cmd = cmd:gsub("$altFile", vim.fn.expand("#"))

  return cmd
end

function M.RunCode()
  if not codeRunnerEnabled then
    print("Code Runner is currently disabled. Toggle it on to execute code.")
    return
  end
  local file_extension = vim.fn.expand("%:e")
  local selected_cmd = ""
  local supported_filetypes = {
    html = {
      default = "%",
    },
    c = {
      default = "gcc % -o $fileBase && ./$fileBase",
      debug = "gcc -g % -o $fileBase && ./$fileBase",
    },
    cs = {
      default = "dotnet run",
    },
    cpp = {
      default = "g++ % -o  $fileBase && ./$fileBase",
      debug = "g++ -g % -o  ./$fileBase",
      competitive = "g++ -std=c++17 -Wall -DAL -O2 % -o $fileBase && $fileBase<input.txt",
    },
    py = {
      default = "python %",
    },
    go = {
      default = "go run %",
    },
    java = {
      default = "java %",
    },
    js = {
      default = "node %",
      debug = "node --inspect %",
    },
    lua = {
      default = "lua %",
    },
    ts = {
      default = "tsc % && node $fileBase",
    },
    rs = {
      default = "rustc % && $fileBase",
    },
    php = {
      default = "php %",
    },
    r = {
      default = "Rscript %",
    },
    jl = {
      default = "julia %",
    },
    rb = {
      default = "ruby %",
    },
    pl = {
      default = "perl %",
    },
  }

  local term_cmd = "bot 10 new | term "
  local choices = {}

  -- Add 'default' as the first option if available
  if supported_filetypes[file_extension]["default"] then
    table.insert(choices, "default")
  end

  -- Add 'debug' as the second option if available
  if supported_filetypes[file_extension]["debug"] then
    table.insert(choices, "debug")
  end

  -- Add other available options
  for key, _ in pairs(supported_filetypes[file_extension]) do
    if key ~= "default" and key ~= "debug" then
      table.insert(choices, key)
    end
  end
  if #choices == 0 then
    vim.notify("It doesn't contain any command", vim.log.levels.WARN, { title = "Code Runner" })
  elseif #choices == 1 then
    selected_cmd = supported_filetypes[file_extension][choices[1]]
    vim.cmd(term_cmd .. substitute(selected_cmd))
  else
    vim.ui.select(choices, {
      prompt = "Choose a command: ",
      layout_config = {
        height = 10,
        width = 40,
        prompt_position = "top",
        -- other options as required
      },
    }, function(choice)
      selected_cmd = supported_filetypes[file_extension][choice]
      if selected_cmd then
        vim.cmd(term_cmd .. substitute(selected_cmd))
      end
    end)
  end

  if not supported_filetypes[file_extension] then
    vim.notify("The filetype isn't included in the list", vim.log.levels.WARN, { title = "Code Runner" })
  end
end

--------------------------------------------------

-- Run executable file
local interpreters = {
  python = "python",
  lua = "lua",
  bash = "bash",
  zsh = "zsh",
  perl = "perl",
  ruby = "ruby",
  node = "node",
  rust = "rust",
  php = "php",
}

function M.RunCurrentFile()
  local file_path = vim.fn.expand("%:p")
  local file = io.open(file_path, "r")

  if not file then
    print("Error: Unable to open the file")
    return
  end

  local shebang = file:read()
  file:close()

  local interpreter = shebang:match("#!%s*(.-)$")
  if not interpreter then
    print("Error: No shebang line found in the file")
    return
  end

  -- Remove leading spaces and any arguments, extracting the interpreter name
  interpreter = interpreter:gsub("^%s*([^%s]+).*", "%1")

  local cmd = interpreters[interpreter]

  if not cmd then
    cmd = interpreter -- Set the command to the interpreter directly
  end

  -- Run the file using the determined interpreter
  vim.fn.jobstart(cmd .. " " .. file_path, {
    cwd = vim.fn.expand("%:p:h"),
  })
end

--------------------------------------------------

-- Close all floating windows
vim.api.nvim_create_user_command("CloseFloatingWindows", function(opts)
  for _, window_id in ipairs(vim.api.nvim_list_wins()) do
    -- If window is floating
    if vim.api.nvim_win_get_config(window_id).relative ~= "" then
      -- Force close if called with !
      vim.api.nvim_win_close(window_id, opts.bang)
    end
  end
end, { bang = true, nargs = 0 })

--------------------------------------------------


-- Platform detection
local uname = vim.loop.os_uname().sysname
local has = vim.fn.has

local is_mac = has("mac") == 1
local is_linux = uname == "Linux"
local is_windows = has("win32") == 1 or uname:find("Windows")
local is_wsl = has("wsl") == 1 or (uname:find("Linux") and (os.getenv("WSL_DISTRO_NAME") ~= nil))
local is_termux = has("termux") == 1 or (os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux"))
local os_name = (is_mac and "mac") or (is_linux and "linux") or (is_windows and "windows") or (is_wsl and "wsl") or (is_termux and "termux") or uname:lower()

-- Check if a command exists
local function command_exists(cmd)
  local handle = io.popen(cmd .. " --version 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
  end
  return false
end

-- Detect clipboard tool on Linux
local function detect_clipboard_tool()
  if command_exists("xclip") then return "xclip" end
  if command_exists("xsel") then return "xsel" end
  if command_exists("wl-copy") and command_exists("wl-paste") then return "wl-clipboard" end
  return nil
end

-- OSC52 clipboard copy fallback
local function osc52_copy(text)
  local encoded = vim.fn.system("base64 | tr -d '\n'", text)
  io.write(string.format("\027]52;c;%s\007", encoded))
end

---- Set clipboard
--function set_clipboard(text)
--  if not text or text == "" then return end
--
--  if is_mac then
--    local handle = io.popen("pbcopy", "w")
--    if handle then
--      handle:write(text)
--      handle:close()
--    end
--  elseif is_linux then
--    local tool = detect_clipboard_tool()
--    if tool == "xclip" then
--      local handle = io.popen("xclip -selection clipboard", "w")
--      if handle then handle:write(text) handle:close() end
--    elseif tool == "xsel" then
--      local handle = io.popen("xsel --clipboard --input", "w")
--      if handle then handle:write(text) handle:close() end
--    elseif tool == "wl-clipboard" then
--      local handle = io.popen("wl-copy", "w")
--      if handle then handle:write(text) handle:close() end
--    else
--      osc52_copy(text)
--      vim.notify("Using OSC52 for clipboard (install xclip, xsel, or wl-clipboard for better support)", vim.log.levels.INFO)
--    end
--  elseif is_wsl or is_windows then
--    local handle = io.popen("clip", "w")
--    if handle then handle:write(text) handle:close() end
--  elseif is_termux then
--    local handle = io.popen("termux-clipboard-set", "w")
--    if handle then handle:write(text) handle:close() end
--  else
--    vim.notify("No clipboard support for OS: " .. os_name, vim.log.levels.WARN)
--  end
--end
--
---- Clipboard sync autocmd setup
--local function setup_clipboard_sync()
--  local ok, Job = pcall(require, "plenary.job")
--  if not ok then
--    -- plenary not available, skip
--    return
--  end
--
--  vim.api.nvim_create_augroup("clipboard_sync", { clear = true })
--  vim.api.nvim_create_autocmd("TextYankPost", {
--    group = "clipboard_sync",
--    desc = "Sync yanked text to system clipboard",
--    pattern = "*",
--    callback = function()
--      local text = vim.fn.getreg("\"")
--      if text ~= nil and text ~= "" then
--        set_clipboard(text)
--      end
--    end,
--  })
--end
--setup_clipboard_sync()
--
---- Terminal clear function (optional)
--function clear_terminal()
--  vim.opt.scrollback = 1
--  vim.api.nvim_feedkeys("i", "n", false)
--  vim.api.nvim_feedkeys("clear\r", "n", false)
--  vim.api.nvim_feedkeys("\x1b", "n", false)
--  vim.api.nvim_feedkeys("i", "n", false)
--  vim.defer_fn(function()
--    vim.opt.scrollback = 10000
--  end, 100)
--end
--
---- Get clipboard content (optional)
--function GetClipboard()
--  local handle
--
--  if is_mac then
--    handle = io.popen("pbpaste", "r")
--  elseif is_linux then
--    local tool = detect_clipboard_tool()
--    if tool == "xclip" then
--      handle = io.popen("xclip -selection clipboard -o", "r")
--    elseif tool == "xsel" then
--      handle = io.popen("xsel --clipboard --output", "r")
--    elseif tool == "wl-clipboard" then
--      handle = io.popen("wl-paste", "r")
--    end
--  elseif is_wsl or is_windows then
--    handle = io.popen("powershell.exe Get-Clipboard", "r")
--  elseif is_termux then
--    handle = io.popen("termux-clipboard-get", "r")
--  end
--
--  if handle then
--    local result = handle:read("*a")
--    handle:close()
--    return result or ""
--  end
--
--  return ""
--end

--------------------------------------------------

-- Cross-platform file/URL opener
function M.open_file_or_url(path)
  local commands = {
    mac     = string.format('open "%s"', path),
    linux   = string.format('xdg-open "%s" &', path),
    wsl     = string.format('wslview "%s" &', path),
    windows = string.format('start "" "%s"', path),
    termux  = string.format('am start -a android.intent.action.VIEW -d "%s"', path),
  }

  local cmd = commands[M.os_name]
  if cmd then
    os.execute(cmd)
  else
    vim.notify("No supported file opener for this OS: " .. tostring(M.os_name), vim.log.levels.WARN)
  end
end

--------------------------------------------------

-- Automcmd to close netrw buffer when file is opened
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.api.nvim_create_autocmd("BufEnter", {
      once = true,
      callback = function()
        if vim.bo.filetype ~= "netrw" then
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].filetype == "netrw" then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end,
    })
  end,
})

--------------------------------------------------

-- Autocomplete
vim.api.nvim_create_autocmd("InsertCharPre", {
    callback = function()
        -- Exit the autocmd if nvim-cmp is present
        local cmp_is_present, _ = pcall(require, "cmp")
        if cmp_is_present then
            return
        end

        -- Skip unwanted buffer types (Telescope, NvimTree, etc.)
        local ft = vim.bo.filetype
        local bt = vim.bo.buftype
        local ignore_ft = {
            "TelescopePrompt",
            "prompt",
            "nofile",
            "terminal",
            "help",
            "quickfix",
            "lazy",
            "neo-tree",
            "NvimTree",
            "starter",
            "packer",
        }

        if bt ~= "" or vim.tbl_contains(ignore_ft, ft) then
            return
        end

        local col = vim.fn.col(".")
        local line = vim.fn.getline(".")
        local function safe_sub(i)
            return line:sub(i, i)
        end

        local prev3 = safe_sub(col - 3)
        local prev2 = safe_sub(col - 2)
        local prev1 = safe_sub(col - 1)
        local curr = vim.v.char

        if curr:match("%w") and prev3:match("%W") and prev2:match("%w") and prev1:match("%w") then
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<C-n>", true, true, true),
                "n",
                true
            )
        end
    end,
})
--------------------------------------------------

M.has_treesitter = function ( bufnr )
    if not bufnr then
        bufnr = vim.api.nvim_get_current_buf()
    end

    local highlighter = require( "vim.treesitter.highlighter" )

    if highlighter.active[ bufnr ] then
        return true
    else
        return false
    end
end

M.parse_treesitter = function ( bufnr, range )
    local parser = vim.treesitter.get_parser( bufnr )

    -- XXX https://neovim.io/doc/user/treesitter.html#LanguageTree%3Aparse()
    parser:parse( range )
end

-- ...
return M
