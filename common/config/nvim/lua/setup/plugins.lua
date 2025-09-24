-- plugins.lua

-- Helper to compare current Neovim version
local function version_at_least(minor, major)
  local v = vim.version()
  major = major or 0
  return v.major > major or (v.major == major and v.minor >= minor)
end

local function version_below(minor, major)
  local v = vim.version()
  major = major or 0
  return v.major < major or (v.major == major and v.minor < minor)
end

-- Normalize version input: number -> {0, number}, table -> itself
local function parse_version(ver)
  if type(ver) == "number" then return 0, ver end
  if type(ver) == "table" then return ver[1] or 0, ver[2] or 0 end
  return 0, 0
end

-- Determine if plugin should be loaded based on version
local function should_load_plugin(min_version, max_version)
  local min_major, min_minor = parse_version(min_version)
  local max_major, max_minor = parse_version(max_version)

  local ok_min = not min_version or version_at_least(min_minor, min_major)
  local ok_max = not max_version or version_below(max_minor, max_major)

  return ok_min and ok_max
end

-- Helper to check if a table contains a specific value
local function contains(table, val)
  for _, v in ipairs(table) do
    if v == val then
      return true
    end
  end
  return false
end

-- The master list of plugins with all potential options.
-- Keys like 'lazy', 'event', 'keys', 'dependencies' are for Lazy.nvim.
-- Keys like 'config', 'run', 'build' are for all managers.
local universal_plugins = {
  -- Core
  { "nvim-lua/plenary.nvim",   lazy = true },
  { "lewis6991/impatient.nvim" },

  {
    "nvim-treesitter/nvim-treesitter",
    min_version = 9,
    event = "BufReadPre",
  },
  { "nvim-treesitter/nvim-treesitter-textobjects", dependencies = { "nvim-treesitter/nvim-treesitter" } },
  { "nvim-treesitter/playground",                  cmd = "TSPlaygroundToggle" },

  -- LSP
  { "nvimtools/none-ls.nvim",                      event = "BufReadPre" },
  { "neovim/nvim-lspconfig",                       min_version = { 0, 9 },                              event = "BufReadPre" },
  {
    "mason-org/mason.nvim",
    min_version = 10,
    cmd = "Mason",
    event = "BufReadPre",
  },
  { "mason-org/mason-lspconfig.nvim", dependencies = { "mason-org/mason.nvim" } },
  {
    "whoissethdaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "BufReadPre",
  },
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    name = 'lsp_lines.nvim',
    config = function()
      require("lsp_lines").setup()
      vim.diagnostic.config({
        virtual_text = false,
      })
    end,
    event = "LspAttach",
  },
  { "rmagatti/goto-preview",          event = "LspAttach" },

  -- Linters/Formatters
  { "mhartington/formatter.nvim",     event = "BufReadPre" },
  {
    "jay-babu/mason-null-ls.nvim",
    event = "BufReadPre",
  },

  -- Completion
  { "hrsh7th/nvim-cmp",                    event = "InsertEnter",                 exclude = { "builtin" } },
  { "hrsh7th/cmp-nvim-lsp",                dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "hrsh7th/cmp-buffer",                  dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "hrsh7th/cmp-path",                    dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "hrsh7th/cmp-cmdline",                 dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "petertriho/cmp-git",                  dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "tamago324/cmp-zsh",                   dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "f3fora/cmp-spell",                    dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "hrsh7th/cmp-calc",                    dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "saadparwaiz1/cmp_luasnip",            dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "hrsh7th/cmp-nvim-lsp-signature-help", dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "rcarriga/cmp-dap",                    dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },
  { "micangl/cmp-vimtex",                  dependencies = { "hrsh7th/nvim-cmp" }, exclude = { "builtin" } },

  -- Snippets
  { "L3MON4D3/LuaSnip",                    event = "InsertEnter" },
  { "rafamadriz/friendly-snippets",        dependencies = { "L3MON4D3/LuaSnip" } },

  -- Git
  { "tpope/vim-fugitive",              cmd = { "G", "Git", "Gdiffsplit" }, event = "VeryLazy" },
  { "kdheepak/lazygit.nvim",               cmd = "LazyGit",                       keys = "<leader>gg" },
  { "lewis6991/gitsigns.nvim", min_version = 11, dependencies = { "nvim-lua/plenary.nvim" }, event = "BufReadPre" },

  -- UI/UX & Enhancements
  { "rcarriga/nvim-notify",                lazy = false },
  {
    "nvim-tree/nvim-tree.lua",
    --cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    --keys = { "<C-n>", "<leader>e" },
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons"},
    config = function()
      require("plugins.nvim-tree").setup()
    end,
  },
  { "ThePrimeagen/harpoon", keys = { "<leader>h" } },
  { "airblade/vim-rooter",  event = "BufEnter" },
  { "ibhagwan/fzf-lua",     cmd = "FzfLua" },

  --- **Telescope** ---
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("plugins.telescope").setup()
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    cond = function()
      return vim.fn.executable("make") == 1
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  { "nvim-telescope/telescope-live-grep-args.nvim", dependencies = { "nvim-telescope/telescope.nvim" } },
  { "nvim-telescope/telescope-ui-select.nvim",      dependencies = { "nvim-telescope/telescope.nvim" } },
  { "nvim-telescope/telescope-project.nvim",        dependencies = { "nvim-telescope/telescope.nvim" } },
  { "nvim-telescope/telescope-media-files.nvim",    dependencies = { "nvim-telescope/telescope.nvim" } },
  { "nvim-telescope/telescope-file-browser.nvim",   dependencies = { "nvim-telescope/telescope.nvim" } },
  { "nvim-telescope/telescope-symbols.nvim",        dependencies = { "nvim-telescope/telescope.nvim" } },
  { "nvim-telescope/telescope-dap.nvim",            dependencies = { "nvim-telescope/telescope.nvim" } },
  { "axkirillov/telescope-changed-files",           dependencies = { "nvim-telescope/telescope.nvim" } },
  { "smartpde/telescope-recent-files",              dependencies = { "nvim-telescope/telescope.nvim" } },
  --- End Telescope ---

  -- Neovim UX
  { "folke/neodev.nvim",                            ft = "lua" },
  {
    "numToStr/Navigator.nvim",
    lazy = false,
    config = function()
      require("Navigator").setup()
    end,
  },
  { "tpope/vim-eunuch",       cmd = { "Rename", "Delete", "Mkdir" } },
  { "tpope/vim-unimpaired",   lazy = true,                          event = "VeryLazy" },
  { "kylechui/nvim-surround", event = "VeryLazy" },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = "<leader>u",
    event = "BufReadPre"
  },
  {
    "myusuf3/numbers.vim",
    event = "BufReadPost",
    config = function()
      vim.cmd("let g:numbers_exclude = ['dashboard']")
    end,
  },
  { "windwp/nvim-autopairs",        event = "InsertEnter" },
  { "numToStr/Comment.nvim",        keys = { "gc", "gb" },             event = "VeryLazy" },
  { "akinsho/toggleterm.nvim",      cmd = { "ToggleTerm", "TermExec" } },
  { "tweekmonster/startuptime.vim", cmd = "StartupTime" },
  { "qpkorr/vim-bufkill",           cmd = { "BD", "BUN" } },
  {
    "ggandor/leap.nvim",
    keys = { "s", "S" },
    event = "VeryLazy",
    config = function()
      require("leap").add_default_mappings()
    end,
  },
  {
    "ggandor/flit.nvim",
    keys = { "f", "F", "t", "T" },
    event = "VeryLazy",
    config = function()
      require("flit").setup()
    end,
  },
  {
    "folke/which-key.nvim",
    min_version = { 0, 10 },
    event = "VeryLazy",
    --keys = "<leader>",
    config = function()
      require("which-key").setup()
    end,
  },
  { "folke/zen-mode.nvim",              cmd = "ZenMode" },
  { "romainl/vim-cool",                 event = "VeryLazy" },
  { "antoinemadec/FixCursorHold.nvim",  lazy = true },
  { "folke/trouble.nvim",               cmd = { "Trouble", "TroubleToggle" } },

  -- Colorschemes & Visuals (load immediately)
  { "nyoom-engineering/oxocarbon.nvim", lazy = false,                                    priority = 1000 },
  { "bluz71/vim-nightfly-guicolors",    lazy = false,                                    priority = 1000 },
  { "ayu-theme/ayu-vim",                lazy = false,                                    priority = 1000 },
  { "joshdick/onedark.vim",             lazy = false,                                    priority = 1000 },
  { "NTBBloodbath/doom-one.nvim",       lazy = false,                                    priority = 1000 },
  { "nyngwang/nvimgelion",              lazy = false,                                    priority = 1000 },
  { "projekt0n/github-nvim-theme",      lazy = false,                                    priority = 1000 },
  { "folke/tokyonight.nvim",            lazy = false,                                    priority = 1000 },
  { "ribru17/bamboo.nvim",              lazy = false,                                    priority = 1000 },

  -- UI Enhancements
  --{ "kyazdani42/nvim-web-devicons",     lazy = true },
  { "nvim-tree/nvim-web-devicons",     lazy = true },
  { "onsails/lspkind-nvim",             dependencies = { "hrsh7th/nvim-cmp" },           exclude = { "builtin" } },
  { "kevinhwang91/nvim-ufo",            dependencies = { "kevinhwang91/promise-async" }, event = "BufReadPre" },
  {
    "luukvbaal/statuscol.nvim",
    event = "WinNew",
    config = function()
      local builtin = require("statuscol.builtin")
      require("statuscol").setup({
        relculright = true,
        segments = {
          { text = { builtin.foldfunc },      click = "v:lua.ScFa" },
          { text = { "%s" },                  click = "v:lua.ScSa" },
          { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
        },
      })
    end,
  },
  { "lukas-reineke/indent-blankline.nvim", event = "BufReadPre" },
  {
    "glepnir/dashboard-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Dashboard",
  },
  { "karb94/neoscroll.nvim",               event = "BufReadPre" },
  { "MunifTanjim/prettier.nvim",           event = "BufWritePre" },
  {
    "norcalli/nvim-colorizer.lua",
    cmd = { "ColorizerToggle", "ColorizerAttachToBuffer" },
    config = function()
      require("colorizer").setup({
        user_default_options = {
          RGB = true,
          RRGGBB = true,
          names = false,
          RRGGBBAA = false,
          css = false,
          css_fn = true,
          mode = "foreground",
        },
      })
    end,
  },
  { "MunifTanjim/nui.nvim" },
  { "metakirby5/codi.vim", cmd = "Codi" },
  {
    "kosayoda/nvim-lightbulb",
    dependencies = { "antoinemadec/FixCursorHold.nvim" },
    event = "LspAttach",
  },
  { "SmiteshP/nvim-navic",      event = "LspAttach" },
  {
    "rebelot/heirline.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- For file icons
      "lewis6991/gitsigns.nvim",     -- For git status
    },
    config = function()
      -- Ensure gitsigns is loaded before Heirline
      if package.loaded["gitsigns"] == nil then
        require("gitsigns").setup()
      end
      local ok, heirline = pcall(require, "plugins.heirline")
      if ok and heirline then
        heirline.setup()
      else
        vim.notify("Failed to load Heirline configuration", vim.log.levels.ERROR)
      end
    end,
    init = function()
      -- Set up the statusline to use Heirline once it's loaded
      vim.opt.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"
      vim.opt.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
      vim.opt.tabline = "%{%v:lua.require'heirline'.eval_tabline()%}"
    end,
  },
  {
    "samodostal/image.nvim",
    config = function()
      require("image").setup({})
    end,
    ft = { "markdown" },
  },

  -- Language Specific
  { "simrat39/rust-tools.nvim", ft = "rust" },
  {
    "saecki/crates.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crates").setup()
    end,
    ft = "rust",
  },
  {
    "akinsho/flutter-tools.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("flutter-tools").setup({
        debugger = {
          enabled = true,
          run_via_dap = true,
        },
      })
    end,
    ft = "dart",
  },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = "markdown",
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.cmd("let g:mkdp_auto_close = 0")
    end,
    cmd = "MarkdownPreview",
  },
  {
    "ellisonleao/glow.nvim",
    config = function()
      local glow_path = vim.fn.executable("~/.local/bin/glow") == 1 and "~/.local/bin/glow" or "/usr/bin/glow"
      require("glow").setup({
        style = "dark",
        glow_path = glow_path,
      })
    end,
    ft = "markdown",
  },

  -- Debugging
  { "mfussenegger/nvim-dap",           event = "VeryLazy" },
  { "rcarriga/nvim-dap-ui",            dependencies = { "mfussenegger/nvim-dap" }, cmd = "DapUI" },
  { "theHamsta/nvim-dap-virtual-text", dependencies = { "mfussenegger/nvim-dap" } },
  { "gabrielpoca/replacer.nvim",       cmd = "Replacer" },
  { "jayp0521/mason-nvim-dap.nvim",    dependencies = { "mason-org/mason.nvim" } },

  -- Misc
  { "rmagatti/auto-session",           event = "VimEnter" },
  { "tpope/vim-sleuth",                lazy = true },
  { "michaelb/sniprun",                build = "bash ./install.sh",                cmd = "SnipRun" },
  { "stevearc/overseer.nvim",          cmd = "Overseer" },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-plenary",
      "nvim-neotest/neotest-vim-test",
      "nvim-neotest/nvim-nio",
    },
    cmd = "Neotest",
  },
  { "kawre/leetcode.nvim",   cmd = "Leetcode" },
  { "m4xshen/hardtime.nvim", lazy = true },

  -- LaTeX
  { "lervag/vimtex",         ft = "tex" },
}

