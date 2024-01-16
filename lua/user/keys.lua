local keymap = vim.keymap
local map = function(mode, l, r, opts)
  opts = opts or {}
  opts.silent = true
  opts.noremap = true
  keymap.set(mode, l, r, opts)
end
local term_opts = { noremap = true, silent = false }
local mods = require('user.mods')
local bufnr = vim.api.nvim_get_current_buf()

-- Semi-colon as leader key
vim.g.mapleader = ';'

-- "jk" and "kj" to exit insert-mode
map('i', 'jk', '<esc>')

-- Jump to next match on line using `.` instead of `;` NOTE: commented out in favour of "ggandor/flit.nvim"
--map("n", ".", ";")

-- Repeat last command using `<Space>` instead of `.` NOTE: commented out in favour of "ggandor/flit.nvim"
--map("n", "<Space>", ".")

-- Reload nvim config
map('n', '<leader><CR>', "<cmd>luafile ~/.config/nvim/init.lua<CR> | :echom ('Nvim config loading...') | :sl! | echo ('')<CR>")

--------------- Extended Operations ---------------
-- Conditional 'q' to quit on floating/quickfix/help windows otherwise still use it for macros
-- TODO: Have a list of if available on system/packages, example "Zen Mode" to not work on it (quit Zen Mode)
map('n', 'q', function()
  local config = vim.api.nvim_win_get_config(0)
  if config.relative ~= '' then -- is_floating_window?
    return ':silent! close!<CR>'
  elseif vim.o.buftype == 'quickfix' then
    return ':quit<CR>'
  elseif vim.o.buftype == 'help' then
    return ':close<CR>'
  else
    return 'q'
  end
end, { expr = true, replace_keycodes = true })

-- Write as sudo
map('c', 'W', "exe 'w !sudo tee >/dev/null %:p:S' | setl nomod<CR>", { silent = true, desc = 'Write as Sudo' })

-- Create new file
map('n', '<leader>e', [[:e <C-R>=expand("%:h")..'/'<CR>]], { noremap = true, silent = true, desc = 'New file' })

-- Combine buffers list with buffer name
map('n', '<Leader>b', ':buffers<CR>:buffer<Space>')

-- Buffer confirmation
map('n', '<leader>y', ':BufferPick<CR>')

-- Map buffer next, prev and delete to <leader>+(n/p/d) respectively
map('n', '<leader>n', ':bn<cr>')
map('n', '<leader>p', ':bp<cr>')
map('n', '<leader>d', ':bd<cr>')

-- Delete file of current buffer
map('n', '<leader>rm', "<CMD>call delete(expand('%')) | bdelete!<CR>")

-- List marks
map('n', '<Leader>m', ':marks<CR>')

-- Messages
map('n', '<Leader>M', ':messages<CR>')

--- Clear messages or just refresh/redraw the screen
map('n', '<leader>i', "<cmd>lua require('notify').dismiss()<CR>")

-- Unsets the 'last search pattern' register by hitting return
--map("n", "<CR>", "!silent :noh<CR><CR>")

-- Toggle set number
map('n', '<leader>$', ':NumbersToggle<CR>')
map('n', '<leader>%', ':NumbersOnOff<CR>')

-- Easier split navigations, just ctrl-j instead of ctrl-w then j
map('t', '<C-[>', '<C-\\><C-N>')
map('t', '<C-h>', '<C-\\><C-N><C-h>')
map('t', '<C-j>', '<C-\\><C-N><C-j>')
map('t', '<C-k>', '<C-\\><C-N><C-k>')
map('t', '<C-l>', '<C-\\><C-N><C-l>')

-- Split window
map('n', '<leader>h', ':split<CR>')
map('n', '<leader>v', ':vsplit<CR>')
map('n', '<leader>c', '<C-w>c')

-- Resize Panes
map('n', '<Leader>+', ':resize +5<CR>')
map('n', '<Leader>-', ':resize -5<CR>')
map('n', '<Leader><', ':vertical resize +5<CR>')
map('n', '<Leader>>', ':vertical resize -5<CR>')
map('n', '<Leader>=', '<C-w>=')

-- Map Alt+(h/j/k/l) in insert(include terminal/command) mode to move directional
map({ 'i', 't', 'c' }, '<A-h>', '<left>')
map({ 'i', 't', 'c' }, '<A-j>', '<down>')
map({ 'i', 't', 'c' }, '<A-k>', '<up>')
map({ 'i', 't', 'c' }, '<A-l>', '<right>')

