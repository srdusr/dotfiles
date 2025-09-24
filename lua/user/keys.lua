-- ============================================================================
-- Key Mappings
-- ============================================================================

local map = function(mode, l, r, opts)
  if r == nil then
    vim.notify("Attempted to map key '" .. l .. "' but RHS is nil", vim.log.levels.WARN)
    return
  end
  opts = vim.tbl_extend('force', {
    silent = true,
    noremap = true
  }, opts or {})
  vim.keymap.set(mode, l, r, opts)
end

-- Leader key
vim.g.mapleader = ";"
vim.g.maplocalleader = "\\"

-- Tmux/Vim navigation
local function smart_move(direction, tmux_cmd)
  local curwin = vim.api.nvim_get_current_win()
  vim.cmd('wincmd ' .. direction)
  if curwin == vim.api.nvim_get_current_win() then
    vim.fn.system('tmux select-pane ' .. tmux_cmd)
  end
end

-- Window Navigation
map('n', '<C-h>', function() smart_move('h', '-L') end)
map('n', '<C-j>', function() smart_move('j', '-D') end)
map('n', '<C-k>', function() smart_move('k', '-U') end)
map('n', '<C-l>', function() smart_move('l', '-R') end)

-- Buffer Navigation
map('n', '<leader>bn', '<cmd>bnext<CR>')
map('n', '<leader>bp', '<cmd>bprevious<CR>')
--map('n', '<leader>bd', '<cmd>bdelete<CR>')
map('n', '<leader>ba', '<cmd>%bdelete<CR>')



-- Get list of loaded buffers in order
local function get_buffers()
    local bufs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            table.insert(bufs, buf)
        end
    end
    return bufs
end

-- Swap two buffers by index in the buffer list
local function swap_buffers(idx1, idx2)
    local bufs = get_buffers()
    local buf1 = bufs[idx1]
    local buf2 = bufs[idx2]
    if not buf1 or not buf2 then return end
    local name1 = vim.api.nvim_buf_get_name(buf1)
    local name2 = vim.api.nvim_buf_get_name(buf2)
    vim.cmd("b " .. buf1)
    vim.cmd("file " .. name2)
    vim.cmd("b " .. buf2)
    vim.cmd("file " .. name1)
end

-- Move current buffer left
vim.keymap.set("n", "<leader>bh", function()
    local bufs = get_buffers()
    local curr = vim.api.nvim_get_current_buf()
    local idx
    for i, b in ipairs(bufs) do if b == curr then idx = i break end end
    if idx and idx > 1 then
        swap_buffers(idx, idx-1)
    end
end, { noremap = true, silent = true })

-- Move current buffer right
vim.keymap.set("n", "<leader>bl", function()
    local bufs = get_buffers()
    local curr = vim.api.nvim_get_current_buf()
    local idx
    for i, b in ipairs(bufs) do if b == curr then idx = i break end end
    if idx and idx < #bufs then
        swap_buffers(idx, idx+1)
    end
end, { noremap = true, silent = true })
-- Save and Quit
map('n', '<leader>w', '<cmd>w<CR>')
map('n', '<leader>q', '<cmd>q<CR>')
map('n', '<leader>wq', '<cmd>wq<CR>')
map('n', '<leader>Q', '<cmd>qa!<CR>')

-- Resize Windows
map('n', '<M-Up>', '<cmd>resize -2<CR>')
map('n', '<M-Down>', '<cmd>resize +2<CR>')
map('n', '<M-Left>', '<cmd>vertical resize -2<CR>')
map('n', '<M-Right>', '<cmd>vertical resize +2<CR>')

-- Quickfix and Location List
map('n', ']q', '<cmd>cnext<CR>zz')
map('n', '[q', '<cmd>cprev<CR>zz')
map('n', ']l', '<cmd>lnext<CR>zz')
map('n', '[l', '<cmd>lprev<CR>zz')

-- Terminal Mode
map('t', '<Esc>', '<C-\\><C-n>')
map('t', '<C-h>', '<C-\\><C-n><C-w>h')
map('t', '<C-j>', '<C-\\><C-n><C-w>j')
map('t', '<C-k>', '<C-\\><C-n><C-w>k')
map('t', '<C-l>', '<C-\\><C-n><C-w>l')

-- Insert mode escape
map('i', 'jk', '<ESC>')

-- Tmux/(n)vim navigation
local function smart_move(direction, tmux_cmd)
	local curwin = vim.api.nvim_get_current_win()
	vim.cmd('wincmd ' .. direction)
	if curwin == vim.api.nvim_get_current_win() then
		vim.fn.system('tmux select-pane ' .. tmux_cmd)
	end
end

map('n', '<C-h>', function() smart_move('h', '-L') end, {silent = true})
map('n', '<C-j>', function() smart_move('j', '-D') end, {silent = true})
map('n', '<C-k>', function() smart_move('k', '-U') end, {silent = true})
map('n', '<C-l>', function() smart_move('l', '-R') end, {silent = true})


