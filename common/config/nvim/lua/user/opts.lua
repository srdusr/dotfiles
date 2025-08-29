--[[ opts.lua ]]

-- Environment
--vim.opt.shell = "zsh" --
vim.o.updatetime = 250
vim.o.shell = '/bin/zsh'
vim.scriptencoding = 'utf-8'                 --
vim.opt.encoding = 'utf-8'                   --
vim.opt.fileencoding = 'utf-8'               --
vim.g.python3_host_prog = '/usr/bin/python3' --
vim.g.loaded_python3_provider = 1            --
vim.g.sh_noisk = 1                           -- iskeyword word boundaries when editing a 'sh' file
vim.o.autochdir = true
--vim.o.writeany= true

-- Clipboard
vim.opt.clipboard:append({ 'unnamedplus' }) -- Install xclip or this will slowdown startup

-- Behaviour
vim.opt.backspace = { 'start', 'eol', 'indent' } -- Make backspace work as you would expect.
vim.opt.hidden = true -- Switch between buffers without having to save first.
vim.opt.splitbelow = true -- make split put the new buffer below the current buffer
vim.opt.splitright = true -- make vsplit put the new buffer on the right of the current buffer
vim.opt.scrolloff = 8 --
vim.opt.sidescrolloff = 8 -- how many lines to scroll when using the scrollbar
vim.opt.autoread = true -- reload files if changed externally
vim.opt.display = 'lastline' -- Show as much as possible of the last line.
vim.opt.inccommand = 'split' --
vim.opt.ttyfast = true -- Faster redrawing.
vim.opt.lazyredraw = false -- Only redraw when necessary
vim.opt.keywordprg = ':help' -- :help options
vim.opt.ruler = true --
vim.opt.errorbells = false --
vim.opt.list = true -- Show non-printable characters.
vim.opt.showmatch = true --
vim.opt.matchtime = 3 --
vim.opt.showbreak = '↪ ' --
vim.opt.linebreak = true --
vim.opt.exrc = true --
--vim.opt.autochdir = true                          -- or use this to use <:e> to create a file in current directory
vim.opt.autoread = true -- if a file is changed outside of vim, automatically reload it without asking
--vim.opt.notimeout = true                          -- Timeout on keycodes and not mappings
vim.opt.ttimeout = true -- Makes terminal vim work sanely
vim.opt.ttimeoutlen = 10 --
--vim.opt.timeoutlen = 100 -- time to wait for a mapped sequence to complete (in milliseconds)
--vim.cmd([[set diffopt = vertical = true]])        -- diffs are shown side-by-side not above/below

-- Indent/tab
vim.opt.breakindent = true --
vim.opt.autoindent = true  -- Indent according to previous line.
vim.opt.copyindent = true  -- Copy indent from the previous line
vim.opt.smarttab = false   --
vim.opt.tabstop = 2        --
vim.opt.expandtab = true   -- Indent according to previous line.
--vim.opt.expandtab = true                          -- Use spaces instead of tabs.
vim.opt.softtabstop = 2    -- Tab key indents by 2 spaces.
vim.opt.shiftwidth = 2     -- >> indents by 2 spaces.
vim.opt.shiftround = true  -- >> indents to next multiple of 'shiftwidth'.
vim.opt.smartindent = true -- smart indent

-- Column/statusline/Cl
vim.opt.number = true        --
vim.opt.title = true         --
--vim.opt.colorcolumn = "+1" --
vim.opt.signcolumn = 'yes:1' -- always show the sign column
--vim.opt.signcolumn = "yes:" .. vim.o.numberwidth
--vim.opt.signcolumn = "number"
--vim.opt.signcolumn = "no"                         --
vim.opt.laststatus = 3  -- " Always show statusline.
vim.opt.showmode = true -- Show current mode in command-line, example: -- INSERT -- mode
vim.opt.showcmd = true  -- Show the command in the status bar
vim.opt.cmdheight = 1   --
--vim.opt.cmdheight = 0                             --
vim.opt.report = 0      -- Always report changed lines.
--local autocmd = vim.api.nvim_create_autocmd
--autocmd("bufenter", {
--	pattern = "*",
--	callback = function()
--		if vim.bo.ft ~= "terminal" then
--			vim.opt.statusline = "%!v:lua.require'ui.statusline'.run()"
--		else
--			vim.opt.statusline = "%#normal# "
--		end
--	end,
--})
---- With vertical splits, the statusline would still show up at the
---- bottom of the split. A quick fix is to just set the statusline
---- to empty whitespace (it can't be an empty string because then
---- it'll get replaced by the default stline).
--vim.opt.stl = " "

-- Backup/undo/swap
local prefix = vim.env.XDG_CONFIG_HOME or vim.fn.expand('~/.config')
--vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undodir = { prefix .. '/nvim/tmp/.undo//' }
vim.opt.directory = { prefix .. '/nvim/tmp/.swp//' }
vim.opt.backupdir = { prefix .. '/nvim/tmp/.backup//' }
vim.opt.undofile = true --
vim.opt.swapfile = true --
vim.opt.backup = true   --
--vim.opt.backupcopy =
-- Add timestamp as extension for backup files
vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('timestamp_backupext', { clear = true }),
  desc = 'Add timestamp to backup extension',
  pattern = '*',
  callback = function()
    vim.opt.backupext = '-' .. vim.fn.strftime('%Y%m%d%H%M')
  end,
})