-- Helper function to detect current manager
local function detect_current_manager()
  -- Check if we're currently using lazy (by checking if lazy module exists)
  if package.loaded["lazy"] or package.loaded["lazy.core.util"] then
    return "lazy"
  end

  -- Check if we're currently using packer
  if package.loaded["packer"] then
    return "packer"
  end

  -- Check for builtin manager
  if vim.plugins and vim.plugins.spec then
    return "builtin"
  end

  return "unknown"
end

local function format_for_lazy(plugin)
  -- Lazy.nvim's format is the closest to our universal format, so we can
  -- largely just copy the table, with some specific adjustments.
  local new_plugin = vim.deepcopy(plugin)

  -- Lazy.nvim uses `dependencies` key for dependencies, not `requires`
  if new_plugin.requires then
    new_plugin.dependencies = new_plugin.requires
    new_plugin.requires = nil
  end

  -- Change 'as' to 'name' for lazy
  if new_plugin.as then
    new_plugin.name = new_plugin.as
    new_plugin.as = nil
  end

  -- Change 'run' to 'build' for lazy
  if new_plugin.run then
    new_plugin.build = new_plugin.run
    new_plugin.run = nil
  end

  return new_plugin
end

local function format_for_packer(plugin)
  -- For Packer, we need to remove lazy-loading keys to force eager loading
  local new_plugin = vim.deepcopy(plugin)

  -- Convert dependencies back to requires for packer
  if new_plugin.dependencies then
    new_plugin.requires = new_plugin.dependencies
    new_plugin.dependencies = nil
  end

  -- Convert name back to as for packer
  if new_plugin.name then
    new_plugin.as = new_plugin.name
    new_plugin.name = nil
  end

  -- Convert build back to run for packer
  if new_plugin.build then
    new_plugin.run = new_plugin.build
    new_plugin.build = nil
  end

  -- Remove lazy-loading keys to force eager loading in packer
  new_plugin.event = nil
  new_plugin.keys = nil
  new_plugin.cmd = nil
  new_plugin.ft = nil
  new_plugin.lazy = nil

  return new_plugin