-- Jump to next match on line using `.` instead of `;` NOTE: commented out in favour of "ggandor/flit.nvim"
--map("n", ".", ";")

-- Repeat last command using `<Space>` instead of `.` NOTE: commented out in favour of "ggandor/flit.nvim"
--map("n", "<Space>", ".")

-- Reload nvim config
map("n", "<leader><CR>",
"<cmd>luafile ~/.config/nvim/init.lua<CR> | :echom ('Nvim config loading...') | :sl! | echo ('')<CR>")

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-b>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

--------------- Extended Operations ---------------
-- Conditional 'q' to quit on floating/quickfix/help windows otherwise still use it for macros
-- TODO: Have a list of if available on system/packages, example "Zen Mode" to not work on it (quit Zen Mode)
map("n", "q", function()
	local config = vim.api.nvim_win_get_config(0)
	if config.relative ~= "" then -- is_floating_window?
		return ":silent! close!<CR>"
	elseif vim.o.buftype == "quickfix" then
		return ":quit<CR>"
	elseif vim.o.buftype == "help" then
		return ":close<CR>"
	else
		return "q"
	end
end, { expr = true, replace_keycodes = true })

-- Minimalist Tab Completion
map("i", "<Tab>", function()
	local col = vim.fn.col('.') - 1
	local line = vim.fn.getline('.')
	local prev_char = line:sub(col, col)
	if vim.fn.pumvisible() == 1 or prev_char:match("%w") then
		return vim.api.nvim_replace_termcodes("<C-n>", true, true, true)
	else
		return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
	end
end, { expr = true })

-- Shift-Tab for reverse completion
map("i", "<S-Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return vim.api.nvim_replace_termcodes("<C-p>", true, true, true)
	else
		return vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true)
	end
end, { expr = true })


-- Toggle completion
map("n", "<Leader>tc", ':lua require("user.mods").toggle_completion()<CR>')

-- Minimalist Auto Completion
map("i", "<CR>", function()
    -- Exit this keymap if nvim-cmp is present
    local cmp_is_present, _ = pcall(require, "cmp")
    if cmp_is_present and require("cmp").visible() then
        return vim.api.nvim_replace_termcodes("<C-y>", true, true, true)
    elseif cmp_is_present then
        return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
    end

    -- when cmp is NOT present
    if vim.fn.pumvisible() == 1 then
        return vim.api.nvim_replace_termcodes("<C-y>", true, true, true)
    else
        return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
    end
end, { expr = true })

-- Closing compaction in insert mode
map("i", "[", "[]<Left>")
map("i", "(", "()<Left>")
map("i", "{", "{}<Left>")
map("i", "/*", "/**/<Left><Left>")

-- Edit new file
map("n", "<leader>e", [[:e <C-R>=expand("%:h")..'/'<CR>]], { noremap = true, silent = true, desc = "New file" })

-- Write as sudo
map("c", "W!", "exe 'w !sudo tee >/dev/null %:p:S' | setl nomod", { silent = true, desc = "Write as Sudo" })

-- Don't format on save
map("c", "F!", ":noautocmd w<CR>")

-- Combine buffers list with buffer name
map("n", "<Leader>b", ":buffers<CR>:buffer<Space>")

-- Buffer confirmation
map("n", "<leader>y", ":BufferPick<CR>")

-- Map buffer next, prev and delete to <leader>+(n/p/d) respectively and tab/s-tab
map("n", "<leader>n", ":bn<cr>")
map("n", "<leader>p", ":bp<cr>")
map("n", "<leader>d", ":bd<cr>")
map("n", "<TAB>", ":bnext<CR>")
map("n", "<S-TAB>", ":bprevious<CR>")

-- Close all buffers and reopen last one
map("n", "<leader>D", ":update | %bdelete | edit # | normal `<CR>")

-- Delete file of current buffer
map("n", "<leader>rm", "<CMD>call delete(expand('%')) | bdelete!<CR>")

-- List marks
map("n", "<Leader>M", ":marks<CR>")

-- Messages
map("n", "<Leader>m", ":messages<CR>")

--- Clear messages or just refresh/redraw the screen
map("n", "<leader>i", function()
  local ok, notify = pcall(require, "notify")
  if ok then
    notify.dismiss()
  end
end)

-- Toggle set number
map("n", "<leader>$", ":NumbersToggle<CR>")
map("n", "<leader>%", ":NumbersOnOff<CR>")

-- Easier split navigations, just ctrl-j instead of ctrl-w then j
map("t", "<C-[>", "<C-\\><C-N>")
map("t", "<C-h>", "<C-\\><C-N><C-h>")
map("t", "<C-j>", "<C-\\><C-N><C-j>")
map("t", "<C-k>", "<C-\\><C-N><C-k>")
map("t", "<C-l>", "<C-\\><C-N><C-l>")

-- Split window
map("n", "<leader>-", ":split<CR>")
map("n", "<leader>\\", ":vsplit<CR>")