-- Create tab, edit and move between them
map('n', '<C-T>n', ':tabnew<CR>')
map('n', '<C-T>e', ':tabedit')
map('n', '<leader>[', ':tabprev<CR>')
map('n', '<leader>]', ':tabnext<CR>')

-- "Zoom" a split window into a tab and/or close it
--map("n", "<Leader>,", ":tabnew %<CR>")
--map("n", "<Leader>.", ":tabclose<CR>")

-- Vim TABs
map('n', '<leader>1', '1gt<CR>')
map('n', '<leader>2', '2gt<CR>')
map('n', '<leader>3', '3gt<CR>')
map('n', '<leader>4', '4gt<CR>')
map('n', '<leader>5', '5gt<CR>')
map('n', '<leader>6', '6gt<CR>')
map('n', '<leader>7', '7gt<CR>')
map('n', '<leader>8', '8gt<CR>')
map('n', '<leader>9', '9gt<CR>')
map('n', '<leader>0', '10gt<CR>')

-- Hitting ESC when inside a terminal to get into normal mode
--map("t", "<Esc>", [[<C-\><C-N>]])

-- Move block (indentation) easily
map('n', '<', '<<', term_opts)
map('n', '>', '>>', term_opts)
map('x', '<', '<gv', term_opts)
map('x', '>', '>gv', term_opts)

-- Set alt+(j/k) to switch lines of texts or simply move them
map('n', '<A-k>', ':let save_a=@a<Cr><Up>"add"ap<Up>:let @a=save_a<Cr>')
map('n', '<A-j>', ':let save_a=@a<Cr>"add"ap:let @a=save_a<Cr>')

-- Toggle Diff
map('n', '<leader>df', '<Cmd>call utils#ToggleDiff()<CR>')

-- Toggle Verbose
map('n', '<leader>uvt', '<Cmd>call utils#VerboseToggle()<CR>')

-- Jump List
map('n', '<leader>j', '<Cmd>call utils#GotoJump()<CR>')

-- Rename file
map('n', '<leader>rf', '<Cmd>call utils#RenameFile()<CR>')

-- Map delete to Ctrl+l
map('i', '<C-l>', '<Del>')

-- Clear screen
map('n', '<leader><C-l>', '<Cmd>!clear<CR>')

-- Change file to an executable
map('n', '<Leader>x', ":lua require('user.mods').Toggle_executable()<CR> | :echom ('Toggle executable')<CR> | :sl! | echo ('')<CR>")
-- map("n", "<leader>x", ":!chmod +x %<CR>")

-- Paste without replace clipboard
map('v', 'p', '"_dP')

-- Swap two pieces of text, use x to cut in visual mode, then use Ctrl-x in
-- visual mode to select text to swap with
--map("v", "<C-X>", "<Esc>`.``gvP``P")

-- Change Working Directory to current project
map('n', '<leader>cd', ':cd %:p:h<CR>:pwd<CR>')

-- Open the current file in the default program (on Mac this should just be just `open`)
map('n', '<leader>o', ':!xdg-open %<cr><cr>')

-- URL handling
if vim.fn.has('mac') == 1 then
  map('', 'gx', '<Cmd>call jobstart(["open", expand("<cfile>")], {"detach": v:true})<CR>', {})
elseif vim.fn.has('unix') == 1 then
  map('', 'gx', '<Cmd>call jobstart(["xdg-open", expand("<cfile>")], {"detach": v:true})<CR>', {})
elseif vim.fn.has('wsl') == 1 then
  map('', 'gx', '<Cmd>call jobstart(["wslview", expand("<cfile>")], {"detach": v:true})<CR>', {})
else
  map[''].gx = { '<Cmd>lua print("Error: gx is not supported on this OS!")<CR>' }
end

-- Search and replace
map('v', '<leader>sr', 'y:%s/<C-r><C-r>"//g<Left><Left>c')

-- Substitute globally and locally in the selected region.
map('n', '<leader>s', ':%s//g<Left><Left>')
map('v', '<leader>s', ':s//g<Left><Left>')

-- Toggle completion
map('n', '<Leader>tc', ':lua require("user.mods").toggle_completion()<CR>')

-- Disable default completion.
map('i', '<C-n>', '<Nop>')
map('i', '<C-p>', '<Nop>')

-- Set line wrap
map('n', '<M-z>', function()
  local wrap_status = vim.api.nvim_exec('set wrap ?', true)

  if wrap_status == 'nowrap' then
    vim.api.nvim_command('set wrap linebreak')
    print('Wrap enabled')
  else
    vim.api.nvim_command('set wrap nowrap')
    print('Wrap disabled')
  end
end, { silent = true })

