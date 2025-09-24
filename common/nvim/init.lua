--[[
              ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
              ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
              ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
              ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
              ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
              ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
 ------------------------------------------------------------------------------
 Author      : srdusr
 URL         : https://github.com/srdusr/nvim.git
 Description : System-agnostic, backwards-compatible config.
               Bootstraps packer/lazy/builtin based on availability.
               Use :PackerSync, :Lazy install, or built-in (v0.12+).
 ------------------------------------------------------------------------------
--]]

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
  "tutor_mode_plugin",
  "spellfile_plugin",
  "sleuth",
  "fzf",
}

local enable_netrw = true
local ok, _ = pcall(require, "nvim-tree")
if ok then
  enable_netrw = false
end

if not enable_netrw then
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
  vim.g.loaded_netrwSettings = 1
  vim.g.loaded_netrwFileHandlers = 1
end

for _, plugin in ipairs(builtins) do
  vim.g["loaded_" .. plugin] = 1
end


-- Load/reload modules
local modules = {
  -- SETUP/MANAGER --
  "setup.compat",  -- Backwards compatibility/future proofing
  "setup.manager", -- Package Manager (builtin/packer/lazy)
  "setup.plugins", -- Plugins list

  -- USER/CORE --
  "user.keys", -- Keymaps
  "user.mods", -- Modules/functions
  "user.opts", -- Options
  "user.view", -- Colorscheme/UI

  -- PLUGINS --
  "plugins.auto-session",
  "plugins.treesitter",
  "plugins.web-devicons",
  "plugins.telescope",
  "plugins.fzf",
  "plugins.nvim-tree",
  "plugins.neodev",
  "plugins.lsp",
  "plugins.cmp",
  "plugins.quickfix",
  "plugins.colorizer",
  "plugins.prettier",
  "plugins.git",
  "plugins.fugitive",
  "plugins.snippets",
  "plugins.gitsigns",
  "plugins.sniprun",
  "plugins.surround",
  "plugins.neoscroll",
  "plugins.statuscol",
  "plugins.trouble",
  "plugins.goto-preview",
  "plugins.autopairs",
  "plugins.navic",
  "plugins.toggleterm",
  "plugins.zen-mode",
  --"plugins.fidget",
  "plugins.dap",
  "plugins.neotest",
  "plugins.heirline",
  "plugins.indent-blankline",
  "plugins.dashboard",
  "plugins.which-key",
  "plugins.harpoon",
  "plugins.leetcode",
  --"plugins.hardtime",
  "plugins.notify",
  "plugins.overseer",
  "plugins.vimtex",
  "plugins.interestingwords",

  --"plugins.nvim-tree",
  --"plugins.telescope",
  --"plugins.heirline",
  --"plugins.fzf",
  --"",

}

-- Refresh module cache
--for _, mod in ipairs(modules) do
--  package.loaded[mod] = nil
--  pcall(require, mod)
--end

for _, mod in ipairs(modules) do
  local ready, loaded = pcall(require, mod)
  if ready and type(loaded) == "table" and loaded.setup then
    local success, err = pcall(loaded.setup)
    if not success then
      vim.notify(string.format("Error setting up %s: %s", mod, err), vim.log.levels.ERROR)
    end
  elseif not ready then
    vim.notify(string.format("Failed to load %s: %s", mod, loaded), vim.log.levels.WARN)
  end
end

--require("setup.manager").setup() -- Setup all managers
--require("user.view").setup() -- Colors/UI