-- Close window
--map("n", "<leader>c", "<C-w>c")
map({ "n", "t", "c" }, "<leader>c", function()
  local winid = vim.api.nvim_get_current_win()
  local config = vim.api.nvim_win_get_config(winid)

  if config.relative ~= "" then
    -- This is a floating window
    vim.cmd("CloseFloatingWindows")
  else
    -- Not a float/close window
    vim.cmd("close")
  end
end, { desc = "Close current float or all floating windows" })

-- Resize Panes
map("n", "<Leader><", ":vertical resize +5<CR>")
map("n", "<Leader>>", ":vertical resize -5<CR>")
map("n", "<Leader>=", "<C-w>=")

-- Mapping for left and right arrow keys in command-line mode
vim.api.nvim_set_keymap("c", "<A-h>", "<Left>", { noremap = true, silent = false })  -- Left Arrow
vim.api.nvim_set_keymap("c", "<A-l>", "<Right>", { noremap = true, silent = false }) -- Right Arrow

-- Map Alt+(h/j/k/l) in insert(include terminal/command) mode to move directional
map({ "i", "t" }, "<A-h>", "<Left>")
map({ "i", "t" }, "<A-j>", "<Down>")
map({ "i", "t" }, "<A-k>", "<Up>")
map({ "i", "t" }, "<A-l>", "<Right>")

-- Create tab, edit and move between them
map("n", "<C-T>n", ":tabnew<CR>")
map("n", "<C-T>e", ":tabedit")
map("n", "<leader>[", ":tabprev<CR>")
map("n", "<leader>]", ":tabnext<CR>")

-- Vim TABs
map("n", "<leader>1", "1gt<CR>")
map("n", "<leader>2", "2gt<CR>")
map("n", "<leader>3", "3gt<CR>")
map("n", "<leader>4", "4gt<CR>")
map("n", "<leader>5", "5gt<CR>")
map("n", "<leader>6", "6gt<CR>")
map("n", "<leader>7", "7gt<CR>")
map("n", "<leader>8", "8gt<CR>")
map("n", "<leader>9", "9gt<CR>")
map("n", "<leader>0", "10gt<CR>")

-- Hitting ESC when inside a terminal to get into normal mode
--map("t", "<Esc>", [[<C-\><C-N>]])

-- Move block (indentation) easily
--map("n", "<", "<<", term_opts)
--map("n", ">", ">>", term_opts)
--map("x", "<", "<gv", term_opts)
--map("x", ">", ">gv", term_opts)
--map("v", "<", "<gv")
--map("v", ">", ">gv")
--map("n", "<", "<S-v><<esc>change mode to normal")
--map("n", ">", "<S-v>><esc>change mode to normal")

-- Visual mode: Indent and reselect the visual area, like default behavior but explicit
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Normal mode: Indent current line and enter Visual Line mode to repeat easily
map("n", "<", "v<<", { desc = "Indent left and select" })
map("n", ">", "v>>", { desc = "Indent right and select" })

---- Visual mode: Indent and reselect the visual area, like default behavior but explicit
--map("v", "<", "<", { desc = "Indent left" })
--map("v", ">", ">", { desc = "Indent right" })
--
---- Normal mode: Indent current line and enter Visual Line mode to repeat easily
--map("n", "<", "v<<", { desc = "Indent left and select" })
--map("n", ">", "v>>", { desc = "Indent right and select" })

-- Set alt+(j/k) to switch lines of texts or simply move them
map("n", "<A-k>", ':let save_a=@a<Cr><Up>"add"ap<Up>:let @a=save_a<Cr>')
map("n", "<A-j>", ':let save_a=@a<Cr>"add"ap:let @a=save_a<Cr>')

-- Toggle Diff
map("n", "<leader>df", "<Cmd>call utils#ToggleDiff()<CR>")

-- Toggle Verbose
map("n", "<leader>uvt", "<Cmd>call utils#VerboseToggle()<CR>")

-- Jump List
map("n", "<leader>j", "<Cmd>call utils#GotoJump()<CR>")

-- Rename file
map("n", "<leader>rf", "<Cmd>call utils#RenameFile()<CR>")

-- Map delete to Ctrl+l
map("i", "<C-l>", "<Del>")

-- Clear screen
map("n", "<leader><C-l>", "<Cmd>!clear<CR>")

-- Change file to an executable
map("n", "<Leader>x",
":lua require('user.mods').Toggle_executable()<CR> | :echom ('Toggle executable')<CR> | :sl! | echo ('')<CR>")
-- map("n", "<leader>x", ":!chmod +x %<CR>")

vim.keymap.set("n", "<leader>cm", function()
  vim.cmd("redir @+")
  vim.cmd("silent messages")
  vim.cmd("redir END")
  vim.notify("Copied :messages to clipboard")
end, { desc = "Copy :messages to clipboard" })

-- Paste without replace clipboard
map("v", "p", '"_dP')

map("n", "]p", 'm`o<Esc>"+p``', opts)