-- Toggle between folds
--utils.map("n", "<F2>", "&foldlevel ? 'zM' : 'zR'", { expr = true })

-- Use space to toggle fold
map('n', '<Space>', 'za')

-- Make a copy of current file
--vim.cmd([[
-- map <leader>s :up \| saveas! %:p:r-<C-R>=strftime("%y.%m.%d-%H:%M")<CR>-bak.<C-R>=expand("%:e")<CR> \| 3sleep \| e #<CR>
--]])
map('n', '<leader>.b', ':!cp % %.backup<CR>')

-- Toggle transparency
map('n', '<leader>tb', ':call utils#Toggle_transparent_background()<CR>')

-- Toggle zoom
map('n', '<leader>z', ':call utils#ZoomToggle()<CR>')
map('n', '<C-w>z', '<C-w>|<C-w>_')

-- Toggle statusline
map('n', '<leader>sl', ':call utils#ToggleHiddenAll()<CR>')

-- Open last closed buffer
map('n', '<C-t>', ':call OpenLastClosed()<CR>')

---------------- Plugin Operations ----------------
-- Packer
map('n', '<leader>Pc', '<cmd>PackerCompile<cr>')
map('n', '<leader>Pi', '<cmd>PackerInstall<cr>')
map('n', '<leader>Ps', '<cmd>PackerSync<cr>')
map('n', '<leader>PS', '<cmd>PackerStatus<cr>')
map('n', '<leader>Pu', '<cmd>PackerUpdate<cr>')

-- Tmux navigation (aserowy/tmux.nvim)
map('n', '<C-h>', '<CMD>NavigatorLeft<CR>')
map('n', '<C-l>', '<CMD>NavigatorRight<CR>')
map('n', '<C-k>', '<CMD>NavigatorUp<CR>')
map('n', '<C-j>', '<CMD>NavigatorDown<CR>')

-- ToggleTerm
map({ 'n', 't' }, '<leader>tt', '<cmd>ToggleTerm<CR>')
map({ 'n', 't' }, '<leader>th', '<cmd>lua Horizontal_term_toggle()<CR>')
map({ 'n', 't' }, '<leader>tv', '<cmd>lua Vertical_term_toggle()<CR>')

-- LazyGit
map({ 'n', 't' }, '<leader>gg', '<cmd>lua Lazygit_toggle()<CR>')

map('n', '<leader>tg', '<cmd>lua Gh_dash()<CR>')

-- Fugitive git bindings
map('n', '<leader>gs', vim.cmd.Git)
map('n', '<leader>ga', ':Git add %:p<CR><CR>')
--map("n", "<leader>gs", ":Gstatus<CR>")
map('n', '<leader>gc', ':Gcommit -v -q<CR>')
map('n', '<leader>gt', ':Gcommit -v -q %:p<CR>')
--map("n", "<leader>gd", ":Gdiff<CR>")
map('n', '<leader>ge', ':Gedit<CR>')
--map("n", "<leader>gr", ":Gread<Cj>")
map('n', '<leader>gw', ':Gwrite<CR><CR>')
map('n', '<leader>gl', ':silent! Glog<CR>:bot copen<CR>')
--map("n", "<leader>gp", ":Ggrep<Space>")
--map("n", "<Leader>gp", ":Git push<CR>")
--map("n", "<Leader>gb", ":Gblame<CR>")
map('n', '<leader>gm', ':Gmove<Space>')
--map("n", "<leader>gb", ":Git branch<Space>")
--map("n", "<leader>go", ":Git checkout<Space>")
--map("n", "<leader>gps", ":Dispatch! git push<CR>")
--map("n", "<leader>gpl", ":Dispatch! git pull<CR>")

