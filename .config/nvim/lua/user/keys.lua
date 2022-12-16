--[[ key.lua ]]

-- Shorten function name
--local keymap = vim.api.nvim_set_keymap
local keymap = vim.keymap

--local function new_desc(d)
--  return { desc = d }
--end
--
--local d = new_desc

--local opts = { noremap = true, silent = true }
local term_opts = { noremap = true, silent = false }
	local map = function(mode, l, r, opts)
		opts = opts or {}
		opts.silent = true
    opts.noremap = true
		keymap.set(mode, l, r, opts)
	end


--------------- Standard Operations ---------------
-- Semi-colon as leader key
vim.g.mapleader = ";"
--vim.g.maplocalleader = ";"

-- "jj" to exit insert-mode
map("i", "jk", "<esc>")

map("n", "<leader>m", ":messages<CR>")
map("n", "<leader>cd", ":cd %:p:h<CR>:pwd<CR>")
-- Print last error message or use these commands | v:errmsgv | :statusmsg | :h execute() |
--nnoremap <silent><leader>x :put =trim(execute(input(':', '', 'command')))<CR>
-- Press <leader>x, then enter your command, such as 5mess and press <Enter>. The last five message lines will be added to the current buffer.
-- useful to copy error message when vim start

-- save quickly
--map("n", ";w", ":w<CR>", d("Save buffer"))

--map("n", "<leader>so", ":luafile %<CR>")

--vim.cmd([[
--let $my_vimrc = $localappdata.'/nvim/init.lua'
--nnoremap <leader>so :source $my_vimrc<cr>
--]])

-- Toggle between folds
--utils.map("n", "<F2>", "&foldlevel ? 'zM' : 'zR'", { expr = true })

-- Move to the next and previous item in the quickfixlist
--utils.map("n", "]c", "<Cmd>cnext<CR>")
--utils.map("n", "[c", "<Cmd>cprevious<CR>")

-- Use space to toggle fold
--utils.map("n", "<Space>", "za")

-- Hitting ESC when inside a terminal to get into normal mode
--utils.map("t", "<Esc>", [[<C-\><C-N>]])

-- select last change
--nnoremap gV `[v`]

--map("n", "<esc>", function()
--  notify.dismiss()
--  vim.cmd.noh()
--end)

--"nnore fast [e]dit and [s]ourcing .[v]imrc
--nnoremap <leader>ev :edit $MYVIMRC<CR>
--"fast macro
--nnoremap @ <cmd>set lazyredraw <bar> execute 'noautocmd norm! ' . v:count1 . '@' . getcharstr() <bar> set nolazyredraw<cr>
--xnoremap @ :<C-U>set lazyredraw <bar> execute "noautocmd '<,'>norm! " . v:count1 . "@" . getcharstr()<bar> set nolazyredraw<cr>

--map("n", "<leader><CR>", ":runtime! /lua/plugins/*.lua<CR> | :runtime! /lua/user/*.lua<CR> | :luafile ~/.config/nvim/init.lua<CR>", print ("Nvim reloaded"))
--map("n", "<leader><CR>", ":lua require('init').unload_lua_namespace()<CR>", print ("Nvim reloaded"))
--map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR>", vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO))
--map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR> | :lua require("notify")("completion off")")
--map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR>", vim.api.nvim_echo({{'first chunk and ', 'None'}, {'second chunk to echo', 'None'}}, false, {}))
--map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR>", print ("Nvim config loading..."))
--map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR> | :echo ('hello') | <C-l><CR>")
map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR> | :echom ('Nvim config loading...') | :sl! | echo ('')<CR>")
map("n", "<leader>u", ":echo '' | redraw<CR>") --clear messages
--map("n", "<leader><CR>", "<cmd>luafile ~/.config/nvim/init.lua<CR>")
--vim.api.nvim_set_keymap("n", "<leader><CR>", "<cmd>lua ReloadConfig()<CR>", { noremap = true, silent = false })

map("n", "<Leader>tc", ":lua require('user.utils').toggle_completion()<CR>")
--  vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)