map("n", "[p", 'm`O<Esc>"+p``', opts)

-- Bind Ctrl-V to paste in insert/normal/command mode
map("i", "<C-v>", "<C-G>u<C-R><C-P>+", opts)
map("n", "<C-v>", '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap("c", "<C-v>", "<C-R>=getreg('+')<CR><BS>", { noremap = true, silent = false })

-- Change Working Directory to current project
map("n", "<leader>cd", ":cd %:p:h<CR>:pwd<CR>")

-- Search and replace
map("v", "<leader>sr", 'y:%s/<C-r><C-r>"//g<Left><Left>c')

-- Substitute globally and locally in the selected region.
map("n", "<leader>s", ":%s//g<Left><Left>")
map("v", "<leader>s", ":s//g<Left><Left>")

-- Set line wrap
map("n", "<M-z>", function()
  local wrap_status = vim.api.nvim_exec("set wrap ?", true)

  if wrap_status == "nowrap" then
    vim.api.nvim_command("set wrap linebreak")
    print("Wrap enabled")
  else
    vim.api.nvim_command("set wrap nowrap")
    print("Wrap disabled")
  end
end, { silent = true })

-- Toggle between folds
map("n", "<Space>", "&foldlevel ? 'zM' : 'zR'", { expr = true })

-- Use space to toggle fold
--map("n", "<Space>", "za")

map("n", "<leader>.b", ":!cp % %.backup<CR>")

-- Go to next window
map("n", "<leader>wn", "<C-w>w", { desc = "Next window" })

-- Go to previous window
map("n", "<leader>wp", "<C-w>W", { desc = "Previous window" })

-- Toggle transparency
map("n", "<leader>tb", ":call utils#Toggle_transparent_background()<CR>")

-- Toggle zoom
map("n", "<leader>z", ":call utils#ZoomToggle()<CR>")
map("n", "<C-w>z", "<C-w>|<C-w>_")

-- Toggle statusline
map("n", "<leader>sl", ":call utils#ToggleHiddenAll()<CR>")

-- Open last closed buffer
map("n", "<C-t>", ":call utils#OpenLastClosed()<CR>")


-- Automatically set LSP keymaps when LSP attaches to a buffer
--vim.api.nvim_create_autocmd("LspAttach", {
--  callback = function(args)
--    local bufnr = args.buf
--    local opts = { buffer = bufnr }
--    map("n", "K", vim.lsp.buf.hover)
--    map("n", "gd", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>")
--    map("n", "gi", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
--    map("n", "gr", "<cmd>lua require('goto-preview').goto_preview_references()<CR>")
--    map("n", "gD", vim.lsp.buf.declaration)
--    map("n", "<leader>k", vim.lsp.buf.signature_help)
--    map("n", "gt", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>")
--    map("n", "gn", vim.lsp.buf.rename)
--    map("n", "ga", vim.lsp.buf.code_action)
--    map("n", "gf", function() vim.lsp.buf.format({ async = true }) end)
--    map("n", "go", vim.diagnostic.open_float)
--    map("n", "<leader>go", ":call utils#ToggleDiagnosticsOpenFloat()<CR> | :echom ('Toggle Diagnostics Float open/close...')<CR> | :sl! | echo ('')<CR>")
--    map("n", "gq", vim.diagnostic.setloclist)
--    map("n", "[d", vim.diagnostic.goto_prev)
--    map("n", "]d", vim.diagnostic.goto_next)
--    map("n", "gs", vim.lsp.buf.document_symbol)
--    map("n", "gw", vim.lsp.buf.workspace_symbol)
--    map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder)
--    map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder)
--    map("n", "<leader>wl", function()
--      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--    end)
--  end,
--})

---- LSP Global Keymaps (available in all buffers)
--map("n", "[d", vim.diagnostic.goto_prev, { desc = "LSP: Previous Diagnostic" })
--map("n", "]d", vim.diagnostic.goto_next, { desc = "LSP: Next Diagnostic" })
--map("n", "go", vim.diagnostic.open_float, { desc = "LSP: Open Diagnostic Float" })
--
---- LSP Buffer-local keymaps function (to be called from LSP on_attach)
--_G.setup_lsp_keymaps = function(bufnr)
--	local bmap = function(mode, l, r, opts)
--		opts = opts or {}
--		opts.silent = true
--		opts.noremap = true
--		opts.buffer = bufnr
--		vim.keymap.set(mode, l, r, opts)
--	end
--
--	bmap("n", "K", vim.lsp.buf.hover, { desc = "LSP: Hover Documentation" })
--	bmap("n", "gd", vim.lsp.buf.definition, { desc = "LSP: Go to Definition" })
--	bmap("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: Go to Declaration" })
--	bmap("n", "gi", vim.lsp.buf.implementation, { desc = "LSP: Go to Implementation" })
--	bmap("n", "gt", vim.lsp.buf.type_definition, { desc = "LSP: Go to Type Definition" })
--	bmap("n", "gr", vim.lsp.buf.references, { desc = "LSP: Go to References" })
--	bmap("n", "gn", vim.lsp.buf.rename, { desc = "LSP: Rename" })
--	bmap("n", "ga", vim.lsp.buf.code_action, { desc = "LSP: Code Action" })
--	bmap("n", "<leader>k", vim.lsp.buf.signature_help, { desc = "LSP: Signature Help" })
--	bmap("n", "gs", vim.lsp.buf.document_symbol, { desc = "LSP: Document Symbols" })
--end

-- LSP Global Keymaps (available in all buffers)
map("n", "[d", vim.diagnostic.goto_prev, { desc = "LSP: Previous Diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "LSP: Next Diagnostic" })
map("n", "go", vim.diagnostic.open_float, { desc = "LSP: Open Diagnostic Float" })
map("n", "<leader>go", ":call utils#ToggleDiagnosticsOpenFloat()<CR> | :echom ('Toggle Diagnostics Float open/close...')<CR> | :sl! | echo ('')<CR>")

-- LSP Buffer-local keymaps function (to be called from LSP on_attach)
_G.setup_lsp_keymaps = function(bufnr)
	local bmap = function(mode, l, r, opts)
		opts = opts or {}
		opts.silent = true
		opts.noremap = true
		opts.buffer = bufnr
		vim.keymap.set(mode, l, r, opts)
	end

	-- Your preferred keybindings
	bmap("n", "K", function()
		vim.lsp.buf.hover { border = "single", max_height = 25, max_width = 120 }
	end, { desc = "LSP: Hover Documentation" })

	bmap("n", "gd", function()
		vim.lsp.buf.definition {
			on_list = function(options)
				-- Custom logic to avoid showing multiple definitions for Lua patterns like:
				-- `local M.my_fn_name = function() ... end`
				local unique_defs = {}
				local def_loc_hash = {}

				for _, def_location in pairs(options.items) do
					local hash_key = def_location.filename .. def_location.lnum
					if not def_loc_hash[hash_key] then
						def_loc_hash[hash_key] = true
						table.insert(unique_defs, def_location)
					end
				end

				options.items = unique_defs
				vim.fn.setloclist(0, {}, " ", options)

				-- Open location list if multiple definitions, otherwise jump directly
				if #options.items > 1 then
					vim.cmd.lopen()
				else
					vim.cmd([[silent! lfirst]])
				end
			end,
		}
	end, { desc = "LSP: Go to Definition" })

	bmap("n", "<C-]>", vim.lsp.buf.definition, { desc = "LSP: Go to Definition (Alt)" })
	bmap("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: Go to Declaration" })
	bmap("n", "gi", vim.lsp.buf.implementation, { desc = "LSP: Go to Implementation" })
	bmap("n", "gt", vim.lsp.buf.type_definition, { desc = "LSP: Go to Type Definition" })
	bmap("n", "gr", vim.lsp.buf.references, { desc = "LSP: Go to References" })
	bmap("n", "gn", vim.lsp.buf.rename, { desc = "LSP: Rename" })
	bmap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP: Rename (Alt)" })
	bmap("n", "ga", vim.lsp.buf.code_action, { desc = "LSP: Code Action" })
	bmap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP: Code Action (Alt)" })
	bmap("n", "<leader>k", vim.lsp.buf.signature_help, { desc = "LSP: Signature Help" })
	bmap("n", "<C-k>", vim.lsp.buf.signature_help, { desc = "LSP: Signature Help (Alt)" })
	bmap("n", "gs", vim.lsp.buf.document_symbol, { desc = "LSP: Document Symbols" })

	-- Workspace folder management
	bmap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "LSP: Add Workspace Folder" })
	bmap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, { desc = "LSP: Remove Workspace Folder" })
	bmap("n", "<leader>wl", function()
		vim.print(vim.lsp.buf.list_workspace_folders())
	end, { desc = "LSP: List Workspace Folders" })