-- Telescope
map('n', '<leader>ff', ":cd %:p:h<CR>:pwd<CR><cmd>lua require('telescope.builtin').find_files()<cr>") -- find files with hidden option
map('n', '<leader>fF', ':cd %:p:h<CR>:pwd<CR><cmd>lua require("user.mods").findFilesInCwd()<CR>', { noremap = true, silent = true, desc = 'Find files in cwd' })
map('n', '<leader>f.', function()
  require('telescope.builtin').find_files({ hidden = true, no_ignore = true })
end) -- find all files
map('n', '<leader>fg', "<cmd>lua require('telescope.builtin').live_grep()<cr>")
map('n', '<leader>fb', "<cmd>lua require('telescope.builtin').buffers()<cr>")
map('n', '<leader>fh', "<cmd>lua require('telescope.builtin').help_tags()<cr>")
map('n', '<leader>fc', "<cmd>lua require('telescope.builtin').commands()<cr>")
map('n', '<leader>cf', '<cmd>Telescope changed_files<cr>')
map('n', '<leader>fp', '<cmd>Telescope pickers<cr>')
map('n', '<leader>fd', "<cmd>lua require('telescope.builtin').diagnostics()<cr>")
map('n', '<leader>fk', "<cmd>lua require('telescope.builtin').keymaps()<cr>")
map('n', '<leader>fr', "<cmd>lua require('telescope.builtin').registers({})<CR>")                  -- registers picker
map('n', '<leader>fm', "<cmd>lua require('telescope').extensions.media_files.media_files({})<cr>") -- find media files
map('n', '<leader>fi', "<cmd>lua require('telescope').extensions.notify.notify({})<cr>")           -- find notifications
map('n', '<Leader>fs', '<cmd>lua require("session-lens").search_session()<CR>')
map('n', '<leader>ffd', [[<Cmd>lua require'plugins.telescope'.find_dirs()<CR>]])                   -- find dies
map('n', '<leader>ff.', [[<Cmd>lua require'plugins.telescope'.find_configs()<CR>]])                -- find configs
map('n', '<leader>ffs', [[<Cmd>lua require'plugins.telescope'.find_scripts()<CR>]])                -- find scripts
map('n', '<leader>ffw', [[<Cmd>lua require'plugins.telescope'.find_projects()<CR>]])               -- find projects
map('n', '<leader>ffb', [[<Cmd>lua require'plugins.telescope'.find_books()<CR>]])                  -- find books
map('n', '<leader>ffn', [[<Cmd>lua require'plugins.telescope'.find_notes()<CR>]])                  -- find notes
map('n', '<leader>fgn', [[<Cmd>lua require'plugins.telescope'.grep_notes()<CR>]])                  -- search notes
map('n', '<leader>ffp', [[<Cmd>lua require'plugins.telescope'.find_private()<CR>]])                -- search notes
map('n', '<leader>ffl', [[<Cmd>lua require'plugins.telescope'.find_logs()<CR>]])                   -- search notes
map('n', '<Leader>frf', "<cmd>lua require('telescope').extensions.recent_files.pick()<CR>")
map('n', '<leader>ffc', "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>")
map('n', '<Leader>f/', "<cmd>lua require('telescope').extensions.file_browser.file_browser()<CR>")
--map("n", "<leader>f/", "<cmd>lua require('plugins.telescope').curbuf()<cr>")                       -- find files with hidden option
-- Map a shortcut to open the picker.

-- FZF
map('n', '<leader>fz', "<cmd>lua require('fzf-lua').files()<CR>")

-- Nvim-tree
map('n', '<leader>f', '<cmd>Rooter<CR>:NvimTreeToggle<CR>', {})

-- Undotree
map('n', '<leader>u', vim.cmd.UndotreeToggle)

-- Markdown-preview
map('n', '<leader>md', '<Plug>MarkdownPreviewToggle')
map('n', '<leader>mg', '<CMD>Glow<CR>')

-- Autopairs
map('n', '<leader>ww', "<cmd>lua require('user.mods').Toggle_autopairs()<CR>")

-- Zen-mode toggle
map('n', '<leader>zm', "<CMD>ZenMode<CR> | :echom ('Zen Mode')<CR> | :sl! | echo ('')<CR>")

-- Vim-rooter
map('n', '<leader>ro', "<CMD>Rooter<CR> | :echom ('cd to root/project directory')<CR> | :sl! | echo ('')<CR>", term_opts)

-- Trouble (UI to show diagnostics)
map('n', '<leader>t', ':cd %:p:h<CR>:pwd<CR><CMD>TroubleToggle<CR>')
map('n', '<leader>tw', ':cd %:p:h<CR>:pwd<CR><CMD>TroubleToggle workspace_diagnostics<CR>')
map('n', '<leader>td', ':cd %:p:h<CR>:pwd<CR><CMD>TroubleToggle document_diagnostics<CR>')
map('n', '<leader>tq', ':cd %:p:h<CR>:pwd<CR><CMD>TroubleToggle quickfix<CR>')
map('n', '<leader>tl', ':cd %:p:h<CR>:pwd<CR><CMD>TroubleToggle loclist<CR>')
map('n', 'gR', '<CMD>TroubleToggle lsp_references<CR>')