-- Format
--vim.opt.textwidth = 80 --
vim.opt.isfname:append('@-@')
vim.cmd([[let &t_Cs = "\e[4:3m"]])    -- Undercurl
vim.cmd([[let &t_Ce = "\e[4:0m"]])    --
vim.opt.path:append({ '**' })         -- Finding files - Search down into subfolder
vim.cmd('set whichwrap+=<,>,[,],h,l') --
vim.cmd([[set iskeyword+=-]])         --
--vim.cmd([[set formatoptions-=cro]]) -- TODO: this doesn't seem to work
vim.opt.formatoptions = vim.opt.formatoptions
    - 't'               -- wrap with text width
    + 'c'               -- wrap comments
    + 'r'               -- insert comment after enter
    - 'o'               -- insert comment after o/O
    - 'q'               -- allow formatting of comments with gq
    - 'a'               -- format paragraphs
    + 'n'               -- recognized numbered lists
    - '2'               -- use indent of second line for paragraph
    + 'l'               -- long lines are not broken
    + 'j'               -- remove comment when joining lines
vim.opt.wrapscan = true -- " Searches wrap around end-of-file.
--vim.wo.number = true                              --
--vim.opt.wrap = false                              -- No Wrap lines
--vim.opt.foldmethod = 'manual'                     --
--vim.opt.foldmethod = "expr" --
vim.opt.foldmethod = 'manual'
vim.opt.foldlevel = 3
vim.opt.confirm = false
--vim.opt.shortmess:append("sI")
--vim.opt.shortmess = "a"
--vim.opt.shortmess = "sI"
--vim.o.shortmess = vim.o.shortmess:gsub('s', '')
vim.opt.shortmess = table.concat({ -- Use abbreviations and short messages in command menu line.
  'f',                             -- Use "(3 of 5)" instead of "(file 3 of 5)".
  'i',                             -- Use "[noeol]" instead of "[Incomplete last line]".
  'l',                             -- Use "999L, 888C" instead of "999 lines, 888 characters".
  'm',                             -- Use "[+]" instead of "[Modified]".
  'n',                             -- Use "[New]" instead of "[New File]".
  'r',                             -- Use "[RO]" instead of "[readonly]".
  'w',                             -- Use "[w]", "[a]" instead of "written", "appended".
  'x',                             -- Use "[dos]", "[unix]", "[mac]" instead of "[dos format]", "[unix format]", "[mac format]".
  'o',                             -- Overwrite message for writing a file with subsequent message.
  'O',                             -- Message for reading a file overwrites any previous message.
  's',                             -- Disable "search hit BOTTOM, continuing at TOP" such messages.
  't',                             -- Truncate file message at the start if it is too long.
  'T',                             -- Truncate other messages in the middle if they are too long.
  'I',                             -- Don't give the :intro message when starting.
  'c',                             -- Don't give ins-completion-menu messages.
  'F',                             -- Don't give the file info when editing a file.
})
vim.opt.fillchars = {
  horiz = '─',
  horizup = '┴',
  horizdown = '┬',
  vert = '│',
  vertleft = '┤',
  vertright = '├',
  verthoriz = '┼',
  foldopen = '',
  foldsep = '│',
  foldclose = '',
  fold = '─',
  eob = ' ',
  --diff = "┃",
  diff = '░',
  msgsep = '━',
  --msgsep = "‾",
}
vim.opt.listchars = { tab = '▸ ', trail = '·' } --
--vim.opt.fillchars:append({ eob = " " }) -- remove the ~ from end of buffer
vim.opt.modeline = true --
vim.opt.modelines = 3 -- modelines (comments that set vim options on a per-file basis)
--vim.opt.modelineexpr = true
--vim.opt.nofoldenable = true                       -- turn folding off
--vim.opt.foldenable = false -- turn folding off
vim.o.showtabline = 2

-- Highlights
vim.opt.incsearch = true  -- Highlight while searching with / or ?.
vim.opt.hlsearch = true   -- Keep matches highlighted.
vim.opt.ignorecase = true -- ignore case in search patterns UNLESS /C or capital in search
vim.opt.smartcase = true  -- smart case
vim.opt.synmaxcol = 200   -- Only highlight the first 200 columns.
--vim.opt.winblend = 30
--vim.opt.winblend = 5
vim.opt.wildoptions = 'pum' --
--vim.opt.pumblend = 5 --
vim.opt.pumblend = 12       --
--vim.opt.pumblend=15
vim.opt.pumheight = 10      -- pop up menu height

-- Better Completion
vim.opt.complete = { '.', 'w', 'b', 'u', 't' } --
--vim.opt.completeopt = { "longest,menuone,preview" } --
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }
--vim.opt.completeopt = { "menuone", "noselect" }   -- mostly just for cmp
--vim.opt.completeopt = { "menu", "menuone", "noselect" } --