end

---------------- Plugin Operations ----------------
-- Packer
map("n", "<leader>Pc", "<cmd>PackerCompile<cr>")
map("n", "<leader>Pi", "<cmd>PackerInstall<cr>")
map("n", "<leader>Ps", "<cmd>PackerSync<cr>")
map("n", "<leader>PS", "<cmd>PackerStatus<cr>")
map("n", "<leader>Pu", "<cmd>PackerUpdate<cr>")

-- ToggleTerm
map({ "n", "t" }, "<leader>tt", "<cmd>ToggleTerm<CR>")
map({ "n", "t" }, "<leader>th", "<cmd>lua Horizontal_term_toggle()<CR>")
map({ "n", "t" }, "<leader>tv", "<cmd>lua Vertical_term_toggle()<CR>")

-- LazyGit
map({ "n", "t" }, "<leader>gg", "<cmd>lua Lazygit_toggle()<CR>")

map("n", "<leader>tg", "<cmd>lua Gh_dash()<CR>")

-- Fugitive git bindings
map("n", "<leader>gs", vim.cmd.Git)
map("n", "<leader>ga", ":Git add %:p<CR><CR>")
--map("n", "<leader>gs", ":Gstatus<CR>")
--map("n", "<leader>gc", ":Gcommit -v -q<CR>")
map("n", "<leader>gt", ":Gcommit -v -q %:p<CR>")
map("n", "<leader>gd", ":Gdiff<CR>")
map("n", "<leader>ge", ":Gedit<CR>")
--map("n", "<leader>gr", ":Gread<Cj>")
map("n", "<leader>gw", ":Gwrite<CR><CR>")
map("n", "<leader>gl", ":silent! Glog<CR>:bot copen<CR>")
--map("n", "<leader>gp", ":Ggrep<Space>")
--map("n", "<Leader>gp", ":Git push<CR>")
--map("n", "<Leader>gb", ":Gblame<CR>")
map("n", "<leader>gm", ":Gmove<Space>")
--map("n", "<leader>gb", ":Git branch<Space>")
--map("n", "<leader>go", ":Git checkout<Space>")
--map("n", "<leader>gps", ":Dispatch! git push<CR>")
--map("n", "<leader>gpl", ":Dispatch! git pull<CR>")