--vim.api.nvim_set_keymap('n', '<Leader>qr',  '<cmd>:lua require("plugins.telescope").reload()<CR>', { noremap = true, silent = true })

--Easier split navigations, just ctrl-j instead of ctrl-w then j
map("n", "<C-J>", "<C-W><C-J>")
map("n", "<C-K>", "<C-W><C-K>")
map("n", "<C-L>", "<C-W><C-L>")
map("n", "<C-H>", "<C-W><C-H>")

-- Combine buffers list with buffer name
map("n", "<Leader>b", ":buffers<CR>:buffer<Space>")
--map("n", "<leader>b", ":ls<cr>:b<space>")

-- Map buffer next, prev and delete to <leader+(n/p/d)>
map("n", "<leader>n", ":bn<cr>")
map("n", "<leader>p", ":bp<cr>")
map("n", "<leader>d", ":bd<cr>")

-- Disable default completion.
map('i', '<C-n>', '<Nop>')
map('i', '<C-p>', '<Nop>')

-- Set alt + j/k to switch lines of texts or simply move them
map("n", "<A-k>", ':let save_a=@a<Cr><Up>"add"ap<Up>:let @a=save_a<Cr>')
map("n", "<A-j>", ':let save_a=@a<Cr>"add"ap:let @a=save_a<Cr>')

map("i", "<C-l>", "<Del>")

map("n", "<leader><C-l>", "<Cmd>!clear<CR>")

map("n", "<leader>y", ":BufferPick<CR>")

vim.cmd([[
  inoremap <A-h> <left>
  inoremap <A-j> <down>
  inoremap <A-k> <up>
  inoremap <A-l> <right>
]])

vim.cmd([[
  cnoremap <A-h> <left>
  cnoremap <A-j> <down>
  cnoremap <A-k> <up>
  cnoremap <A-l> <right>
]])

--vim.cmd([[
--  cnoremap <C-A> <Home>
--  cnoremap <C-F> <Right>
--  cnoremap <C-B> <Left>
--  cnoremap <C-E> <End>
--]])

vim.cmd([[
  snoremap <A-h> <left>
  snoremap <A-j> <down>
  snoremap <A-k> <up>
  snoremap <A-l> <right>
]])

-- move block easily
map("n", "<", "<<", term_opts)
map("n", ">", ">>", term_opts)
map("x", "<", "<gv", term_opts)
map("x", ">", ">gv", term_opts)

-- Resize Panes
map("n", "<Leader>+", ":resize +5<CR>")
map("n", "<Leader>-", ":resize -5<CR>")
map("n", "<Leader><", ":vertical resize +5<CR>")
map("n", "<Leader>>", ":vertical resize -5<CR>")
map("n", "<Leader>=", "<C-w>=")

-- New tab
map("n", "<C-T>e", ":tabedit")

-- create tab like window
map("n", "<C-T>h", ":tabprevious<CR>")
map("n", "<C-T>l", ":tabnext<CR>")
map("n", "<C-T>n", ":tabnew<CR>")

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

-- Split window
map("n", "<leader>h", ":split<CR>")
map("n", "<leader>v", ":vsplit<CR>")
map("n", "<leader>c", "<C-w>c")

-- Toggle set number
map("n", "<leader>$", ":NumbersToggle<CR>")
map("n", "<leader>%", ":NumbersOnOff<CR>")

-- Change mode to executable
map("n", "<leader>x", ":!chmod +x %<CR>")

-- Paste without replace clipboard
map("v", "p", '"_dP')

-- Paste end of line
--map("n", ",", "$p")
--vim.cmd([[
--  nmap , $p
--]])

-- Select entire buffer
--map("v", "<aa>", "gg<S-v>G")

-- Delete without changing the registers
--map('n', 'x', '"_x')

-- Select all text in current buffer
--map('n', '<leader>a', ':keepjumps normal! ggVG<cr>')

-- Swap two pieces of text, use x to cut in visual mode, then use Ctrl-x in
-- visual mode to select text to swap with
map("v", "<C-X>", "<Esc>`.``gvP``P")

