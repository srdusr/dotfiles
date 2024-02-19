--[[
              ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
              ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
              ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
              ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
              ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
              ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
              " ------------------------------------------------
              Author: srdusr
               Email: trevorgray@srdusr.com
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

-- ================================== --
-- ==    Install neovim-nightly    == --
-- ================================== --

-- Download nvim-linux64.tar.gz:
--$ curl -L -o nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz
-- Extract:
--$ tar xzvf nvim-linux64.tar.gz --install-dir=/bin
-- Run:
--$ ./nvim-linux64/bin/nvim

-- ---------------------------------- --

-- Initialize config with this one liner in the terminal
--$ nvim --headless -c 'call mkdir(stdpath("config"), "p") | exe "edit" stdpath("config") . "/init.lua" | write | quit'

-- Command to see startup time
--$ nvim --startuptime startup.log -c exit && tail -100 startup.log

-- Load impatient (Faster loading times)
local impatient_ok, impatient = pcall(require, "impatient")
if impatient_ok then
  impatient.enable_profile()
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
  "user.mods", -- Modules/functions
  "user.view", -- Colorscheme/UI
  "plugins.web-devicons",
  "plugins.treesitter",
  "plugins.neodev",
  "plugins.telescope",
  "plugins.nvim-tree",
  "plugins.lsp",
  "plugins.cmp",
  "plugins.quickfix",
  --"plugins.snippets",
  --"plugins.colorizer",
  --"plugins.prettier",
  --"plugins.git",
  --"plugins.fugitive",
  "plugins.gitsigns",
  "plugins.sniprun",
  "plugins.session",
  "plugins.surround",
  "plugins.neoscroll",
  "plugins.statuscol",
  "plugins.trouble",
  "plugins.goto-preview",
  "plugins.autopairs",
  "plugins.navic",
  "plugins.toggleterm",
  "plugins.zen-mode",
  "plugins.fidget",
  "plugins.dap",
  "plugins.neotest",
  "plugins.heirline",
  "plugins.dashboard",
  "plugins.which-key",
  "plugins.harpoon",
  "plugins.leetcode",
  "plugins.hardtime",
  "plugins.notify",
  "plugins.overseer",
  "plugins.vimtex",
  --"plugins.modify-blend",
}

-- Refresh module cache
for k, v in pairs(modules) do
  package.loaded[v] = nil
  require(v)
end

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
vim.g.do_filetype_lua = 1
vim.g.did_load_filetypes = 0

-- Snippets
--vim.g.snippets = 'luasnip'

-- Notifications
vim.notify = require("notify") -- Requires plugin "rcarriga/nvim-notify"