-- Telescope
-- Safe load of your custom Telescope module
-- This initial pcall for "plugins.telescope" is fine because it just checks if YOUR module is there.
-- The actual checks for Telescope's core modules happen *inside* your wrapper functions when called.
local telescope_ok, telescope_module = pcall(require, "plugins.telescope")

if telescope_ok and telescope_module then

  -- Direct function calls from your plugins.telescope module
  -- M.safe_find_files handles its own internal `builtin` check
  map("n", "<leader>ff", telescope_module.safe_find_files, { desc = "Find files" })

  -- For `find all files`, use your `safe_telescope_builtin` wrapper
  -- You need to wrap it in a function to pass the options correctly.
  map("n", "<leader>f.", function()
    telescope_module.safe_telescope_builtin("find_files")({ hidden = true, no_ignore = true })
  end, { desc = "Find all files" })


  ---
  --- Built-in Telescope functions
  --- Note: safe_telescope_builtin returns a function, so you map directly to it.
  ---
  map("n", "<leader>fg", function() telescope_module.safe_telescope_builtin("live_grep")() end, { desc = "Live grep" })
  map("n", "<leader>fb", function() telescope_module.safe_telescope_builtin("buffers")() end, { desc = "Find buffers" })
  map("n", "<leader>fh", function() telescope_module.safe_telescope_builtin("help_tags")() end, { desc = "Help tags" })
  map("n", "<leader>fc", function() telescope_module.safe_telescope_builtin("commands")() end, { desc = "Commands" })
  map("n", "<leader>fd", function() telescope_module.safe_telescope_builtin("diagnostics")() end, { desc = "Diagnostics" })
  map("n", "<leader>fk", function() telescope_module.safe_telescope_builtin("keymaps")() end, { desc = "Keymaps" })
  map("n", "<leader>fr", function() telescope_module.safe_telescope_builtin("registers")() end, { desc = "Registers" })
  map("n", "<leader>ffc", function() telescope_module.safe_telescope_builtin("current_buffer_fuzzy_find")() end, { desc = "Current buffer fuzzy find" })
  -- Corrected the previous `fp` mapping that pointed to `pickers`
  map("n", "<leader>fp", function() telescope_module.safe_telescope_builtin("oldfiles")() end, { desc = "Recently opened files" })


  ---
  --- Telescope Extension functions
  --- Note: safe_telescope_extension returns a function, so you map directly to it.
  ---
  map("n", "<leader>cf", function() telescope_module.safe_telescope_extension("changed_files", "changed_files")() end, { desc = "Changed files" })
  map("n", "<leader>fm", function() telescope_module.safe_telescope_extension("media_files", "media_files")() end, { desc = "Media files" })
  map("n", "<leader>fi", function() telescope_module.safe_telescope_extension("notify", "notify")() end, { desc = "Notifications" })
  map("n", "<Leader>fs", function() telescope_module.safe_telescope_extension("session-lens", "search_session")() end, { desc = "Search sessions" })
  map("n", "<Leader>frf", function() telescope_module.safe_telescope_extension("recent_files", "pick")() end, { desc = "Recent files" })
  map("n", "<Leader>f/", function() telescope_module.safe_telescope_extension("file_browser", "file_browser")() end, { desc = "File browser" })


  ---
  --- Custom functions defined in plugins.telescope.lua
  --- Note: safe_telescope_call returns a function, so you map directly to it.
  --- (These were already correct as safe_telescope_call returns a callable function)
  ---
  map("n", "<leader>ffd", telescope_module.safe_telescope_call("plugins.telescope", "find_dirs"), { desc = "Find directories" })
  map("n", "<leader>ff.", telescope_module.safe_telescope_call("plugins.telescope", "find_configs"), { desc = "Find configs" })
  map("n", "<leader>ffs", telescope_module.safe_telescope_call("plugins.telescope", "find_scripts"), { desc = "Find scripts" })
  map("n", "<leader>ffw", telescope_module.safe_telescope_call("plugins.telescope", "find_projects"), { desc = "Find projects" })
  map("n", "<leader>ffB", telescope_module.safe_telescope_call("plugins.telescope", "find_books"), { desc = "Find books" })
  map("n", "<leader>ffn", telescope_module.safe_telescope_call("plugins.telescope", "find_notes"), { desc = "Find notes" })
  map("n", "<leader>fgn", telescope_module.safe_telescope_call("plugins.telescope", "grep_notes"), { desc = "Grep notes" })
  map("n", "<leader>fpp", telescope_module.safe_telescope_call("plugins.telescope", "find_private"), { desc = "Find private notes" })
  map("n", "<leader>fgc", telescope_module.safe_telescope_call("plugins.telescope", "grep_current_dir"), { desc = "Grep current directory" })