-- Keep Visual mode selection when indenting text
--utils.map("x", ">", ">gv")
--utils.map("x", "<", "<gv")

-- Make visual pasting a word to not update the unnamed register
-- Thus, allowing us to repeatedly paste the word. {"_ : black-hole register}
--utils.map("v", "p", [["_dP]])

-- Whole-word search
--utils.map("n", "<leader>/", ":/\\<\\><Left><Left>", { silent = false })

-- EasyAlign keybindings
-- 'vipga' starts interactive EasyAlign in visual mode
-- 'gaip' starts interactive EasyAlign for text/motion object
--utils.map({ "n", "x" }, "ga", "<Plug>(EasyAlign)")
--utils.map({ "n", "x" }, "<leader>ga", "<Plug>(LiveEasyAlign)")

-- Set a mark when moving more than 5 lines upwards/downards
-- this will populate the jumplist enabling us to jump back with Ctrl-O
--utils.map("n", "k", [[(v:count > 5 ? "m'" . v:count : "") . 'k']], { expr = true })
--utils.map("n", "j", [[(v:count > 5 ? "m'" . v:count : "") . 'j']], { expr = true })

-- Zoom toggle a buffer in a new tab
--utils.map("n", "<leader>z", function()
--    require("tt.helper").zoomToggleNewTab()
--end, { desc = "Zoom toggle a buffer in a new tab" })

-- Hitting ESC when inside a terminal to get into normal mode
--utils.map("t", "<Esc>", [[<C-\><C-N>]])

-- markdown-preview
map("n", "<leader>md", "<Plug>MarkdownPreviewToggle")


-- Search and replace
map("v", "<leader>sr", 'y:%s/<C-r><C-r>"//g<Left><Left>c')
--vnoremap ; :call Get_visual_selection()<cr>
--
--function! Get_visual_selection()
--  " Why is this not a built-in Vim script function?!
--  let [lnum1, col1] = getpos("'<")[1:2]
--  let [lnum2, col2] = getpos("'>")[1:2]
--  let lines = getline(lnum1, lnum2)
--  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
--  let lines[0] = lines[0][col1 - 1:]
--  let selection = join(lines,'\n')
--  let change = input('Change the selection with: ')
--  execute ":%s/".selection."/".change."/g"
--endfunction
vim.cmd([[
let s:hidden_all = 0
function! ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction
nnoremap <S-h> :call ToggleHiddenAll()<CR>
]])

vim.cmd([[
  map <leader>s :up \| saveas! %:p:r-<C-R>=strftime("%y.%m.%d-%H:%M")<CR>-bak.<C-R>=expand("%:e")<CR> \| 3sleep \| e #<CR>
]])

-- Execute this file
--map("n", "<leader><leader>x", ":call scripts#save_and_exec()<CR>", print("save & exec"))
vim.cmd([[
  " Execute this file
  nnoremap <leader><leader>x :call scripts#save_and_exec()<CR>\|:echom "save & exec . . ."<CR>

]])

-------------- FZF --------------
map("n", "<leader>fz", "<cmd>lua require('fzf-lua').files()<CR>")

-------------- Telescope --------------
--Telescope find_files cwd=..
map("n", "<leader>fc", "<cmd>lua require('telescope.builtin').commands()<cr>")
map("n", "<leader>cf", "<cmd>Telescope changed_files<cr>")
map("n", "<leader>fk", "<cmd>lua require('telescope.builtin').keymaps()<cr>")
map("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>")
--map(
--	"n",
--	"<leader>ft",
--	"<cmd>lua require('telescope.builtin').builtin(require('telescope.themes').get_dropdown({}))<cr>")

--  maps.n["<leader>fF"] = {
--    function() require("telescope.builtin").find_files { hidden = true, no_ignore = true } end,
--    desc = "Search all files",
--    <cmd>Telescope find_files hidden=true<cr>
--map("n", "<leader>fh", "<cme>lua require('telecsope.builtin').file_files hidden=true<cr>")
map("n", "<leader>fF", function() require("telescope.builtin").find_files { hidden = true, no_ignore = true } end)
--map("n", "<leader>fe", ":lua require('telescope.builtin').file_browser({cwd = '.'})<CR>")
map("n", "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>")
map("n", "<leader>fb", "<cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<cr>")
map("n", "<leader>fd", "<cmd>lua require('telescope.builtin').diagnostics()<cr>")
map("n", "<leader>fp", "<cmd>Telescope pickers<cr>")

-- find notes
map("n", "<leader>fn", [[<Cmd>lua require'plugins.telescope'.find_notes()<CR>]])
-- search notes
map("n", "<leader>fgn", [[<Cmd>lua require'plugins.telescope'.grep_notes()<CR>]])
-- Find files in config dirs
map("n", "<leader>f.", [[<Cmd>lua require'plugins.telescope'.find_configs()<CR>]])
--map("n", "<leader>fz", ":FZF<CR>")
--map("t", [[<Esc><Esc>]], [[<C-\><C-N>]])
--map("n", "ff", ":NvimTreeToggle<CR>", {})
map("n", "<leader>f", ":NvimTreeToggle<CR>", {})
--  This <Esc><Esc> avoids crashing fzf menu running in TERMINAL MODE (:q if you do)
-- Find files in config dirs
--key_map("n", "<leader>e", ":lua require('plugins.telescope').find_configs()<CR>",  opts)
--map("n", "<leader>f.", "<cmd>lua require('plugins.telescope').find_configs({})<cr>")
--map("n", "<leader>ft", "<cmd>lua require('plugins.telescope').file_explorer({})<cr>")
--map("n", "<leader>fd", "<cmd>lua require('plugins.telescope').find_notes({})<cr>")
map("n", "<leader>fm", "<cmd>lua require('telescope').extensions.media_files.media_files({})<cr>")
-- registers picker
map("n", "<leader>r", "<cmd>lua require('telescope.builtin').registers({})<CR>")
-- find files including gitignored
--keymap(
--  "n",
--  "<leader>fg",
--  "<cmd>lua require('telescope.builtin').find_files({find_command={'fd','--no-ignore-vcs'}})<CR>")
-- open available commands & run it
--map("n", "<leader>fc", "<cmd>lua require('telescope.builtin').commands({results_title='Commands Results'})<CR>")

-------------- Autopairs --------------
Toggle_autopairs = function()
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
map("n", "<leader>ww", ":lua Toggle_autopairs()<CR>", term_opts)

-------------- Functions --------------
-- Toggle transparency
vim.cmd([[
  let t:is_transparent = 0
  function! Toggle_transparent_background()
    if t:is_transparent == 0
      hi Normal guibg=#111111 ctermbg=black
      let t:is_transparent = 1
    else
      hi Normal guibg=NONE ctermbg=NONE
      let t:is_transparent = 0
    endif
  endfunction
  nnoremap <leader>tb :call Toggle_transparent_background()<CR>
]])
--keymap('n', '<leader>tb', ':Toggle_transparent_background<CR>')

-- Toggle zoom
vim.cmd([[
  function! s:ZoomToggle() abort
      if exists('t:zoomed') && t:zoomed
          execute t:zoom_winrestcmd
          let t:zoomed = 0
      else
          let t:zoom_winrestcmd = winrestcmd()
          resize
          vertical resize
          let t:zoomed = 1
      endif
  endfunction
  command! ZoomToggle call s:ZoomToggle()
 ]])
map("n", "<leader>z", ":ZoomToggle<CR>")
-- "Zoom" a split window into a tab and/or close it
--keymap('n', '<Leader>,', ':tabnew %<CR>')
--keymap('n', '<Leader>.', ':tabclose<CR>')

-- Open last closed buffer
vim.cmd([[
  function! OpenLastClosed()
      let last_buf = bufname('#')
      if empty(last_buf)
          echo "No recently closed buffer found"
          return
      endif
      let result = input("Open ". last_buf . " in (n)ormal (v)split, (t)ab or (s)plit ? (n/v/t/s) : ")
      if empty(result) || (result !=# 'v' && result !=# 't' && result !=# 's' && result !=# 'n')
          return
      endif
      if result ==# 't'
          execute 'tabnew'
      elseif result ==# 'v'
          execute "vsplit"
      elseif result ==# 's'
          execute "split"
      endif
      execute 'b ' . last_buf
  endfunction
 ]])
map("n", "<C-t>", ":call OpenLastClosed() <CR>")

-- Tabularize
vim.cmd([[
  vnoremap <expr> <Leader>mm ':Tabularize /^\s*\S.*\zs' . split(&commentstring, '%s')[0] . "<CR>"
  nnoremap <expr> <Leader>mm ':Tabularize /^\s*\S.*\zs' . split(&commentstring, '%s')[0] . "<CR>"
  "nnoremap <leader>i mc40A <esc>080lDgelD`cP
  "vnoremap <leader>ii mc0f-20i<Space><Esc>`cdt=j
]])

vim.cmd([[
  " Start interactive EasyAlign in visual mode (e.g. vipga)
  xmap ga <Plug>(EasyAlign)
  " Start interactive EasyAlign for a motion/text object (e.g. gaip)
  nmap ga <Plug>(EasyAlign)
  if !exists('g:easy_align_delimiters')
    let g:easy_align_delimiters = {}
  endif
  let g:easy_align_delimiters['--'] = { 'pattern': '--', 'ignore_groups': ['String'] }
  nnoremap <F1> 21A <Esc>d21\|
  imap <F1> <Esc><F1>a
]])
--:'<,'>EasyAlign /--/
--EasyAlign /--/
--:'<,'>Tabularize /--

--map("n", "<leader>,", ":hide<CR>")
--map("n", "<leader>.", ":unhide<CR>")

--" Clean trailing whitespace
--nnoremap <leader>ww mz:%s/\s\+$//<cr>:let @/=''<cr>`z

-- Save with root permission (not working for now)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

-- Copy and Paste with <C-c> and <C-v>
--keymap('n', '<expr> p', (v:register =--= '"' && &clipboard =~ 'unnamed' ? '"*p' : '"' . v:register . 'p')'')
-- Use command :Vb for Visual Block or <C-q> since <C-v> is used for Copy
--command! Vb normal! <C-v>
-- Map <w!!> to save/edit a root permission/read-only file, only works in
-- traditional vim and not neovim
--keymap('c', 'w!! %!sudo tee > /dev/null')
--" Copying text to the system clipboard.
--"
--" For some reason Vim no longer wants to talk to the OS X pasteboard through "*.
--" Computers are bullshit.
--function! g:FuckingCopyTheTextPlease()
--    let old_z = @z
--    normal! gv"zy
--    call system('pbcopy', @z)
--    let @z = old_z
--endfunction
--noremap <leader>p :silent! set paste<CR>"*p:set nopaste<CR>
--" noremap <leader>p mz:r!pbpaste<cr>`z
--vnoremap <leader>y :<c-u>call g:FuckingCopyTheTextPlease()<cr>

--" Indent/dedent/autoindent what you just pasted.
--nnoremap <lt>> V`]<
--nnoremap ><lt> V`]>
--nnoremap =- V`]=

--" Keep the cursor in place while joining lines
--nnoremap J mzJ`z

--" Toggle [i]nvisible characters
--nnoremap <leader>i :set list!<cr>
--
--" Unfuck my screen
--nnoremap U :syntax sync fromstart<cr>:redraw!<cr>

--" Ranger
--nnoremap <leader>r :silent !ranger %:h<cr>:redraw!<cr>
--nnoremap <leader>R :silent !ranger<cr>:redraw!<cr>
--
--" Insert Mode Completion {{{
--
--inoremap <c-f> <c-x><c-f>
--inoremap <c-]> <c-x><c-]>
--inoremap <c-l> <c-x><c-l>
---- Open the current file in the default program (on Mac this should just be just `open`)
--keymap('n', '<leader>x', ':!xdg-open %<cr><cr>')

map("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>")
--keymap("n", "<leader>ff", "<cmd>lua require('telescope.builtin').find_files cwd=..()<cr>")
--keymap('n', '<leader>k', ':nohlsearch<CR>')
--
--"This unsets the "last search pattern" register by hitting return
vim.cmd([[
  nnoremap <silent> <CR> :noh<CR><CR>
]])

--keymap('n', '<leader>Q', ':bufdo bdelete<CR>')
--
---- Allow gf to open non-existent files
--keymap('', 'gf', ':edit <cfile><CR>')
--
---- Reselect visual selection after indenting
--keymap('v', '<', '<gv')
--keymap('v', '>', '>gv')
--
---- Maintain the cursor position when yanking a visual selection
---- http://ddrscott.github.io/blog/2016/yank-without-jank/
--keymap('v', 'y', 'myy`y')
--keymap('v', 'Y', 'myY`y')
--keymap("n", "<C-q>", ":q<cr>")
--keymap("n", "<C-M-q>", ":qa!<cr>")

--" Sort lines
--nnoremap <leader>s vip:!sort<cr>
--vnoremap <leader>s :!sort<cr>
--
--" Tabs
--nnoremap <leader>( :tabprev<cr>
--nnoremap <leader>) :tabnext<cr>
--
--" Wrap
--nnoremap <leader>W :set wrap!<cr>

--set foldlevelstart=0
--
--" Space to toggle folds.
--nnoremap <Space> za
--vnoremap <Space> za
--" Make zO recursively open whatever fold we're in, even if it's partially open.
--nnoremap zO zczO

-- Packer
--maps.n["<leader>pc"] = { "<cmd>PackerCompile<cr>", desc = "Packer Compile" }
--maps.n["<leader>pi"] = { "<cmd>PackerInstall<cr>", desc = "Packer Install" }
--maps.n["<leader>ps"] = { "<cmd>PackerSync<cr>", desc = "Packer Sync" }
--maps.n["<leader>pS"] = { "<cmd>PackerStatus<cr>", desc = "Packer Status" }
--maps.n["<leader>pu"] = { "<cmd>PackerUpdate<cr>", desc = "Packer Update" }
-- NeoTree
--if is_available "neo-tree.nvim" then
--  keymaps.n["<leader>e"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
--  keymaps.n["<leader>o"] = { "<cmd>Neotree focus<cr>", desc = "Focus Explorer" }
--end
-- Alpha
--if is_available "alpha-nvim" then maps.n["<leader>d"] = { "<cmd>Alpha<cr>", desc = "Alpha Dashboard" } end

-- Package Manager
-- TODO: v2 rework these key bindings to be more general
--if is_available "mason.nvim" then maps.n["<leader>lI"] = { "<cmd>Mason<cr>", desc = "LSP installer" } end
-- Telescope
--if is_available "telescope.nvim" then
--  maps.n["<leader>fw"] = { function() require("telescope.builtin").live_grep() end, desc = "Search words" }
--  maps.n["<leader>fW"] = {
--    function()
--      require("telescope.builtin").live_grep {
--        additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
--      }
--    end,
--    desc = "Search words in all files",
--  }
--  maps.n["<leader>gt"] = { function() require("telescope.builtin").git_status() end, desc = "Git status" }
--  maps.n["<leader>gb"] = { function() require("telescope.builtin").git_branches() end, desc = "Git branches" }
--  maps.n["<leader>gc"] = { function() require("telescope.builtin").git_commits() end, desc = "Git commits" }
--  maps.n["<leader>ff"] = { function() require("telescope.builtin").find_files() end, desc = "Search files" }
--  maps.n["<leader>fF"] = {
--    function() require("telescope.builtin").find_files { hidden = true, no_ignore = true } end,
--    desc = "Search all files",
--  }
--  maps.n["<leader>fb"] = { function() require("telescope.builtin").buffers() end, desc = "Search buffers" }
--  maps.n["<leader>fh"] = { function() require("telescope.builtin").help_tags() end, desc = "Search help" }
--  maps.n["<leader>fm"] = { function() require("telescope.builtin").marks() end, desc = "Search marks" }
--  maps.n["<leader>fo"] = { function() require("telescope.builtin").oldfiles() end, desc = "Search history" }
--  maps.n["<leader>fc"] =
--    { function() require("telescope.builtin").grep_string() end, desc = "Search for word under cursor" }
--  maps.n["<leader>sb"] = { function() require("telescope.builtin").git_branches() end, desc = "Git branches" }
--  maps.n["<leader>sh"] = { function() require("telescope.builtin").help_tags() end, desc = "Search help" }
--  maps.n["<leader>sm"] = { function() require("telescope.builtin").man_pages() end, desc = "Search man" }
--  maps.n["<leader>sn"] =
--    { function() require("telescope").extensions.notify.notify() end, desc = "Search notifications" }
--  maps.n["<leader>sr"] = { function() require("telescope.builtin").registers() end, desc = "Search registers" }
--  maps.n["<leader>sk"] = { function() require("telescope.builtin").keymaps() end, desc = "Search keymaps" }
--  maps.n["<leader>sc"] = { function() require("telescope.builtin").commands() end, desc = "Search commands" }
--  maps.n["<leader>ls"] = {
--    function()
--      local aerial_avail, _ = pcall(require, "aerial")
--      if aerial_avail then
--        require("telescope").extensions.aerial.aerial()
--      else
--        require("telescope.builtin").lsp_document_symbols()
--      end
--    end,
--    desc = "Search symbols",
--  }
--  maps.n["<leader>lR"] = { function() require("telescope.builtin").lsp_references() end, desc = "Search references" }
--end
--
---- Terminal
--if is_available "toggleterm.nvim" then
--  local toggle_term_cmd = astronvim.toggle_term_cmd
--  maps.n["<C-\\>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" }
--  maps.n["<leader>gg"] = { function() toggle_term_cmd "lazygit" end, desc = "ToggleTerm lazygit" }
--  maps.n["<leader>tn"] = { function() toggle_term_cmd "node" end, desc = "ToggleTerm node" }
--  maps.n["<leader>tu"] = { function() toggle_term_cmd "ncdu" end, desc = "ToggleTerm NCDU" }
--  maps.n["<leader>tt"] = { function() toggle_term_cmd "htop" end, desc = "ToggleTerm htop" }
--  maps.n["<leader>tp"] = { function() toggle_term_cmd "python" end, desc = "ToggleTerm python" }
--  maps.n["<leader>tl"] = { function() toggle_term_cmd "lazygit" end, desc = "ToggleTerm lazygit" }
--  maps.n["<leader>tf"] = { "<cmd>ToggleTerm direction=float<cr>", desc = "ToggleTerm float" }
--  maps.n["<leader>th"] = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", desc = "ToggleTerm horizontal split" }
--  maps.n["<leader>tv"] = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", desc = "ToggleTerm vertical split" }
--end
--
---- Stay in indent mode
--maps.v["<"] = { "<gv", desc = "unindent line" }
--maps.v[">"] = { ">gv", desc = "indent line" }
--
---- Improved Terminal Mappings
--maps.t["<esc>"] = { "<C-\\><C-n>", desc = "Terminal normal mode" }
--maps.t["jk"] = { "<C-\\><C-n>", desc = "Terminal normal mode" }
--maps.t["<C-h>"] = { "<c-\\><c-n><c-w>h", desc = "Terminal left window navigation" }
--maps.t["<C-j>"] = { "<c-\\><c-n><c-w>j", desc = "Terminal down window navigation" }
--maps.t["<C-k>"] = { "<c-\\><c-n><c-w>k", desc = "Terminal up window navigation" }
--maps.t["<C-l>"] = { "<c-\\><c-n><c-w>l", desc = "Terminal right window naviation" }
-- LSP Installer
--if is_available "mason-lspconfig.nvim" then maps.n["<leader>li"] = { "<cmd>LspInfo<cr>", desc = "LSP information" } end

--  ALE: toggle _ALE activity
--keymap('n', '<leader>a',[[:ALEToggle<CR>]])

--keymap('n', '<Leader>cd', ':call fzf#run({'source': 'fd -t d -H . ~', 'sink': 'cd'})<CR>')
-- ":lua require('neogen').generate()<CR>")
--keymap("n", "<leader>ww", ":set wrap!<CR>")
--
