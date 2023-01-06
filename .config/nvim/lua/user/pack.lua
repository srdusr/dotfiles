local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost pack.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	auto_reload_compiled = true,
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- Install your plugins here
return packer.startup(function(use)
	use("wbthomason/packer.nvim") -- Have packer manage itself

	use("lewis6991/impatient.nvim")
  use("nvim-lua/plenary.nvim") -- Useful lua functions used ny lots of plugins
	--use("jose-elias-alvarez/null-ls.nvim")

    -- lsp
    use {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    }
    require("mason").setup()
    local mason_lspconfig = require("mason-lspconfig")
    mason_lspconfig.setup({
      ensure_installed = {
        "pylsp",
        "pyright",
        "clangd",
        --"vim-language-server",
        --"bash-language-server",
        --"lua-language-server",
        "sumneko_lua",
      }
    })
    use({ "j-hui/fidget.nvim",
      config = function()
        require("fidget").setup()
      end
    })
    --use({ "folke/trouble.nvim",
    --  config = function()
    --    require("trouble").setup({ position = "right", })
    --  end
    --})
  	--use({
		--"folke/trouble.nvim",
		--requires = "kyazdani42/nvim-web-devicons",
		--config = function()
		--	require("trouble").setup({
    --    --postion = "top",
    --    postion = "right",
		--		-- your configuration comes here
		--		-- or leave it empty to use the default settings
		--		-- refer to the configuration section below
		--	})
		--end,
    --})

    --use({
    --  "https://git.sr.ht/~whynothugo/lsp_lines.nvim", -- See also: https://github.com/Maan2003/lsp_lines.nvim
    --  config = function()
    --    require("lsp_lines").setup()

    --    -- disable virtual_text since it's redundant due to lsp_lines.
    --    vim.diagnostic.config({
    --      virtual_text = false,
    --    })
    --  end,
    --})
    use { "simrat39/symbols-outline.nvim",
      config = function()
        require("symbols-outline").setup({
          auto_close = true,
        })
      end
    }
    use "antoinemadec/FixCursorHold.nvim"
    use { "kosayoda/nvim-lightbulb", requires = { "antoinemadec/FixCursorHold.nvim" } }
    --use("folke/lsp-colors.nvim")
    use "mfussenegger/nvim-lint"
    use "weilbith/nvim-code-action-menu"
    use "simrat39/rust-tools.nvim"
    use { "saecki/crates.nvim",
      requires = { "nvim-lua/plenary.nvim" },
      config = function()
        require("crates").setup()
      end,
    }
    --use "lvimuser/lsp-inlayhints.nvim" -- rust-tools already provides this feature, but gopls doesn't

    -- null-ls
    --use({ "jose-elias-alvarez/null-ls.nvim",
    --  config = function()
    --    require("null-ls").setup({
    --      sources = {
    --        require("null-ls").builtins.diagnostics.checkmake, -- https://github.com/mrtazz/checkmake
    --      }
    --    })
    --  end
    --})
  	use({
		"jose-elias-alvarez/null-ls.nvim",
		config = function()
			require("null-ls").setup()
		end,
		requires = { "nvim-lua/plenary.nvim" },
	})
  	use({
		"SmiteshP/nvim-navic",
		requires = "neovim/nvim-lspconfig",
	})

	-- nvimlsp plugins
	--use({
	--  "williamboman/mason.nvim",
	--  config = function()
	--    require("mason").setup()
	--    require("mason-lspconfig").setup({
	--      ensure_installed = { "sumneko_lua", "clangd", "rust_analyzer" },
	--    })
	--  end,
	--})
	--use("williamboman/mason.nvim")
	--use("williamboman/mason-lspconfig.nvim")
	--use("neovim/nvim-lspconfig")
	--use("williamboman/nvim-lsp-installer")
	--use("glepnir/lspsaga.nvim")
	--use("nvim-lua/lsp-status.nvim")
	--use({
	--  "glepnir/lspsaga.nvim",
	--  branch = "main",
	--  config = function()
	--    local saga = require("lspsaga")

	--    saga.init_lsp_saga({
	--      -- your configuration
	--    })
	--  end,
	--})
	-- use("nvim-lua/popup.nvim")
	--use("SmiteshP/nvim-gps")
	--  autocomplete plugins
	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-cmdline")
  use("petertriho/cmp-git")
	use("tamago324/cmp-zsh")
	use("f3fora/cmp-spell")
	use("hrsh7th/cmp-calc")
	use("saadparwaiz1/cmp_luasnip")
	use("hrsh7th/cmp-nvim-lsp-signature-help")
	use("onsails/lspkind-nvim")

	-- snippets
	--use("L3MON4D3/LuaSnip") --snippet engine
  use("L3MON4D3/LuaSnip")
	use("rafamadriz/friendly-snippets") -- a bunch of snippets to use
	--use("github/copilot.vim")
	--use({
	--"zbirenbaum/copilot.lua",
	--event = { "VimEnter" },
	--config = function()
	--vim.defer_fn(function()
	--require("plugins.copilot")
	--end, 100)
	--end,
	--})
	--use({
	--"zbirenbaum/copilot-cmp",
	--module = "copilot_cmp",
	--})

	-- treesitter plugins
	use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }) --folding, jumping, refactoring...
	use("nvim-treesitter/nvim-treesitter-refactor")
	use("nvim-treesitter/nvim-treesitter-context")
	--use({
	--	"danymat/neogen",
	--	config = function()
	--		require("neogen").setup({ snippet_engine = "luasnip" })
	--	end,
	--	requires = "nvim-treesitter/nvim-treesitter",
	--})
	--use({ "junegunn/fzf", run = ":call fzf#install()" })
	use('ibhagwan/fzf-lua')
	-- telescope plugins
	use("nvim-telescope/telescope.nvim")
	use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
	use("tami5/sqlite.lua")
	--use("nvim-telescope/telescope-frecency.nvim")
	use("nvim-telescope/telescope-ui-select.nvim")
	use("nvim-telescope/telescope-media-files.nvim")
	use("nvim-telescope/telescope-file-browser.nvim")
	-- search emoji and other symbols
	use({ "nvim-telescope/telescope-symbols.nvim", after = "telescope.nvim" })
	use("axkirillov/telescope-changed-files")
	--use({
  --"princejoogie/dir-telescope.nvim",
  --requires = {"nvim-telescope/telescope.nvim"},
  --config = function()
  --  require("dir-telescope").setup({
  --    hidden = true,
  --    respect_gitignore = true,
  --  })
  --end,
  --})
  use("airblade/vim-rooter")
	-- statusline plugins
	--use("nvim-lualine/lualine.nvim")
	--use({
	--	"nvim-lualine/lualine.nvim",
	--	requires = { "kyazdani42/nvim-web-devicons", opt = true },
	--})
	--use({
	--	"folke/trouble.nvim",
	--	requires = "kyazdani42/nvim-web-devicons",
	--	config = function()
	--		require("trouble").setup({
	--			-- your configuration comes here
	--			-- or leave it empty to use the default settings
	--			-- refer to the configuration section below
	--		})
	--	end,
	--})
	use("rebelot/heirline.nvim")
	--use({ "akinsho/bufferline.nvim", tag = "v2.*", requires = "kyazdani42/nvim-web-devicons" })
	--use("itchyny/lightline.vim")
	-- debug plugins
	--use("puremourning/vimspector")
	use("mfussenegger/nvim-dap")
	use("rcarriga/nvim-dap-ui")
	--use({
	--      "rcarriga/neotest",
	--      requires = {
	--          "nvim-lua/plenary.nvim",
	--          "nvim-treesitter/nvim-treesitter",
	--          "antoinemadec/FixCursorHold.nvim",
	--          "rcarriga/neotest-python",
	--          "rcarriga/neotest-vim-test",
	--          "rcarriga/neotest-plenary",
	--          "vim-test/vim-test",
	--      },
	--      config = function()
	--          require("plugins.neotest")
	--      end,
	--})
	--use("vim-test/vim-test")
	--use({
	--  "rcarriga/vim-ultest",
	--  requires = { "vim-test/vim-test" },
	--  run = ":UpdateRemotePlugins",
	--  config = function()
	--    require("plugins.ultest")
	--  end,
	--})
	-- UI
	use("karb94/neoscroll.nvim")
	use("folke/which-key.nvim")
	use("MunifTanjim/prettier.nvim") -- Prettier plugin for Neovim's built-in LSP client
	use("norcalli/nvim-colorizer.lua")
	use("folke/zen-mode.nvim")
	use("romainl/vim-cool")
	--use("p00f/nvim-ts-rainbow")
	--use("goolord/alpha-nvim")
	--use("feline-nvim/feline.nvim")
	--use({ "fgheng/winbar.nvim" })
	--use("vim-airline/vim-airline")
	--use("kdheepak/tabline.nvim")
	-- use({
	--   "kdheepak/tabline.nvim",
	--   config = function()
	--     require("tabline").setup({ enable = false })
	--   end,
	--   requires = { "hoob3rt/lualine.nvim", "kyazdani42/nvim-web-devicons" },
	-- notification plugin
	use("rcarriga/nvim-notify")
	--use("lukas-reineke/indent-blankline.nvim")
	use("kyazdani42/nvim-web-devicons")
	-- Colorschemes
	use("gruvbox-community/gruvbox")
	use("srcery-colors/srcery-vim")
	use("tomasr/molokai")
	use("ayu-theme/ayu-vim")
	--use("sjl/badwolf")
	use("joshdick/onedark.vim")
	use("everblush/everblush.nvim")
	use("EdenEast/nightfox.nvim")
	use("bluz71/vim-nightfly-guicolors")
	--use({ "shaunsingh/oxocarbon.nvim", run = "./install.sh" })
	use("jacoborus/tender.vim")
	use("sainnhe/sonokai")
	use("NTBBloodbath/doom-one.nvim")

	-- Utilities
	use("nathom/filetype.nvim")
	use("christoomey/vim-tmux-navigator")
	use("preservim/vimux")
	use("myusuf3/numbers.vim")
	use("windwp/nvim-autopairs")
	use("lewis6991/gitsigns.nvim")
	use("dinhhuy258/git.nvim") -- For git blame & browse
  use("kdheepak/lazygit.nvim")
	use("kyazdani42/nvim-tree.lua")
	use("numToStr/Comment.nvim")
	use("akinsho/toggleterm.nvim")
	--use("godlygeek/tabular")
	--use("Vonr/align.nvim")
	--use("junegunn/vim-easy-align")
	--use("dstein64/vim-startuptime")
	use("tweekmonster/startuptime.vim")
	-- use("luukvbaal/stabilize.nvim")
  --use("rhysd/clever-f.vim")
  --use("ggandor/lightspeed.nvim") -- use 'cl' and 'cc' instead of 's' and 'S' respectively
  --use("ggandor/leap.nvim")
	use({
	  "ggandor/leap.nvim",
	  config = function()
      require('leap').add_default_mappings()
	    --require("leap").set_default_keymaps()
      --vim.keymap.set('n', '-', '<Plug>(leap-forward)', {})
      --vim.keymap.set('n', '_', '<Plug>(leap-backward)', {})
	  end,
	})
  use({ "ggandor/flit.nvim",
    config = function()
      require("flit").setup()
    end,
  })

	--use("Shatur/neovim-session-manager")
	--use("rmagatti/auto-session")
	--use("rmagatti/session-lens")
	--use("ahmedkhalf/project.nvim")
	--use("aserowy/tmux.nvim")
	--use("wakatime/vim-wakatime")
	--use("tpope/vim-eunuch")
	-- Handy unix command inside Vim (Rename, Move etc.)
	use({ "tpope/vim-eunuch", cmd = { "Rename", "Delete" } })
	use("tpope/vim-fugitive")
	--use("tpope/vim-surround")
	--use("tpope/vim-obsession")
	--use("tpope/vim-unimpaired")
	--use("voldikss/vim-floaterm")
	--use("vimpostor/vim-tpipeline")
	--use({
	--  "vimwiki/vimwiki",
	--  config = function()
	--    vim.g.vimwiki_list = {
	--      {
	--        path = "~/",
	--        syntax = "markdown",
	--        ext = ".md",
	--      },
	--    }
	--    vim.g.vimwiki_ext2syntax = {
	--      [".md"] = "markdown",
	--      [".markdown"] = "markdown",
	--      [".mdown"] = "markdown",
  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
end)
