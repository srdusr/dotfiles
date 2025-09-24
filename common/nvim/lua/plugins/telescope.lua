local M = {}

-- Safely require a module
-- @param name string The module name to require
-- @return table|nil The loaded module or nil if failed
local function safe_require(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

--- Setup and configure Telescope
-- This function initializes Telescope with default configurations and extensions
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  -- Check if Telescope is installed
  local telescope = safe_require("telescope")
  if not telescope then
    return false
  end
  -- Require Telescope and fail early if missing
  local telescope = safe_require("telescope")
  if not telescope then
    return false
  end

  local actions       = safe_require("telescope.actions")
  local actions_set   = safe_require("telescope.actions.set")
  local actions_state = safe_require("telescope.actions.state")
  local finders       = safe_require("telescope.finders")
  local pickers       = safe_require("telescope.pickers")
  local config_mod    = safe_require("telescope.config")
  local utils         = safe_require("telescope.utils")
  local previewers    = require("telescope.previewers")

  local config = config_mod and config_mod.values or {}

  -- 🛡 Safe previewer to avoid nil path error
  local safe_previewer = function()
    return require("telescope.previewers").new_buffer_previewer({
      define_preview = function(self, entry)
        if not entry or type(entry) ~= "table" then return end

        local path = entry.path or entry.filename or entry.value
        if type(path) ~= "string" or path == "" then return end

        -- Avoid expanding things like " Recent Books" which aren't valid files
        if path:match("^%s") then return end

        -- Resolve tilde if present
        path = path:gsub("^~", vim.env.HOME)

        if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
          return
        end

        -- Protect against nil path being passed further
        if not self.state or not self.state.bufnr or not self.state.bufname then return end

        local preview_utils = require("telescope.previewers.utils")
        preview_utils.buffer_previewer_maker(path, self.state.bufnr, {
          bufname = self.state.bufname,
          callback = function(bufnr, success)
            if not success then
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Failed to preview file." })
            end
          end,
        })
      end,
    })
  end

  local function get_extension_actions(ext)
    local ok, telescope_ext = pcall(require, "telescope._extensions." .. ext)
    if not ok then return {} end
    return telescope_ext.actions or {}
  end

  telescope.setup({
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
      previewer = safe_previewer(),
      prompt_prefix = " ",
      selection_caret = " ",
      entry_prefix = "  ",
      path_display = { "tail" },
      file_ignore_patterns = {
        "packer_compiled.lua",
        "~/.config/zsh/plugins",
        "zcompdump",
        "%.DS_Store",
        "%.git/",
        "%.spl",
        "%[No Name%]",
        "/$",
        "node_modules",
        "%.png",
        "%.zip",
        "%.pxd",
        "^.local/",
        "^.cache/",
        "^downloads/",
        "^music/",
      },
      mappings = {
        i = {
          ["<C-n>"] = actions.cycle_history_next,
          ["<C-p>"] = actions.cycle_history_prev,
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<Esc>"] = actions.close,
          ["<?>"] = actions.which_key,
          ["<Down>"] = actions.move_selection_next,
          ["<Up>"] = actions.move_selection_previous,
          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-y>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,
          ["<C-c>"] = actions.delete_buffer,
          ["<C-u>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,
          ["<PageUp>"] = actions.results_scrolling_up,
          ["<PageDown>"] = actions.results_scrolling_down,
          ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
          ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          ["<C-l>"] = actions.complete_tag,
          ["<C-_>"] = actions.which_key,
        },
        n = {
          ["<esc>"] = actions.close,
          ["<q>"] = actions.close,
          ["<CR>"] = actions.select_default,
          ["<C-x>"] = actions.select_horizontal,
          ["<C-y>"] = actions.select_vertical,
          ["<C-t>"] = actions.select_tab,
          ["<C-c>"] = actions.delete_buffer,
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
          ["cd"] = function(prompt_bufnr)
            local selection = actions_state.get_selected_entry()
            local dir = vim.fn.fnamemodify(selection.path, ":p:h")
            actions.close(prompt_bufnr)
            vim.cmd("silent lcd " .. dir)
          end,
          ["?"] = actions.which_key,
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
    layout_strategy = "horizontal",
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
        prompt_position = "bottom",
      },
    },
    find_files = {
      cwd = vim.fn.getcwd(),
      prompt_prefix = " ",
      follow = true,
    },
    extensions = {
      file_browser = {
        theme = "dropdown",
        hijack_netrw = false,
        mappings = {
          i = {
            ["<C-w>"] = function() vim.cmd("normal vbd") end,
            ["<C-h>"] = function()
              local fb_actions = get_extension_actions("file_browser")
              if fb_actions.goto_parent_dir then
                fb_actions.goto_parent_dir()
              end
            end,
          },
          n = {
            ["N"] = function()
              local fb_actions = get_extension_actions("file_browser")
              if fb_actions.create then
                fb_actions.create()
              end
            end,
            ["<C-h>"] = function()
              local fb_actions = get_extension_actions("file_browser")
              if fb_actions.goto_parent_dir then
                fb_actions.goto_parent_dir()
              end
            end,
          },
        },
      },
    },
  })

  -- Load extensions
  for _, ext in ipairs({
    "fzf", "ui-select", "file_browser", "changed_files",
    "media_files", "notify", "dap", "session-lens", "recent_files"
  }) do
    pcall(telescope.load_extension, ext)
  end

  -- Define the custom command findhere/startup
  vim.cmd('command! Findhere lua require("plugins.telescope").findhere()')

  return true
end

-- Find config files
local function _sys_path(repo_path)
    local home = os.getenv("HOME") or vim.fn.expand("~")

    -- Case 1: Files in the OS-specific home folder (e.g., linux/home/.bashrc)
    if repo_path:find("/home/", 1, true) then
        local file = repo_path:match(".*/home/(.*)")
        return home .. "/" .. file
    -- Case 2: Files in the common folder (e.g., common/README.md)
    elseif repo_path:find("common/", 1, true) then
        local file = repo_path:match("common/(.*)")
        return home .. "/" .. file
    -- Case 3: Root-level files (e.g., profile/profile_script or README.md)
    elseif repo_path:find("profile/", 1, true) or repo_path:find("README.md", 1, true) then
        return home .. "/" .. repo_path
    -- Case 4: System-level files (e.g., linux/etc/issue)
    elseif repo_path:find("/etc/", 1, true) then
        local file = repo_path:match(".*/etc/(.*)")
        return "/etc/" .. file
    -- Return nil for paths that don't match any known pattern
    else
        return nil
    end
end

function M.find_configs()
    local telescope_builtin = require("telescope.builtin")
    local tracked_files = {}
    local home = os.getenv("HOME") or "~"
    local original_dir = vim.fn.getcwd()
    vim.fn.chdir(home)

    vim.api.nvim_create_autocmd("VimLeave", {
        callback = function()
            vim.fn.chdir(original_dir)
        end,
    })

    -- Check if the bare repository exists
    if vim.fn.isdirectory(home .. "/.cfg") == 1 then
        -- Repository exists, use git to find tracked files
        local handle = io.popen("git --git-dir=" .. home .. "/.cfg --work-tree=" .. home .. " ls-tree --name-only -r HEAD")
        local cfg_files = ""
        if handle then
            cfg_files = handle:read("*a") or ""
            handle:close()
        end

        -- Process the list of files
        for file in string.gmatch(cfg_files, "[^\n]+") do
            file = vim.trim(file)
            if file ~= "" then
                local fullpath = _sys_path(file)
                if fullpath and (vim.fn.filereadable(fullpath) == 1 or vim.fn.isdirectory(fullpath) == 1) then
                    table.insert(tracked_files, fullpath)
                end
            end
        end
    end

    -- If no files were found (either no repo or no tracked files), use fallback paths
    if #tracked_files == 0 then
        local fallback_dirs = {
            home .. "/.config/nvim",
            home .. "/.config/zsh",
            home .. "/.config/tmux",
            home .. "/.bashrc",
            home .. "/.zshrc",
            home .. "/.tmux.conf",
        }
        for _, path in ipairs(fallback_dirs) do
            if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
                table.insert(tracked_files, path)
            end
        end
    end

    if #tracked_files == 0 then
        vim.notify("[find_configs] No configuration files found to search.", vim.log.levels.WARN)
        return
    end

    -- Launch Telescope
    telescope_builtin.find_files({
        hidden = true,
        no_ignore = false,
        prompt_title = " Find Configs",
        results_title = "Config Files",
        path_display = { "smart" },
        search_dirs = tracked_files,
        layout_strategy = "horizontal",
        layout_config = { preview_width = 0.65, width = 0.75 },
        previewer = true,
    })
end

function M.find_scripts()
  require("telescope.builtin").find_files({
    hidden = true,
    no_ignore = true,
    prompt_title = " Find Scripts",
    path_display = { "smart" },
    search_dirs = {
      "~/.scripts",
    },
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_projects()
  local search_dir = "~/projects"
  local actions       = safe_require("telescope.actions")
  local actions_set   = safe_require("telescope.actions.set")
  local actions_state = safe_require("telescope.actions.state")
  local finders       = safe_require("telescope.finders")
  local pickers       = safe_require("telescope.pickers")
  local config_mod    = safe_require("telescope.config")
  local config = config_mod and config_mod.values or {}

  pickers
      .new({}, {
        prompt_title = "Find Projects",
        finder = finders.new_oneshot_job({
          "find",
          vim.fn.expand(search_dir),
          "-type",
          "d",
          "-maxdepth",
          "1",
        }),
        previewer = require("telescope.previewers").vim_buffer_cat.new({}),
        sorter = config.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions_set.select:replace(function()
            local entry = actions_state.get_selected_entry()
            if entry ~= nil then
              local dir = entry.value
              actions.close(prompt_bufnr, false)
              vim.fn.chdir(dir)
              vim.cmd("e .")
              vim.cmd("echon ''")
              print("cwd: " .. vim.fn.getcwd())
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
    "~/documents/main/",
  }
  opts.prompt_prefix = "   "
  opts.prompt_title = " Grep Notes"
  opts.path_display = { "smart" }
  require("telescope.builtin").live_grep(opts)
end

function M.find_notes()
  require("telescope.builtin").find_files({
    hidden = true,
    no_ignore = false,
    prompt_title = " Find Notes",
    path_display = { "smart" },
    search_dirs = {
      "~/documents/main",
    },
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_private()
  require("telescope.builtin").find_files({
    hidden = true,
    no_ignore = false,
    prompt_title = " Find Notes",
    path_display = { "smart" },
    search_dirs = {
      "~/notes/private",
      "~/notes",
    },
    layout_strategy = "horizontal",
    layout_config = { preview_width = 0.65, width = 0.75 },
  })
end

function M.find_books()
  local search_dir = "~/documents/books"
  local actions       = safe_require("telescope.actions")
  local actions_set   = safe_require("telescope.actions.set")
  local actions_state = safe_require("telescope.actions.state")
  local finders       = safe_require("telescope.finders")
  local pickers       = safe_require("telescope.pickers")
  local config_mod    = safe_require("telescope.config")
  local config = config_mod and config_mod.values or {}

  vim.fn.jobstart("$HOME/.scripts/track-books.sh")
  local recent_books_directory = vim.fn.stdpath("config") .. "/tmp/"
  local recent_books_file = recent_books_directory .. "recent_books.txt"

  -- Check if recent_books.txt exists, create it if not
  if vim.fn.filereadable(recent_books_file) == 0 then
    vim.fn.mkdir(recent_books_directory, "p") -- Ensure the directory exists
    vim.fn.writefile({}, recent_books_file)   -- Create an empty file
  end

  local search_cmd = "find " .. vim.fn.expand(search_dir) .. " -type d -o -type f -maxdepth 1"

  local recent_books = vim.fn.readfile(recent_books_file)
  local search_results = vim.fn.systemlist(search_cmd)

  local results = {}

  -- Section for Recent Books
  table.insert(results, " Recent Books")
  for _, recent_book_path in ipairs(recent_books) do
    local formatted_path = vim.fn.fnameescape(recent_book_path)
    table.insert(results, formatted_path)
  end

  -- Section for All Books
  table.insert(results, " All Books")
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
    prompt_title = "Find Books",
    finder = finders.new_table({
      results = results,
    }),
    file_ignore_patterns = {
      "%.git",
    },
    previewer = require("telescope.previewers").vim_buffer_cat.new({}),
    sorter = config.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions_set.select:replace(function()
        local entry = actions_state.get_selected_entry()
        if entry ~= nil then
          local path = entry.value

          actions.close(prompt_bufnr, false)

          -- Check if it's under "Recent Books"
          if path == " Recent Books" or path == " All Books" then
            vim.notify("Cannot select 'All Books'/'Recent Books', please select a book or directory.",
              vim.log.levels.WARN, { title = "Find Books" })
          else
            -- Determine whether it's a directory or a file
            local is_directory = vim.fn.isdirectory(path)
            if is_directory then
              -- It's a directory, navigate to it in the current buffer
              vim.cmd("e " .. path)
            else
              -- It's a file, open it
              vim.cmd("e " .. path)
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
  local buffer_dir = require("telescope.utils").buffer_dir()
  local opts = {
    prompt_title = "Live Grep in " .. buffer_dir,
    cwd = buffer_dir,
  }
  require("telescope.builtin").live_grep(opts)
end

-- Helper functions that depend on telescope availability
local function get_dropdown_theme()
  return require("telescope.themes").get_dropdown({
    hidden = true,
    no_ignore = true,
    previewer = false,
    prompt_title = "",
    preview_title = "",
    results_title = "",
    layout_config = {
      prompt_position = "top",
    },
  })
end

-- Set current folder as prompt title
local function with_title(opts, extra)
  extra = extra or {}
  local path = opts.cwd or opts.path or extra.cwd or extra.path or nil
  local title = ""
  local buf_path = vim.fn.expand("%:p:h")
  local cwd = vim.fn.getcwd()
  if path ~= nil and buf_path ~= cwd then
    title = require("plenary.path"):new(buf_path):make_relative(cwd)
  else
    title = vim.fn.fnamemodify(cwd, ":t")
  end

  return vim.tbl_extend("force", opts, {
    prompt_title = title,
  }, extra or {})
end

-- Find here
function M.findhere()
  -- Open file browser if argument is a folder
  local arg = vim.api.nvim_eval("argv(0)")
  if arg and (vim.fn.isdirectory(arg) ~= 0 or arg == "") then
    vim.defer_fn(function()
      require("telescope.builtin").find_files(with_title(get_dropdown_theme()))
    end, 10)
  end
end

-- Find dirs
function M.find_dirs()
  local root_dir = vim.fn.input("Enter the root directory: ")

  -- Check if root_dir is empty
  if root_dir == "" then
    print("No directory entered. Aborting.")
    return
  end

  local entries = {}

  -- Use vim.fn.expand() to get an absolute path
  local root_path = vim.fn.expand(root_dir)

  local subentries = vim.fn.readdir(root_path)
  if subentries then
    for _, subentry in ipairs(subentries) do
      local absolute_path = root_path .. "/" .. subentry
      table.insert(entries, subentry)
    end
  end

  local actions       = safe_require("telescope.actions")
  local actions_set   = safe_require("telescope.actions.set")
  local actions_state = safe_require("telescope.actions.state")
  local finders       = safe_require("telescope.finders")
  local pickers       = safe_require("telescope.pickers")
  local config_mod    = safe_require("telescope.config")
  local config = config_mod and config_mod.values or {}

  pickers
      .new({}, {
        prompt_title = "Change Directory or Open File",
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
              local selected_path = root_path .. "/" .. selected_entry
              if vim.fn.isdirectory(selected_path) == 1 then
                vim.fn.chdir(selected_path)
                vim.cmd("e .")
                print("cwd: " .. vim.fn.getcwd())
              else
                vim.cmd("e " .. selected_path)
              end
            end
          end)
          return true
        end,
      })
      :find()
end

-- Safe telescope function wrapper for keymaps
local function safe_telescope_call(module_path, func_name, fallback_msg)
  return function()
    local ok, module = pcall(require, module_path)
    if ok and module[func_name] then
      module[func_name]()
    else
      vim.notify(fallback_msg or ("Telescope plugin not available for " .. func_name), vim.log.levels.WARN)
    end
  end
end

local function safe_telescope_builtin(func_name, fallback_msg)
  return function(opts)
    local ok, telescope_builtin = pcall(require, "telescope.builtin")
    if not ok then
      vim.notify(fallback_msg or ("Telescope builtin module (telescope.builtin) not found!"), vim.log.levels.ERROR)
      vim.notify("Error details: " .. tostring(telescope_builtin), vim.log.levels.DEBUG) -- telescope_builtin will contain the error message here
      return
    end

    if not telescope_builtin[func_name] then
      vim.notify(fallback_msg or ("Telescope builtin function '" .. func_name .. "' not found!"), vim.log.levels.ERROR)
      vim.notify("Available builtin functions: " .. vim.inspect(vim.tbl_keys(telescope_builtin)), vim.log.levels.DEBUG)
      return
    end

    -- If both are ok, proceed
    telescope_builtin[func_name](opts or {})
  end
end

-- Safe builtin telescope functions
local function safe_telescope_builtin(func_name, fallback_msg)
  return function(opts)
    local ok, telescope_builtin = pcall(require, "telescope.builtin")
    if ok and telescope_builtin[func_name] then
      telescope_builtin[func_name](opts or {})
    else
      vim.notify(fallback_msg or ("Telescope builtin not available: " .. func_name), vim.log.levels.WARN)
    end
  end
end

-- Safe extension calls with better checking
local function safe_telescope_extension(ext_name, func_name, fallback_msg)
  return function(opts)
    local telescope_mod = package.loaded.telescope or require("telescope")
    if not telescope_mod then
      return
    end

    -- Check if extension is loaded
    if not telescope_mod.extensions or not telescope_mod.extensions[ext_name] then
      vim.notify(fallback_msg or ("Telescope extension '" .. ext_name .. "' not available (plugin may not be installed)"), vim.log.levels.WARN)
      return
    end

    local ext_func = telescope_mod.extensions[ext_name][func_name]
    if not ext_func then
      vim.notify(fallback_msg or ("Function '" .. func_name .. "' not found in extension '" .. ext_name .. "'"), vim.log.levels.WARN)
      return
    end

    ext_func(opts or {})
  end
end

-- Fallback-safe `find_files`
M.safe_find_files = function()
  local builtin = safe_require("telescope.builtin")
  if builtin and builtin.find_files then
    builtin.find_files()
  else
    local file = vim.fn.input("Open file: ", "", "file")
    if file ~= "" then vim.cmd("edit " .. file) end
  end
end

-- Export safe wrapper functions for external use
M.safe_telescope_call = safe_telescope_call
M.safe_telescope_builtin = safe_telescope_builtin
M.safe_telescope_extension = safe_telescope_extension

return M