end
---- Fallback keymaps when telescope is not available
--map("n", "<leader>ff", function()
--  local file = vim.fn.input("Open file: ", "", "file")
--  if file ~= "" then
--    vim.cmd("edit " .. file)
--  end
--end, { desc = "Find files (fallback)" })

---- You can add other basic fallbacks here
--map("n", "<leader>fg", function()
--	vim.notify("Live grep requires telescope plugin", vim.log.levels.WARN)
--end, { desc = "Live grep (unavailable)" })
----end


map("n", "<leader>fF", ":cd %:p:h<CR>:pwd<CR><cmd>lua require('user.mods').findFilesInCwd()<CR>",
{ noremap = true, silent = true, desc = "Find files in cwd" })

-- FZF
map("n", "<leader>fz", function()
	local ok, fzf_lua = pcall(require, "fzf-lua")
	if ok then
		fzf_lua.files() -- no config, just open
	else
		local handle = io.popen("find . -type f | fzf")
		if handle then
			local result = handle:read("*a")
			handle:close()
			result = result:gsub("\n", "")
			if result ~= "" then
				vim.cmd("edit " .. vim.fn.fnameescape(result))
			end
		else
			vim.notify("fzf not found or failed to run", vim.log.levels.ERROR)
		end
	end
end, { desc = "FZF file picker (fzf-lua or fallback)" })

map("n", "gA", ":FzfLua lsp_code_actions<CR>")

-- Nvim-tree
local function safe_nvim_tree_toggle()
	local ok_tree, tree_api = pcall(require, "nvim-tree.api")
	if ok_tree then
		pcall(vim.cmd, "Rooter")  -- silently run Rooter if available
		tree_api.tree.toggle()
	else
		-- Fallback to netrw
		local cur_buf = vim.api.nvim_get_current_buf()
		local ft = vim.api.nvim_get_option_value("filetype", { buf = cur_buf })

		if ft == "netrw" then
			vim.cmd("close")
		else
			vim.cmd("Lexplore")
		end
	end
end

map("n", "<leader>f", safe_nvim_tree_toggle, { desc = "Toggle file explorer" })

-- Undotree
map("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Markdown-preview
map("n", "<leader>md", "<Plug>MarkdownPreviewToggle")
map("n", "<leader>mg", "<CMD>Glow<CR>")

-- Autopairs
map("n", "<leader>ww", "<cmd>lua require('user.mods').Toggle_autopairs()<CR>")

-- Zen-mode toggle
map("n", "<leader>zm", "<CMD>ZenMode<CR> | :echom ('Zen Mode')<CR> | :sl! | echo ('')<CR>")

-- Vim-rooter
local function safe_project_root()
	if vim.fn.exists(":Rooter") == 2 then
		vim.cmd("Rooter")
	else
		vim.cmd("cd %:p:h")
	end
end
vim.keymap.set("n", "<leader>ro", safe_project_root, { desc = "Project root" })

-- Trouble (UI to show diagnostics)
local function safe_trouble_toggle(view, opts)
	local ok, _ = pcall(require, "trouble")
	if ok then
		local cmd = "Trouble"
		if view then
			cmd = cmd .. " " .. view .. " toggle"
			if opts then
				cmd = cmd .. " " .. opts
			end
		else
			cmd = cmd .. " diagnostics toggle"
		end
		vim.cmd(cmd)
	else
		vim.cmd("copen")
	end
end

-- Replace 'map' with 'vim.keymap.set' if not already a global alias
vim.keymap.set("n", "<leader>t", function()
	safe_trouble_toggle()
end, { desc = "Diagnostics (Workspace)" })

vim.keymap.set("n", "<leader>tw", function()
	vim.cmd("cd %:p:h | pwd")
	safe_trouble_toggle("diagnostics")
end, { desc = "Diagnostics (Workspace)" })

vim.keymap.set("n", "<leader>td", function()
	vim.cmd("cd %:p:h | pwd")
	safe_trouble_toggle("diagnostics", "filter.buf=0")
end, { desc = "Diagnostics (Buffer)" })

vim.keymap.set("n", "<leader>tq", function()
	vim.cmd("cd %:p:h | pwd")
	safe_trouble_toggle("qflist")
end, { desc = "Quickfix List" })

vim.keymap.set("n", "<leader>tl", function()
	vim.cmd("cd %:p:h | pwd")
	safe_trouble_toggle("loclist")
end, { desc = "Location List" })

vim.keymap.set("n", "gR", function()
	safe_trouble_toggle("lsp")
end, { desc = "LSP References/Definitions" })

-- Null-ls
map("n", "<leader>ls", ':lua require("null-ls").toggle({})<CR>')


-- Replacer
map("n", "<Leader>qr", ':lua require("replacer").run()<CR>')

-- Quickfix
map("n", "<leader>q", function()
	if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
		require("plugins.quickfix").close()
	else
		require("plugins.quickfix").open()
	end
end, { desc = "Toggle quickfix window" })

-- Move to the next and previous item in the quickfixlist
map("n", "]c", "<Cmd>cnext<CR>")
map("n", "[c", "<Cmd>cprevious<CR>")

-- Location list
map("n", "<leader>l", '<cmd>lua require("plugins.loclist").loclist_toggle()<CR>')

-- Dap (debugging)
local dap_ok, dap = pcall(require, "dap")
local dap_ui_ok, ui = pcall(require, "dapui")

if not (dap_ok and dap_ui_ok) then
	--require("notify")("nvim-dap or dap-ui not installed!", "warning")
	return
end

vim.fn.sign_define("DapBreakpoint", { text = "🐞" })

-- Start debugging session
map("n", "<leader>ds", function()
	dap.continue()
	ui.toggle({})
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false) -- Spaces buffers evenly
end)