end

local function format_for_builtin(plugin)
  -- This function is now simplified, as the main loop handles flattening
  local new_plugin = vim.deepcopy(plugin)

  -- Convert GitHub shorthand to full URL if needed
  if type(new_plugin) == "string" then
    if new_plugin:match("^[%w%-_%.]+/[%w%-_%.]+$") then
      return {
        src = "https://github.com/" .. new_plugin,
        name = new_plugin:match("/([%w%-_%.]+)$")
      }
    else
      return { src = new_plugin }
    end
  end

  -- Handle table format
  if new_plugin[1] and type(new_plugin[1]) == "string" then
    local repo = new_plugin[1]
    if repo:match("^[%w%-_%.]+/[%w%-_%.]+$") then
      new_plugin.src = "https://github.com/" .. repo
      new_plugin.name = new_plugin.name or new_plugin.as or repo:match("/([%w%-_%.]+)$")
    else
      new_plugin.src = repo
    end
    new_plugin[1] = nil -- Remove positional argument
  end

  -- Convert url to src if present
  if new_plugin.url then
    new_plugin.src = new_plugin.url
    new_plugin.url = nil
  end

  -- Convert 'as' to 'name'
  if new_plugin.as then
    new_plugin.name = new_plugin.as
    new_plugin.as = nil
  end

  -- Only keep the keys that vim.pack uses: src, name, and version
  new_plugin.dependencies = nil
  new_plugin.config = nil
  new_plugin.build = nil
  new_plugin.run = nil
  new_plugin.cond = nil
  new_plugin.min_version = nil
  new_plugin.max_version = nil
  new_plugin.lazy = nil
  new_plugin.priority = nil
  new_plugin.event = nil
  new_plugin.keys = nil
  new_plugin.cmd = nil
  new_plugin.ft = nil
  new_plugin.requires = nil

  return new_plugin
