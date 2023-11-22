local M = {}

-- Shorten function names
local actions = require('telescope.actions')
local fb_actions = require('telescope').extensions.file_browser.actions
--local builtin = require("telescope.builtin")
--local utils = require("telescope.utils")
--local layout_actions = require("telescope.actions.layout")
--local themes = require('telescope.themes')
local actions_set = require('telescope.actions.set')
local actions_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local config = require('telescope.config').values

require('telescope').setup({
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',
      '--fixed-strings',
      '--trim',
    },
    prompt_prefix = ' ',
    selection_caret = ' ',
    entry_prefix = '  ',
    path_display = { 'tail' },
    --path_display = { "truncate" },
    --path_display = { "smart" },
    file_ignore_patterns = {
      'packer_compiled.lua',
      '~/.config/zsh/plugins',
      'zcompdump',
      '%.DS_Store',
      '%.git/',
      '%.spl',
      --"%.log",
      '%[No Name%]', -- new files / sometimes folders (netrw)
      '/$',          -- ignore folders (netrw)
      'node_modules',
      '%.png',
      '%.zip',
      '%.pxd',
      --"^.vim/",
      '^.local/',
      '^.cache/',
      '^downloads/',
      '^music/',
      --"^node_modules/",
      --"^undodir/",
    },
    mappings = {
      i = {
        ['<C-n>'] = actions.cycle_history_next,
        ['<C-p>'] = actions.cycle_history_prev,

        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,

        --["<C-c>"] = actions.close,
        ['<Esc>'] = actions.close,   -- close w/ one esc
        --["<Esc>"] = "close", -- close w/ one esc
        ['<?>'] = actions.which_key, -- keys from pressing <C-/>

        ['<Down>'] = actions.move_selection_next,
        ['<Up>'] = actions.move_selection_previous,

        ['<CR>'] = actions.select_default,
        ['<C-x>'] = actions.select_horizontal,
        ['<C-y>'] = actions.select_vertical,
        ['<C-t>'] = actions.select_tab,
        ['<C-c>'] = actions.delete_buffer,

        ['<C-u>'] = actions.preview_scrolling_up,
        ['<C-d>'] = actions.preview_scrolling_down,

        ['<PageUp>'] = actions.results_scrolling_up,
        ['<PageDown>'] = actions.results_scrolling_down,

        ['<Tab>'] = actions.toggle_selection + actions.move_selection_worse,
        ['<S-Tab>'] = actions.toggle_selection + actions.move_selection_better,
        ['<C-q>'] = actions.send_to_qflist + actions.open_qflist,
        ['<M-q>'] = actions.send_selected_to_qflist + actions.open_qflist,
        ['<C-l>'] = actions.complete_tag,
        ['<C-_>'] = actions.which_key, -- keys from pressing <C-/>
        --["<C-o>"] = function(prompt_bufnr)
        --	local selection = require("telescope.actions.state").get_selected_entry()
        --	local dir = vim.fn.fnamemodify(selection.path, ":p:h")
        --	require("telescope.actions").close(prompt_bufnr)
        --	-- Depending on what you want put `cd`, `lcd`, `tcd`
        --	vim.cmd(string.format("silent lcd %s", dir))
        --end,
      },
      n = {
        --["cd"] = function(prompt_bufnr)
        --  local selection = require("telescope.actions.state").get_selected_entry()
        --  local dir = vim.fn.fnamemodify(selection.path, ":p:h")
        --  require("telescope.actions").close(prompt_bufnr)
        --  -- Depending on what you want put `cd`, `lcd`, `tcd`
        --  vim.cmd(string.format("silent lcd %s", dir))
        --end,
        ['<esc>'] = actions.close,
        ['<q>'] = actions.close,
        ['<CR>'] = actions.select_default,
        ['<C-x>'] = actions.select_horizontal,
        ['<C-y>'] = actions.select_vertical,
        ['<C-t>'] = actions.select_tab,
        ['<C-c>'] = actions.delete_buffer,

        ['<Tab>'] = actions.toggle_selection + actions.move_selection_worse,
        ['<S-Tab>'] = actions.toggle_selection + actions.move_selection_better,
        ['<C-q>'] = actions.send_to_qflist + actions.open_qflist,
        ['<M-q>'] = actions.send_selected_to_qflist + actions.open_qflist,

        ['j'] = actions.move_selection_next,
        ['k'] = actions.move_selection_previous,
        ['H'] = actions.move_to_top,
        ['M'] = actions.move_to_middle,
        ['L'] = actions.move_to_bottom,

        ['<Down>'] = actions.move_selection_next,
        ['<Up>'] = actions.move_selection_previous,
        ['gg'] = actions.move_to_top,
        ['G'] = actions.move_to_bottom,

        ['<C-u>'] = actions.preview_scrolling_up,
        ['<C-d>'] = actions.preview_scrolling_down,

        ['<PageUp>'] = actions.results_scrolling_up,
        ['<PageDown>'] = actions.results_scrolling_down,
        ['cd'] = function(prompt_bufnr)
          local selection = require('telescope.actions.state').get_selected_entry()
          local dir = vim.fn.fnamemodify(selection.path, ':p:h')
          require('telescope.actions').close(prompt_bufnr)
          -- Depending on what you want put `cd`, `lcd`, `tcd`
          vim.cmd(string.format('silent lcd %s', dir))
        end,
        ['?'] = actions.which_key,
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
  selection_strategy = 'reset',
  sorting_strategy = 'ascending',
  scroll_strategy = 'limit',
  color_devicons = true,
  layout_strategy = 'horizontal',
  layout_config = {
    horizontal = {
      height = 0.95,
      preview_cutoff = 70,
      width = 0.92,
      preview_width = { 0.55, max = 50 },
    },
    bottom_pane = {
      height = 12,
      preview_cutoff = 70,
      prompt_position = 'bottom',
    },
  },
  find_files = {
    --cwd = '%:p:h',
    cwd = vim.fn.getcwd(),
    prompt_prefix = ' ',
    --hidden = true,
    --no_ignore = false,
    follow = true,
  },
  --pickers = {
  --  live_grep = {
  --    disable_coordinates = true,
  --    layout_config = {
  --      horizontal = {
  --        preview_width = 0.55,
  --      },
  --    },
  --  },
  --},
  --pickers = {
  --  live_grep = {
  --    mappings = {
  --      i = {
  --        ["<C-f>"] = ts_select_dir_for_grep,
  --      },
  --      n = {
  --        ["<C-f>"] = ts_select_dir_for_grep,
  --      },
  --    },
  --  },
  --},
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
      theme = 'dropdown',
      -- disables netrw and use telescope-file-browser in its place
      hijack_netrw = false,
      mappings = {
        -- your custom insert mode mappings
        ['i'] = {
          ['<C-w>'] = function()
            vim.cmd('normal vbd')
          end,
          ['<C-h>'] = fb_actions.goto_parent_dir,
        },
        ['n'] = {
          -- your custom normal mode mappings
          ['N'] = fb_actions.create,
          ['<C-h>'] = fb_actions.goto_parent_dir,
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
require('telescope').load_extension('file_browser')
require('telescope').load_extension('changed_files')
require('telescope').load_extension('media_files')
require('telescope').load_extension('notify')
require('telescope').load_extension('dap')
require('telescope').load_extension('session-lens')
require('telescope').load_extension('flutter')
require('telescope').load_extension('recent_files')
--require('telescope').load_extension('projects')

--M.curbuf = function(opts)
--  opts = opts
--      or themes.get_dropdown({
--        previewer = false,
--        shorten_path = false,
--        border = true,
--      })
--  require("telescope.builtin").current_buffer_fuzzy_find(opts)
--end

function M.find_configs()
  -- Track dotfiles (bare git repository)
  -- Inside shell config file:
  --  alias config='git --git-dir=$HOME/.cfg --work-tree=$HOME'
  --  cfg_files=$(config ls-tree --name-only -r HEAD)
  --  export CFG_FILES="$cfg_files"
  local tracked_files = {}

  for file in string.gmatch(os.getenv('CFG_FILES'), '[^\n]+') do
    table.insert(tracked_files, os.getenv('HOME') .. '/' .. file)
  end

  require('telescope.builtin').find_files({
    hidden = true,
    no_ignore = false,
    prompt_title = ' Find Configs',
    results_title = 'Config Files',
    path_display = { 'smart' },
    search_dirs = tracked_files,
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_scripts()
  require('telescope.builtin').find_files({
    hidden = true,
    no_ignore = true,
    prompt_title = ' Find Scripts',
    path_display = { 'smart' },
    search_dirs = {
      '~/.scripts',
    },
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_projects()
  local search_dir = '~/projects'
  pickers
      .new({}, {
        prompt_title = 'Find Projects',
        finder = finders.new_oneshot_job({
          'find',
          vim.fn.expand(search_dir),
          '-type',
          'd',
          '-maxdepth',
          '1',
        }),
        previewer = require('telescope.previewers').vim_buffer_cat.new({}),
        sorter = config.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions_set.select:replace(function()
            local entry = actions_state.get_selected_entry()
            if entry ~= nil then
              local dir = entry.value
              actions.close(prompt_bufnr, false)
              vim.fn.chdir(dir)
              vim.cmd('e .')
              vim.cmd("echon ''")
              print('cwd: ' .. vim.fn.getcwd())
            end
          end)
          return true
        end,
      })
      :find()
end

function M.grep_notes()
  local opts = {}
  opts.hidden = false
  opts.search_dirs = {
    '~/documents/notes/',
  }
  opts.prompt_prefix = '   '
  opts.prompt_title = ' Grep Notes'
  opts.path_display = { 'smart' }
  require('telescope.builtin').live_grep(opts)
end

function M.find_notes()
  require('telescope.builtin').find_files({
    hidden = true,
    no_ignore = false,
    prompt_title = ' Find Notes',
    path_display = { 'smart' },
    search_dirs = {
      '~/documents/notes/private/',
      '~/documents/notes',
    },
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_private()
  require('telescope.builtin').find_files({
    hidden = true,
    no_ignore = false,
    prompt_title = ' Find Notes',
    path_display = { 'smart' },
    search_dirs = {
      '~/notes/private',
      '~/notes',
    },
    layout_strategy = 'horizontal',
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_books()
  local search_dir = '~/documents/books'
  vim.fn.jobstart('$HOME/.scripts/track-books.sh')
  local recent_books_directory = vim.fn.stdpath('config') .. '/tmp/'
  local recent_books_file = recent_books_directory .. 'recent_books.txt'
  local search_cmd = 'find ' .. vim.fn.expand(search_dir) .. ' -type d -o -type f -maxdepth 1'

  local recent_books = vim.fn.readfile(recent_books_file)
  local search_results = vim.fn.systemlist(search_cmd)

  local results = {}

  -- Section for Recent Books
  table.insert(results, ' Recent Books')
  for _, recent_book_path in ipairs(recent_books) do
    local formatted_path = vim.fn.fnameescape(recent_book_path)
    table.insert(results, formatted_path)
  end

  -- Section for All Books
  table.insert(results, ' All Books')
  local directories = {}
  local files = {}

  for _, search_result in ipairs(search_results) do
    if vim.fn.isdirectory(search_result) == 1 then
      table.insert(directories, search_result)
    else
      table.insert(files, search_result)
    end
  end

  table.sort(directories)
  table.sort(files)

  for _, dir in ipairs(directories) do
    table.insert(results, dir)
  end

  for _, file in ipairs(files) do
    table.insert(results, file)
  end

  local picker = pickers.new({}, {
    prompt_title = 'Find Books',
    finder = finders.new_table({
      results = results,
    }),
    file_ignore_patterns = {
      '%.git',
    },
    previewer = require('telescope.previewers').vim_buffer_cat.new({}),
    sorter = config.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions_set.select:replace(function()
        local entry = actions_state.get_selected_entry()
        if entry ~= nil then
          local path = entry.value

          actions.close(prompt_bufnr, false)

          -- Check if it's under "Recent Books"
          if path == ' Recent Books' or path == ' All Books' then
            vim.notify("Cannot select 'All Books'/'Recent Books', please select a book or directory.", vim.log.levels.WARN, { title = 'Find Books' })
          else
            -- Determine whether it's a directory or a file
            local is_directory = vim.fn.isdirectory(path)
            if is_directory then
              -- It's a directory, navigate to it in the current buffer
              vim.cmd('e ' .. path)
            else
              -- It's a file, open it
              vim.cmd('e ' .. path)
            end
          end
        end
      end)
      return true
    end,
  })

  picker:find()
end

function M.grep_current_dir()
  local buffer_dir = require('telescope.utils').buffer_dir()
  local opts = {
    prompt_title = 'Live Grep in ' .. buffer_dir,
    cwd = buffer_dir,
  }
  require('telescope.builtin').live_grep(opts)
end

--------------------------------------------------------------------------------

local dropdown = require('telescope.themes').get_dropdown({
  hidden = true,
  no_ignore = true,
  previewer = false,
  prompt_title = '',
  preview_title = '',
  results_title = '',
  layout_config = {
    --anchor = "S",
    prompt_position = 'top',
  },
})

-- File browser always relative to buffer
--local opts_file_browser = vim.tbl_extend('force', dropdown, {
--  path_display = { '%:p:h' },
--})

-- Set current folder as prompt title
local with_title = function(opts, extra)
  extra = extra or {}
  local path = opts.cwd or opts.path or extra.cwd or extra.path or nil
  local title = ''
  local buf_path = vim.fn.expand('%:p:h')
  local cwd = vim.fn.getcwd()
  if path ~= nil and buf_path ~= cwd then
    title = require('plenary.path'):new(buf_path):make_relative(cwd)
  else
    title = vim.fn.fnamemodify(cwd, ':t')
  end

  return vim.tbl_extend('force', opts, {
    prompt_title = title,
  }, extra or {})
end

-- Find here
function M.findhere()
  -- Open file browser if argument is a folder
  local arg = vim.api.nvim_eval('argv(0)')
  if arg and (vim.fn.isdirectory(arg) ~= 0 or arg == '') then
    vim.defer_fn(function()
      require('telescope.builtin').find_files(with_title(dropdown))
      --      require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({
      --        hidden = true,
      --        results_title = '',
      --        layout_config = { prompt_position = 'top' },
      --      }))
    end, 10)
  end
end

-- Define the custom command findhere/startup
vim.cmd('command! Findhere lua require("plugins.telescope").findhere()')
--vim.cmd('command! Startup lua require("plugins.telescope").findhere()')
--vim.api.nvim_command('autocmd VimEnter * lua require("plugins/telescope").findhere()')

-- Find dirs
function M.find_dirs()
  local root_dir = vim.fn.input('Enter the root directory: ')

  -- Check if root_dir is empty
  if root_dir == '' then
    print('No directory entered. Aborting.')
    return
  end

  local entries = {}

  -- Use vim.fn.expand() to get an absolute path
  local root_path = vim.fn.expand(root_dir)

  local subentries = vim.fn.readdir(root_path)
  if subentries then
    for _, subentry in ipairs(subentries) do
      local absolute_path = root_path .. '/' .. subentry
      table.insert(entries, subentry)
    end
  end

  pickers
      .new({}, {
        prompt_title = 'Change Directory or Open File',
        finder = finders.new_table({
          results = entries,
        }),
        previewer = config.file_previewer({}),
        sorter = config.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions_set.select:replace(function()
            local entry = actions_state.get_selected_entry()
            if entry ~= nil then
              local selected_entry = entry.value
              actions.close(prompt_bufnr, false)
              local selected_path = root_path .. '/' .. selected_entry
              if vim.fn.isdirectory(selected_path) == 1 then
                vim.fn.chdir(selected_path)
                vim.cmd('e .')
                print('cwd: ' .. vim.fn.getcwd())
              else
                vim.cmd('e ' .. selected_path)
              end
            end
          end)
          return true
        end,
      })
      :find()
end

return M