-- Null-ls
map('n', '<leader>ls', '<CMD>NullLsToggle<CR>')

-- Replacer
map('n', '<Leader>qr', ':lua require("replacer").run()<CR>')

-- Quickfix
map('n', '<leader>q', function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    require('plugins.quickfix').close()
  else
    require('plugins.quickfix').open()
  end
end, { desc = 'Toggle quickfix window' })

-- Move to the next and previous item in the quickfixlist
map('n', ']c', '<Cmd>cnext<CR>')
map('n', '[c', '<Cmd>cprevious<CR>')

-- Location list
map('n', '<leader>l', '<cmd>lua require("plugins.loclist").loclist_toggle()<CR>')

-- Dap (debugging)
local dap_ok, dap = pcall(require, 'dap')
local dap_ui_ok, ui = pcall(require, 'dapui')

if not (dap_ok and dap_ui_ok) then
  require('notify')('nvim-dap or dap-ui not installed!', 'warning')
  return
end

vim.fn.sign_define('DapBreakpoint', { text = '🐞' })

-- Start debugging session
map('n', '<leader>ds', function()
  dap.continue()
  ui.toggle({})
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-w>=', false, true, true), 'n', false) -- Spaces buffers evenly
end)

-- Set breakpoints, get variable values, step into/out of functions, etc.
map('n', '<leader>dC', dap.continue)
-- map("n", "<leader>dC", dap.close)
-- map("n", "<leader>dt", dap.terminate)
map('n', '<leader>dt', ui.toggle)
map('n', '<leader>dd', function()
  dap.disconnect({ terminateDebuggee = true })
end)
map('n', '<leader>dn', dap.step_over)
map('n', '<leader>di', dap.step_into)
map('n', '<leader>do', dap.step_out)
map('n', '<leader>db', dap.toggle_breakpoint)
map('n', '<leader>dB', function()
  dap.clear_breakpoints()
  require('notify')('Breakpoints cleared', 'warn')
end)
map('n', '<leader>dl', require('dap.ui.widgets').hover)
map('n', '<leader>de', function()
  require('dapui').float_element()
end, { desc = 'Open Element' })
map('n', '<leader>dq', function()
  require('dapui').close()
  require('dap').repl.close()
  local session = require('dap').session()
  if session then
    require('dap').terminate()
  end
  require('nvim-dap-virtual-text').refresh()
end, { desc = 'Terminate Debug' })
map('n', '<leader>dc', function()
  require('telescope').extensions.dap.commands()
end, { desc = 'DAP-Telescope: Commands' })
--vim.keymap.set("n", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
--vim.keymap.set("v", "<leader>B", ":lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>")
--vim.keymap.set("n", "<leader>lp", ":lua require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>")
--vim.keymap.set("n", "<leader>dr", ":lua require'dap'.repl.open()<CR>")

-- Close debugger and clear breakpoints
--map("n", "<leader>de", function()
-- dap.clear_breakpoints()
-- ui.toggle({})
-- dap.terminate()
-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
-- require("notify")("Debugger session ended", "warn")
--end)

-- Toggle Dashboard
map('n', '<leader><Space>', '<CMD>lua require("user.mods").toggle_dashboard()<CR>')

-- Lsp Lines toggle
map('', '<Leader>ll', require('lsp_lines').toggle, { desc = 'Toggle lsp_lines' })

-- SnipRun
map({ 'n', 'v' }, '<leader>r', '<Plug>SnipRun<CR>')

-- Codi
map('n', '<leader>co', '<CMD>lua require("user.mods").toggleCodi()<CR>')

-- Scratch buffer
map('n', '<leader>ss', '<CMD>lua require("user.mods").Scratch("float")<CR>')
map('n', '<leader>sh', '<CMD>lua require("user.mods").Scratch("horizontal")<CR>')
map('n', '<leader>sv', '<CMD>lua require("user.mods").Scratch("vertical")<CR>')

-- Hardtime
map('n', '<leader>H', '<CMD>lua require("plugins.hardtime").ToggleHardtime()<CR>')

-- Code Run
map('n', '<leader>rr', '<CMD>lua require("user.mods").toggleCodeRunner()<CR>')

-- Run executable file
map('n', '<leader>rx', ":lua require('user.mods').RunCurrentFile()<CR>:echom 'Running executable file...'<CR>:sl!<CR>:echo ''<CR>")

-- Close all floating windows
map({ 'n', 't', 'c' }, '<leader>w', '<CMD>CloseFloatingWindows<CR>')
