local M = {}

--- Shorten Function Names
local fn = vim.fn
function M.executable(name)
  if fn.executable(name) > 0 then
    return true
  end

  return false
end

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
require("null-ls").setup({
  -- you can reuse a shared lspconfig on_attach callback here
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = format_augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = format_augroup,
        buffer = bufnr,
        callback = function()
          -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
          --vim.lsp.buf.formatting_seq_sync()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end,
})

vim.cmd([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]])
--vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]

--------------------------------------------------

---Determine if a value of any type is empty
---@param item any
---@return boolean?
function M.empty(item)
  if not item then
    return true
  end
  local item_type = type(item)
  if item_type == "string" then
    return item == ""
  end
  if item_type == "number" then
    return item <= 0
  end
  if item_type == "table" then
    return vim.tbl_isempty(item)
  end
  return item ~= nil
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

vim.cmd([[autocmd FileType NvimTree lua require("user.mods").DeleteCurrentBuffer()]])

-- On :bd nvim-tree should behave as if it wasn't opened
vim.api.nvim_create_autocmd("BufEnter", {
  nested = true,
  callback = function()
    -- Only 1 window with nvim-tree left: we probably closed a file buffer
    if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
      local api = require("nvim-tree.api")
      -- Required to let the close event complete. An error is thrown without this.
      vim.defer_fn(function()
        -- close nvim-tree: will go to the last buffer used before closing
        api.tree.toggle({ find_file = true, focus = true })
        -- re-open nivm-tree
        api.tree.toggle({ find_file = true, focus = true })
        -- nvim-tree is still the active window. Go to the previous window.
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

-- Intercept file open
local augroup = vim.api.nvim_create_augroup("user-autocmds", { clear = true })
local intercept_file_open = true
vim.api.nvim_create_user_command("InterceptToggle", function()
  intercept_file_open = not intercept_file_open
  local intercept_state = "`Enabled`"
  if not intercept_file_open then
    intercept_state = "`Disabled`"
  end
  vim.notify("Intercept file open set to " .. intercept_state, vim.log.levels.INFO, {
    title = "Intercept File Open",
    ---@param win integer The window handle
    on_open = function(win)
      vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(win), "filetype", "markdown")
    end,
  })
end, { desc = "Toggles intercepting BufNew to open files in custom programs" })

-- NOTE: Add "BufReadPre" to the autocmd events to also intercept files given on the command line, e.g.
-- `nvim myfile.txt`
vim.api.nvim_create_autocmd({ "BufNew" }, {
  group = augroup,
  callback = function(args)
    ---@type string
    local path = args.match
    ---@type integer
    local bufnr = args.buf

    ---@type string? The file extension if detected
    local extension = vim.fn.fnamemodify(path, ":e")
    ---@type string? The filename if detected
    local filename = vim.fn.fnamemodify(path, ":t")

    ---Open a given file path in a given program and remove the buffer for the file.
    ---@param buf integer The buffer handle for the opening buffer
    ---@param fpath string The file path given to the program
    ---@param fname string The file name used in notifications
    ---@param prog string The program to execute against the file path
    local function open_in_prog(buf, fpath, fname, prog)
      vim.notify(string.format("Opening `%s` in `%s`", fname, prog), vim.log.levels.INFO, {
        title = "Open File in External Program",
        ---@param win integer The window handle
        on_open = function(win)
          vim.api.nvim_buf_set_option(vim.api.nvim_win_get_buf(win), "filetype", "markdown")
        end,
      })
      local mods = require("user.mods")
      local nvim_ver = mods.get_nvim_version()

      local version_major, version_minor = string.match(nvim_ver, "(%d+)%.(%d+)")
      version_major = tonumber(version_major)
      version_minor = tonumber(version_minor)

      if version_major > 0 or (version_major == 0 and version_minor >= 10) then
        vim.system({ prog, fpath }, { detach = true })
      else
        vim.fn.jobstart({ prog, fpath }, { detach = true })
      end
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    local extension_callbacks = {
      ["pdf"] = function(buf, fpath, fname)
        open_in_prog(buf, fpath, fname, "zathura")
      end,
      ["epub"] = function(buf, fpath, fname)
        open_in_prog(buf, fpath, fname, "zathura")
      end,
      ["mobi"] = "pdf",
      ["png"] = function(buf, fpath, fname)
        open_in_prog(buf, fpath, fname, "vimiv")
      end,
      ["jpg"] = "png",
      ["mp4"] = function(buf, fpath, fname)
        open_in_prog(buf, fpath, fname, "vlc")
      end,
      ["gif"] = "mp4",
    }

    ---Get the extension callback for a given extension. Will do a recursive lookup if an extension callback is actually
    ---of type string to get the correct extension
    ---@param ext string A file extension. Example: `png`.
    ---@return fun(bufnr: integer, path: string, filename: string?) extension_callback The extension callback to invoke, expects a buffer handle, file path, and filename.
    local function extension_lookup(ext)
      local callback = extension_callbacks[ext]
      if type(callback) == "string" then
        callback = extension_lookup(callback)
      end
      return callback
    end

    if extension ~= nil and not extension:match("^%s*$") and intercept_file_open then
      local callback = extension_lookup(extension)
      if type(callback) == "function" then
        callback(bufnr, path, filename)
      end
    end
  end,
})

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

-- ...
return M
