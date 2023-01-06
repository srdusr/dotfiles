--[[
              ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
              ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
              ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
              ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
              ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
              ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
              " ------------------------------------------------
              Author: srdusr
               Email: graytrevor98@gmail.com
                 Url: https://github.com/srdusr/nvim.git
              ------------------------------------------------ "
--]]

--[[init.]]

-- ========================================================================== --
-- ==                            DEPENDENCIES                              == --
-- ========================================================================== --

-- ripgrep    - https://github.com/BurntSushi/ripgrep
-- fd         - https://github.com/sharkdp/fd
-- git        - https://git-scm.com/
-- make       - https://www.gnu.org/software/make/
-- c compiler - gcc or tcc or zig

-- -------------------------------------------------------------------------- --

-- Initialize config with this one liner in the terminal
--nvim --headless -c 'call mkdir(stdpath("config"), "p") | exe "edit" stdpath("config") . "/init.lua" | write | quit'

-- See startup time
--nvim --startuptime startup.log -c exit && tail -100 startup.log

-- Load impatient
local impatient_ok, impatient = pcall(require, "impatient")
if impatient_ok then
	impatient.enable_profile()
end

-- Check if we have the latest stable version of nvim
local utils = require("user.utils")
local expected_ver = "0.8.0"
local nvim_ver = utils.get_nvim_version()

if nvim_ver ~= expected_ver then
	local msg = string.format("Unsupported nvim version: expect %s, but got %s instead!", expected_ver, nvim_ver)
vim.api.nvim_err_writeln(msg)
	return
end

-- Schedule reading shadafile to improve the startup time
vim.opt.shadafile = "NONE"
vim.schedule(function()
	vim.opt.shadafile = ""
	vim.cmd("silent! rsh")
end)


-- Load/reload modules
local modules = {
  "user.pack", -- Packer plugin manager
  "user.opts", -- Options
  "user.keys", -- Keymaps
  "user.utils", -- Utilities
  --"user.mods", -- Modules/functions
  --"user.deps", -- Plugins
  --"user.scripts",
  "plugins.treesitter",
  "plugins.telescope",
  "plugins.nvim-tree",
  "plugins.cmp",
  "plugins.luasnip",
  "plugins.colorizer",
  "plugins.prettier",
  "plugins.git",
  "plugins.gitsigns",
  "plugins.neoscroll",
  "plugins.lsp",
  "plugins.autopairs",
  "plugins.null-ls",
  "plugins.web-devicons",
  "plugins.zen-mode",
  "plugins.colorscheme",
  "plugins.heirline",
  "plugins.toggleterm",
  --"plugins.dap",
  --"plugins.floatterm",
}

-- Refresh module cache
for k, v in pairs(modules) do
  package.loaded[v] = nil
  require(v)
end

-- Snippets
vim.g.snippets = "luasnip"

-- Improve speed by disabling some default plugins/modules
local builtins = {
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	--"matchit",
	--"matchparen",
	"logiPat",
	"rrhelper",
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
  "tutor_mode_plugin",
  "fzf",
  "spellfile_plugin",
  "sleuth",
}

for _, plugin in ipairs(builtins) do
	vim.g["loaded_" .. plugin] = 1
end
vim.g.do_filetype_nvim = 1
vim.g.did_load_filetypes = 0

--vim.cmd[[
--if maparg('<C-L>', 'n') ==# ''
--  nnoremap <silent> <C-L> :set lz!<CR>:nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>:set lz!<CR>
--endif]]
--vim.cmd[[autocmd VimEnter * set nolazyredraw lazyredraw]]
--vim.cmd[[autocmd VimEnter * redraw!]]