end

-- Detect which manager is currently active and format plugins accordingly
local current_manager = detect_current_manager()
local plugins_to_process = {}
local processed_plugins = {} -- Use a set to avoid duplicates

-- Flatten the plugin list for the builtin manager
if current_manager == "builtin" then
  local function get_plugin_name(plugin)
    if type(plugin) == "string" then
      return plugin:match("/([%w%-_%.]+)$") or plugin
    elseif type(plugin) == "table" then
      -- Get name from 'name', 'as', or from the src/url
      return plugin.name or plugin.as or (type(plugin[1]) == "string" and plugin[1]:match("/([%w%-_%.]+)$")) or
          plugin.url:match("/([%w%-_%.]+)$")
    end
  end

  local function add_to_process(plugin)
    local name = get_plugin_name(plugin)
    if name and not processed_plugins[name] then
      table.insert(plugins_to_process, plugin)
      processed_plugins[name] = true
    end
  end

  for _, plugin in ipairs(universal_plugins) do
    add_to_process(plugin)
    if plugin.dependencies then
      for _, dep in ipairs(plugin.dependencies) do
        add_to_process(dep)
      end
    end
    if plugin.requires then
      for _, req in ipairs(plugin.requires) do
        add_to_process(req)
      end
    end
  end
else
  plugins_to_process = universal_plugins
end

local finalized_plugins = {}

for _, plugin in ipairs(plugins_to_process) do
  local cond_ok = true

  -- Check for the new 'exclude' option first
  if plugin.exclude and contains(plugin.exclude, current_manager) then
    cond_ok = false
  end

  if cond_ok and (plugin.min_version or plugin.max_version) then
    cond_ok = should_load_plugin(plugin.min_version, plugin.max_version)
  end
  if cond_ok and plugin.cond then
    cond_ok = plugin.cond()
  end

  if cond_ok then
    local new_plugin
    if current_manager == "lazy" then
      new_plugin = format_for_lazy(plugin)
    elseif current_manager == "packer" then
      new_plugin = format_for_packer(plugin)
    elseif current_manager == "builtin" then
      new_plugin = format_for_builtin(plugin)
    else
      -- Default to lazy format if manager is unknown
      new_plugin = format_for_lazy(plugin)
    end
    table.insert(finalized_plugins, new_plugin)
  end
end

return finalized_plugins
