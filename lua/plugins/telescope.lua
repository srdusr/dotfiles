local M = {}
-- Shorten function names
local actions = require("telescope.actions")
local fb_actions = require("telescope").extensions.file_browser.actions
local builtin = require("telescope.builtin")
local themes = require("telescope.themes")
local utils = require("telescope.utils")
local action_state = require("telescope.actions.state")
local layout_actions = require("telescope.actions.layout")


require('telescope').setup({
	defaults = {
    vimgrep_arguments = {
      "rg",
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
      "--smart-case",
      "--hidden",
      "--fixed-strings",
      "--trim",
    },
		prompt_prefix = " ",
		selection_caret = " ",
		entry_prefix = "  ",
		path_display = { "tail" },
    --path_display = { "truncate" },
		--path_display = { "smart" },
		file_ignore_patterns = {
			"packer_compiled.lua",
			"%.DS_Store",
			"%.git/",
			"%.spl",
			"%.log",
			"%[No Name%]", -- new files / sometimes folders (netrw)
			"/$", -- ignore folders (netrw)
			"node_modules",
			"%.png",
			"%.zip",
			"%.pxd",
      "^.vim/",
      "^.local/",
      "^.cache/",
      "^downloads/",
      --"^node_modules/",
      --"^undodir/",
		},
		mappings = {
					i = {
				["<C-n>"] = actions.cycle_history_next,
				["<C-p>"] = actions.cycle_history_prev,

				["<C-j>"] = actions.move_selection_next,
				["<C-k>"] = actions.move_selection_previous,

				["<C-c>"] = actions.close,
				["<Esc>"] = actions.close, -- close w/ one esc
				--["<Esc>"] = "close", -- close w/ one esc
				["<?>"] = actions.which_key, -- keys from pressing <C-/>

				["<Down>"] = actions.move_selection_next,
				["<Up>"] = actions.move_selection_previous,

				["<CR>"] = actions.select_default,
				["<C-x>"] = actions.select_horizontal,
				["<C-y>"] = actions.select_vertical,
				["<C-t>"] = actions.select_tab,

				["<C-u>"] = actions.preview_scrolling_up,
				["<C-d>"] = actions.preview_scrolling_down,

				["<PageUp>"] = actions.results_scrolling_up,
				["<PageDown>"] = actions.results_scrolling_down,

				["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
				["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
				["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
				["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
				["<C-l>"] = actions.complete_tag,
				["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
				--["<C-o>"] = function(prompt_bufnr)
				--	local selection = require("telescope.actions.state").get_selected_entry()
				--	local dir = vim.fn.fnamemodify(selection.path, ":p:h")
				--	require("telescope.actions").close(prompt_bufnr)
				--	-- Depending on what you want put `cd`, `lcd`, `tcd`
				--	vim.cmd(string.format("silent lcd %s", dir))
				--end,
			},

			n = {
				["<esc>"] = actions.close,
        ["<q>"] = actions.close,
				["<CR>"] = actions.select_default,
				["<C-x>"] = actions.select_horizontal,
				["<C-y>"] = actions.select_vertical,
				["<C-t>"] = actions.select_tab,

				["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
				["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
				["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
				["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

				["j"] = actions.move_selection_next,
				["k"] = actions.move_selection_previous,
				["H"] = actions.move_to_top,
				["M"] = actions.move_to_middle,
				["L"] = actions.move_to_bottom,

				["<Down>"] = actions.move_selection_next,
				["<Up>"] = actions.move_selection_previous,
				["gg"] = actions.move_to_top,
				["G"] = actions.move_to_bottom,

				["<C-u>"] = actions.preview_scrolling_up,
				["<C-d>"] = actions.preview_scrolling_down,

				["<PageUp>"] = actions.results_scrolling_up,
				["<PageDown>"] = actions.results_scrolling_down,

				["?"] = actions.which_key,
				--["<C-o>"] = function(prompt_bufnr)
				--	local selection = require("telescope.actions.state").get_selected_entry()
				--	local dir = vim.fn.fnamemodify(selection.path, ":p:h")
				--	require("telescope.actions").close(prompt_bufnr)
				--	-- Depending on what you want put `cd`, `lcd`, `tcd`
				--	vim.cmd(string.format("silent lcd %s", dir))
				--end,
			},
		},
	},
    preview = {
      filesize_limit = 3,
      timeout = 250,
    },
    selection_strategy = "reset",
    sorting_strategy = "ascending",
    scroll_strategy = "limit",
    color_devicons = true,
		layout_strategy = 'horizontal',
		layout_config = {
			horizontal = {
				height = 0.95,
				preview_cutoff = 70,
				width = 0.92,
				preview_width = {0.55, max = 50}
			},
			bottom_pane = {
				height = 12,
				preview_cutoff = 70,
				prompt_position = "bottom",
			},
		},
  pickers = {
    live_grep = {
      disable_coordinates = true,
      layout_config = {
        horizontal = {
          preview_width = 0.55,
        },
      },
    },
  },
	--pickers = {
		--lsp_references = {
		--	prompt_prefix='⬅️',
		--	show_line=false,
		--	trim_text=true,
		--	include_declaration=false,
		--	initial_mode = "normal",
		--},
		--lsp_definitions = {
		--	prompt_prefix='➡️',
		--	show_line=false,
		--	trim_text=true,
		--	initial_mode = "normal",
		--},
		--lsp_document_symbols = {
		--	prompt_prefix='* ',
		--	show_line = false,
		--},
		--treesitter = {
		--	prompt_prefix=' ',
		--	show_line = false,
		--},
		--find_files = {
		--	cwd='%:p:h',
		--	prompt_prefix=' ',
		--	hidden = true,
		--	follow = true,
		--},
		--keymaps = { prompt_prefix='? ' },
		--oldfiles = { prompt_prefix=' ' },
		--highlights = { prompt_prefix=' ' },
		--git_files = {
		--	prompt_prefix=' ',
		--	show_untracked = true,
		--	path_display = { "tail" },
		--},
		--buffers = {
		--	prompt_prefix=' ',
		--	ignore_current_buffer = true,
		--	initial_mode = "normal",
		--	sort_mru = true,
		--},
		--live_grep = {
		--	cwd='%:p:h',
		--	disable_coordinates=true,
		--	prompt_title='Search in Folder',
		--	prompt_prefix=' ',
		--},
		--spell_suggest = {
		--	initial_mode = "normal",
		--	prompt_prefix = "暈",
		--	theme = "cursor",
		--	layout_config = { cursor = { width = 0.3 } }
		--},
		--colorscheme = {
		--	enable_preview = true,
		--	prompt_prefix = '',
		--	results_title = '',
		--	layout_strategy = "bottom_pane",
		--},
	--},

	extensions = {
		file_browser = {
			theme = "dropdown",
			-- disables netrw and use telescope-file-browser in its place
			hijack_netrw = true,
			mappings = {
				-- your custom insert mode mappings
				["i"] = {
					["<C-w>"] = function()
						vim.cmd("normal vbd")
					end,
          --["<C-h>"] = fb_actions.goto_parent_dir,
				},
				["n"] = {
					-- your custom normal mode mappings
					["N"] = fb_actions.create,
					--["<C-h>"] = fb_actions.goto_parent_dir,
					--["/"] = function()
					--	vim.cmd("startinsert")
					--end,
				},
      },
    },
  },
})

--------------------------------------------------------------------------------

-- Load extensions:
-- have to be loaded after telescope setup/config
require('telescope').load_extension('fzf')
require('telescope').load_extension('ui-select')
require("telescope").load_extension("file_browser")
require('telescope').load_extension('changed_files')
require('telescope').load_extension('media_files')
--require('telescope').extensions.notify.notify()
require('telescope').load_extension('notify')

function M.find_configs()
  require("telescope.builtin").find_files {
    hidden = true,
    no_ignore = false,
    prompt_title = " Find Configs",
    results_title = "Config Files",
    path_display = { "smart" },
    search_dirs = {
      "~/.config/nvim",
      "~/.config/zsh",
      "~/.config/tmux",
      "~/.config/X11",
      "~/.config/alacritty",
      "~/.config/kitty",
      "~/.config/wezterm",
      "~/.config/bspwm",
      "~/.config/sxhkd",
      "~/.config/picom",
    },
    -- cwd = "~/.config/nvim/",
    file_ignore_patterns = {
      "~/.config/nvim/startup.log",
      "packer_compiled.lua",
      "resurrect",
      "tmux/plugins",
      --"^~/.config/tmux/plugins",
      "%.txt",
      ".git",
    },
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.65, width = 0.75 },
  }
end

function M.find_scripts()
  require("telescope.builtin").find_files {
    hidden = false,
    prompt_title = " Find Notes",
    path_display = { "smart" },
    search_dirs = {
      "~/.local/bin/scripts",
    },
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.65, width = 0.75 },
  }
end

function M.grep_notes()
  local opts = {}
  opts.hidden = false
  opts.search_dirs = {
    "~/documents/notes/",
  }
  opts.prompt_prefix = "   "
  opts.prompt_title = " Grep Notes"
  opts.path_display = { "smart" }
  require("telescope.builtin").live_grep(opts)
end

function M.find_notes()
  require("telescope.builtin").find_files {
    hidden = false,
    prompt_title = " Find Notes",
    path_display = { "smart" },
    search_dirs = {
      "~/documents/notes/private/",
      "~/documents/notes",
    },
    --cwd = "~documents/notes",
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.65, width = 0.75 },
  }
end

function M.file_explorer()
  require("telescope.builtin").file_browser({
    prompt_title = "File Browser",
    cwd = "~",
    layout_strategy = "horizontal",
  })
end

function M.grep_current_dir()
  local buffer_dir = require("telescope.utils").buffer_dir()
  local opts = {
    prompt_title = "Live Grep in " .. buffer_dir,
    cwd = buffer_dir,
  }
  require("telescope.builtin").live_grep(opts)
end

return M