-- Set breakpoints, get variable values, step into/out of functions, etc.
map("n", "<leader>dC", dap.continue)
-- map("n", "<leader>dC", dap.close)
-- map("n", "<leader>dt", dap.terminate)
map("n", "<leader>dt", ui.toggle)
map("n", "<leader>dd", function()
	dap.disconnect({ terminateDebuggee = true })
end)
map("n", "<leader>dn", dap.step_over)
map("n", "<leader>di", dap.step_into)
map("n", "<leader>do", dap.step_out)
map("n", "<leader>db", dap.toggle_breakpoint)
map("n", "<leader>dB", function()
	dap.clear_breakpoints()
	require("notify")("Breakpoints cleared", "warn")
end)
map("n", "<leader>dl", function()
	local ok, dap_widgets = pcall(require, "dap.ui.widgets")
	if ok then dap_widgets.hover() end
end)
map("n", "<leader>de", function()
	require("dapui").float_element()
end, { desc = "Open Element" })
map("n", "<leader>dq", function()
	require("dapui").close()
	require("dap").repl.close()
	local session = require("dap").session()
	if session then
		require("dap").terminate()
	end
	require("nvim-dap-virtual-text").refresh()
end, { desc = "Terminate Debug" })
map("n", "<leader>dc", function()
	require("telescope").extensions.dap.commands()
end, { desc = "DAP-Telescope: Commands" })
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
map("n", "<leader><Space>", '<CMD>lua require("user.mods").toggle_dashboard()<CR>')

-- Lsp Lines toggle
map("", "<Leader>ll", require("lsp_lines").toggle, { desc = "Toggle lsp_lines" })

-- SnipRun
map({ "n", "v" }, "<leader>r", "<Plug>SnipRun<CR>")

-- Codi
map("n", "<leader>co", '<CMD>lua require("user.mods").toggleCodi()<CR>')

-- Scratch buffer
map("n", "<leader>ss", '<CMD>lua require("user.mods").Scratch("float")<CR>')
map("n", "<leader>sh", '<CMD>lua require("user.mods").Scratch("horizontal")<CR>')
map("n", "<leader>sv", '<CMD>lua require("user.mods").Scratch("vertical")<CR>')

-- Hardtime
map("n", "<leader>H", '<CMD>lua require("plugins.hardtime").ToggleHardtime()<CR>')

-- Code Run
map("n", "<leader>rr", '<CMD>lua require("user.mods").toggleCodeRunner()<CR>')

-- Run executable file
map("n", "<leader>rx",
":lua require('user.mods').RunCurrentFile()<CR>:echom 'Running executable file...'<CR>:sl!<CR>:echo ''<CR>")

-- Set Files to current location as dir
map({ "n" }, "<leader>cf", "<CMD>e %:h<CR>")

-- Vimtex
map("n", "<Leader>lc", ":VimtexCompile<cr>")
map("v", "<Leader>ls", ":VimtexCompileSelected<cr>")
map("n", "<Leader>li", ":VimtexInfo<cr>")
map("n", "<Leader>lt", ":VimtexTocToggle<cr>")
map("n", "<Leader>lv", ":VimtexView<cr>")