-- Wildmenu completion                            --
vim.opt.wildmenu = true                                                       --
vim.opt.wildmode = { 'list:longest' }                                         --
vim.opt.wildignore:append({ '.hg', '.git', '.svn' })                          -- Version control
vim.opt.wildignore:append({ '*.aux', '*.out', '*.toc' })                      -- LaTeX intermediate files
vim.opt.wildignore:append({ '*.jpg', '*.bmp', '*.gif', '*.png', '*.jpeg' })   -- binary images
vim.opt.wildignore:append({ '*.o', '*.obj', '*.exe', '*.dll', '*.manifest' }) -- compiled object files
vim.opt.wildignore:append({ '*.spl' })                                        -- compiled spelling word lists
vim.opt.wildignore:append({ '*.sw?' })                                        -- Vim swap files
vim.opt.wildignore:append({ '*.DS_Store' })                                   -- OSX bullshit
vim.opt.wildignore:append({ '*.luac' })                                       -- Lua byte code
vim.opt.wildignore:append({ 'migrations' })                                   -- Django migrations
vim.opt.wildignore:append({ '*.pyc' })                                        -- Python byte code
vim.opt.wildignore:append({ '*.orig' })                                       -- Merge resolution files
vim.opt.wildignore:append({ '*/node_modules/*' })                             --

-- Shada
vim.opt.shada = "!,'1000,f1,<1000,s100,:1000,/1000,h"

-- Sessions
vim.opt.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal'
--vim.opt.sessionoptions = "curdir,folds,help,options,tabpages,winsize,winpos,terminal,globals" --
--vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal"
--vim.opt.sessionoptions:remove({ "blank", "buffers", "globals" })

-- Netrw file tree
vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

-- " Load indent files, to automatically do language-dependent indenting.
--vim.cmd([[
--    "filetype plugin indent on
--]])
vim.cmd('filetype plugin on')
vim.cmd('filetype indent off')

-- Let clipboard register be +
vim.cmd([[
    let g:clipbrdDefaultReg = '+'
]])

--vim.cmd([[
--    "autocmd BufEnter * :syntax sync fromstart
--    "syntax enable
--    "set nocompatible
--    "autocmd FileType lua set comments=s1:---,m:--,ex:--
--]])

-- Fast macros without lazyredraw
vim.cmd([[
    set re=0
    nnoremap @ <cmd>execute "noautocmd norm! " . v:count1 . "@" . getcharstr()<cr>
    xnoremap @ :<C-U>execute "noautocmd '<,'>norm! " . v:count1 . "@" . getcharstr()<cr>
]])

-- Stop annoying auto commenting on new lines
vim.cmd([[
  augroup annoying
    au!
    au BufEnter * set fo-=c fo-=r fo-=o
  augroup end
]])

-- Cursorline
vim.cmd([[                                        " Only show cursorline in the current window and in normal mode
  	augroup cline
	    au!
	    au WinLeave,InsertEnter * set nocursorline
	    au WinEnter,InsertLeave * set cursorline
	augroup END
]])
vim.opt.cursorline = true               --
vim.opt.guicursor = 'i:ver100,r:hor100' --

-- Trailing whitespace
vim.cmd([[                                        " Only show in insert mode
    augroup trailing
	    au!
	    au InsertEnter * :set listchars-=trail:⌴
	    au InsertLeave * :set listchars+=trail:⌴
	augroup END
]])

-- Line Return
vim.cmd([[                                        " Return to the same line when we reopen a file
  augroup line_return
      au!
      au BufReadPost *
          \ if line("'\"") > 0 && line("'\"") <= line("$") |
          \     execute 'normal! g`"zvzz' |
          \ endif
  augroup END
]])

-- Enable mouse scrollback
vim.cmd([[
    set mouse=a
    tnoremap <Esc> <C-\><C-n>
    tnoremap <c-b> <c-\><c-n>
    function! ClearTerminal()
        set scrollback=1
        let &g:scrollback=1
        echo &scrollback
        call feedkeys("\i")
        call feedkeys("clear\<CR>")
        call feedkeys("\<C-\>\<C-n>")
        call feedkeys("\i")
        sleep 100m
        let &scrollback=s:scroll_value
    endfunction
]])

-- Yank to clipboard in Termux
if vim.fn.has('termux') == 1 then
  local Job = require('plenary.job')
  vim.api.nvim_create_autocmd('TextYankPost', {
    pattern = '*',
    callback = function()
      Job:new({
        command = 'termux-clipboard-set',
        writer = vim.fn.getreg('@'),
      }):start()
    end,
  })
end

function GetTermuxClipboard()
  if vim.fn.has('termux') == 1 then
    local sysclip = vim.fn.system('termux-clipboard-get')
    if sysclip ~= '@' then
      vim.fn.setreg('@', sysclip)
    end
  end
  return ''
end

if vim.fn.has('termux') == 1 then
  vim.cmd('autocmd TextYankPost * call GetTermuxClipboard()')
  vim.cmd('noremap <expr> p Paste("p")')
  vim.cmd('noremap <expr> P Paste("P")')
end
