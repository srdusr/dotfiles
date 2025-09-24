-- manager.lua

local M = {}

-- State tracking
local state = {
  manager_invoked = nil,
  initialized = false,
  bootstrap_completed = {},
}

-- Path constants
local PATHS = {
  lazy = vim.fn.stdpath("data") .. "/lazy/lazy.nvim",
  packer = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim",
  packer_dir = vim.fn.stdpath("data") .. "/site/pack/packer/start",
  builtin_dir = vim.fn.stdpath("data") .. "/nvim/site/pack/core/opt",
}

-- Utility functions
local function safe_require(module)
  local ok, result = pcall(require, module)
  return ok and result or nil
end

local function notify(msg, level)
  vim.notify("[Manager] " .. msg, level or vim.log.levels.INFO)
end

local function execute_git_command(cmd, _)
  -- Use vim.fn.system instead of os.execute for better cross-platform support and error handling
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

local function get_nvim_version()
  local version = vim.version()
  if version then
    return version.major, version.minor, version.patch
  end

  -- Fallback for older versions
  local version_str = vim.fn.execute("version"):match("NVIM v(%d+%.%d+%.%d+)")
  if version_str then
    local major, minor, patch = version_str:match("(%d+)%.(%d+)%.(%d+)")
    return tonumber(major), tonumber(minor), tonumber(patch)
  end
  return 0, 0, 0
end

local function has_builtin_manager()
  local major, minor = get_nvim_version()
  return major > 0 or (major == 0 and minor >= 12)
end

-- CRITICAL FIX: This function is essential to prevent runtime conflicts.
-- It removes the specified manager's directory from the runtimepath.
local function cleanup_manager(manager_name)
  if manager_name == "packer" then
    -- Reset packer state and remove from rtp
    local packer = safe_require("packer")
    if packer then
      pcall(packer.reset)
    end
    -- Remove the entire packer directory from rtp
    local packer_rtp = vim.fn.glob(PATHS.packer_dir)
    if packer_rtp then
      local rtp_items = vim.split(vim.o.rtp, ",")
      local new_rtp_items = {}
      for _, item in ipairs(rtp_items) do
        if item ~= packer_rtp then
          table.insert(new_rtp_items, item)
        end
      end
      vim.o.rtp = table.concat(new_rtp_items, ",")
    end
  elseif manager_name == "lazy" then
    -- Lazy.nvim clears its state on each run, but we can remove it from rtp for good measure
    local lazy_rtp = vim.fn.glob(PATHS.lazy)
    if lazy_rtp then
      local rtp_items = vim.split(vim.o.rtp, ",")
      local new_rtp_items = {}
      for _, item in ipairs(rtp_items) do
        if item ~= lazy_rtp then
          table.insert(new_rtp_items, item)
        end
      end
      vim.o.rtp = table.concat(new_rtp_items, ",")
    end
  elseif manager_name == "builtin" then
    -- Built-in manager is handled by vim.opt.packpath and doesn't need manual cleanup from rtp
    -- unless we want to disable its packages, which isn't the goal here.
  end
end

-- IMPROVED: Use vim.g for persistence instead of file system
local function save_manager_choice(manager_name)
  vim.g.nvim_manager_choice = manager_name
  -- Also save to data directory as a simple text file for true persistence across sessions
  local data_dir = vim.fn.stdpath("data")
  local choice_file = data_dir .. "/.manager_choice"
  local file = io.open(choice_file, "w")
  if file then
    file:write(manager_name)
    file:close()
  end
end

local function load_manager_choice()
  -- First check vim.g (current session)
  if vim.g.nvim_manager_choice then
    return vim.g.nvim_manager_choice
  end

  -- Then check persistent file
  local data_dir = vim.fn.stdpath("data")
  local choice_file = data_dir .. "/.manager_choice"
  local file = io.open(choice_file, "r")
  if file then
    local choice = file:read("*a"):gsub("%s+", "") -- trim whitespace
    file:close()
    if choice and choice ~= "" then
      vim.g.nvim_manager_choice = choice -- cache in session
      return choice
    end
  end

  return nil
end

--- Packer Manager Implementation
--
-- Handles cloning, setup, and configuration of Packer.nvim.
local Packer = {}

function Packer.bootstrap()
  if state.bootstrap_completed.packer then
    return true
  end

  local fn = vim.fn
  if fn.isdirectory(PATHS.packer_dir) == 0 then
    fn.mkdir(PATHS.packer_dir, "p")
  end

  if fn.empty(fn.glob(PATHS.packer)) > 0 then
    local is_windows = vim.loop.os_uname().version:match("Windows")
    local git_cmd

    if is_windows then
      git_cmd = string.format(
        'git clone --depth=1 https://github.com/wbthomason/packer.nvim "%s" >nul 2>&1',
        PATHS.packer
      )
    else
      git_cmd = string.format(
        'env -i PATH="%s" HOME="%s" git clone --depth=1 --quiet https://github.com/wbthomason/packer.nvim %q >/dev/null 2>&1',
        os.getenv("PATH") or "/usr/bin:/bin",
        os.getenv("HOME") or "/tmp",
        PATHS.packer
      )
    end

    if not execute_git_command(git_cmd, "Failed to clone packer.nvim") then
      return false
    end
  end

  state.bootstrap_completed.packer = true
  return true
end

function Packer.setup()
  if not Packer.bootstrap() then
    return false
  end

  -- Ensure packer.nvim is in the runtime path
  vim.cmd("packadd packer.nvim")

  local packer = safe_require("packer")
  if not packer then
    notify("Failed to load packer.nvim", vim.log.levels.ERROR)
    return false
  end

  -- Reset any existing configuration from a previous run
  pcall(packer.reset)

  packer.init({
    auto_reload_compiled = true,
    display = {
      open_fn = function()
        return require("packer.util").float({ border = "rounded" })
      end,
    },
    luarocks = {
      python_cmd = 'python3'
    },
  })

  local plugins = safe_require("setup.plugins")
  if not plugins then
    notify("Failed to load plugins configuration", vim.log.levels.ERROR)
    return false
  end

  packer.startup(function(use)
    use "wbthomason/packer.nvim"
    for _, plugin in ipairs(plugins) do
      -- CHECK FOR EXCLUDE HERE - Packer support for exclude option
      if plugin.exclude and vim.tbl_contains(plugin.exclude, "packer") then
        --notify("Excluding plugin for packer: " .. (plugin.name or plugin.as or plugin[1] or "unknown"), vim.log.levels.INFO)
        goto continue
      end

      -- Packer doesn't have a lazy option, so we ensure all plugins are loaded eagerly
      -- by clearing any lazy-loading keys from the plugins table.
      local packer_plugin = vim.deepcopy(plugin)
      packer_plugin.event = nil
      packer_plugin.keys = nil
      packer_plugin.cmd = nil
      packer_plugin.ft = nil
      packer_plugin.lazy = nil
      packer_plugin.exclude = nil -- Remove exclude from the actual plugin spec
      use(packer_plugin)
      ::continue::
    end
  end)

  return true
end

function Packer.is_available()
  return vim.fn.isdirectory(PATHS.packer) == 1
end

--- Lazy.nvim Manager Implementation
--
local Lazy = {}

function Lazy.bootstrap()
  if state.bootstrap_completed.lazy then
    return true
  end

  -- Check if lazy.nvim is already cloned
  if not vim.loop.fs_stat(PATHS.lazy) then
    local is_windows = vim.loop.os_uname().version:match("Windows")
    local git_cmd

    if is_windows then
      git_cmd = string.format(
        'git clone --filter=blob:none --branch=stable https://github.com/folke/lazy.nvim.git "%s" >nul 2>&1',
        PATHS.lazy
      )
    else
      git_cmd = string.format(
        'env -i PATH="%s" HOME="%s" git clone --filter=blob:none --branch=stable --quiet https://github.com/folke/lazy.nvim.git %q >/dev/null 2>&1',
        os.getenv("PATH") or "/usr/bin:/bin",
        os.getenv("HOME") or "/tmp",
        PATHS.lazy
      )
    end

    if not execute_git_command(git_cmd, "Failed to clone lazy.nvim") then
      return false
    end
  end

  state.bootstrap_completed.lazy = true
  return true
end

function Lazy.setup()
  if not Lazy.bootstrap() then
    return false
  end

  -- Ensure lazy.nvim is in the runtime path before requiring it
  vim.opt.rtp:prepend(PATHS.lazy)

  local lazy = safe_require("lazy")
  if not lazy then
    notify("Failed to load lazy.nvim", vim.log.levels.ERROR)
    return false
  end

  -- FIX: Correctly require plugins and set up lazy.nvim
  local plugins = safe_require("setup.plugins")
  if not plugins then
    notify("Failed to load plugins configuration", vim.log.levels.ERROR)
    return false
  end

  -- Filter out excluded plugins for Lazy
  local filtered_plugins = {}
  for _, plugin in ipairs(plugins) do
    -- CHECK FOR EXCLUDE HERE - Lazy support for exclude option
    if plugin.exclude and vim.tbl_contains(plugin.exclude, "lazy") then
      --notify("Excluding plugin for lazy: " .. (plugin.name or plugin[1] or "unknown"), vim.log.levels.INFO)
    else
      local lazy_plugin = vim.deepcopy(plugin)
      lazy_plugin.exclude = nil -- Remove exclude from the actual plugin spec
      table.insert(filtered_plugins, lazy_plugin)
    end
  end

  -- Setup Lazy.nvim with the correct options
  lazy.setup(filtered_plugins, {
    {
      import = "plugins",
    },
    defaults = { lazy = false },  -- Set plugins to be lazy-loaded by default
    install = { missing = true }, -- CRITICAL FIX: This ensures missing plugins are installed
    ui = {
      border = "rounded",
    },
    performance = {
      rtp = {
        disabled_plugins = {
          "gzip", "matchit", "matchparen", "netrwPlugin",
          "tarPlugin", "tohtml", "tutor", "zipPlugin",
        },
      },
    },
  })

  return true
end

function Lazy.is_available()
  return vim.loop.fs_stat(PATHS.lazy) ~= nil
end

--- Built-in manager implementation (Neovim 0.12+)
--
local Builtin = {}

function Builtin.bootstrap()
  if not has_builtin_manager() then
    --notify("Built-in package manager not available in this Neovim version", vim.log.levels.WARN)
    return false
  end

  state.bootstrap_completed.builtin = true
  return true
end

function Builtin.setup()
  if not has_builtin_manager() then
    --notify("Built-in package manager not available in this Neovim version", vim.log.levels.WARN)
    return false
  end

  local plugins = safe_require("setup.plugins")
  if not plugins then
    notify("Failed to load plugins configuration", vim.log.levels.ERROR)
    return false
  end

  -- Convert plugins to builtin manager format
  local builtin_specs = {}
  for _, plugin in ipairs(plugins) do
    -- CHECK FOR EXCLUDE HERE
    if plugin.exclude and vim.tbl_contains(plugin.exclude, "builtin") then
      --notify("Excluding plugin for builtin: " .. (plugin.name or plugin[1] or "unknown"), vim.log.levels.INFO)
      goto continue
    end
    local spec = {}

    if type(plugin) == "string" then
      -- Handle string format like "user/repo"
      if plugin:match("^[%w%-_%.]+/[%w%-_%.]+$") then
        -- It's a GitHub shorthand
        spec.src = "https://github.com/" .. plugin
        spec.name = plugin:match("/([%w%-_%.]+)$") -- Extract repo name
      else
        -- It's already a full URL
        spec.src = plugin
      end
    elseif type(plugin) == "table" then
      -- Handle table format
      if plugin[1] and type(plugin[1]) == "string" then
        -- Format like {"user/repo", ...}
        if plugin[1]:match("^[%w%-_%.]+/[%w%-_%.]+$") then
          spec.src = "https://github.com/" .. plugin[1]
          spec.name = plugin[1]:match("/([%w%-_%.]+)$")
        else
          spec.src = plugin[1]
        end

        -- Copy other properties
        for k, v in pairs(plugin) do
          if type(k) == "string" then
            spec[k] = v
          end
        end
      elseif plugin.src then
        spec.src = plugin.src
        for k, v in pairs(plugin) do
          if k ~= "src" then
            spec[k] = v
          end
        end
      elseif plugin.url then
        spec.src = plugin.url
        for k, v in pairs(plugin) do
          if k ~= "url" then
            spec[k] = v
          end
        end
      else
        notify("Invalid plugin specification for built-in manager: " .. vim.inspect(plugin), vim.log.levels.WARN)
        goto continue
      end

      -- Handle name override
      if plugin.name then
        spec.name = plugin.name
      elseif plugin.as then
        spec.name = plugin.as
      elseif not spec.name and spec.src then
        -- Extract name from URL if not specified
        spec.name = spec.src:match("/([%w%-_%.]+)%.git$") or spec.src:match("/([%w%-_%.]+)$") or spec.src
      end

      -- Handle version
      if plugin.version then
        spec.version = plugin.version
      end

      -- Remove keys that builtin manager doesn't understand
      spec.lazy = nil
      spec.event = nil
      spec.keys = nil
      spec.cmd = nil
      spec.ft = nil
      spec.dependencies = nil
      spec.config = nil
      spec.build = nil
      spec.run = nil
      spec.priority = nil
      spec.as = nil
      spec.url = nil
      spec.exclude = nil
      spec[1] = nil -- Remove positional argument
    end

    if spec.src then
      table.insert(builtin_specs, spec)
    end
    ::continue::
  end

  -- Debug: Show what we're about to install
  --notify(string.format("Installing %d plugins with built-in manager", #builtin_specs), vim.log.levels.INFO)

  -- CRITICAL FIX: Call vim.pack.add with the specs directly, not wrapped in array
  if #builtin_specs > 0 then
    local ok, err = pcall(vim.pack.add, builtin_specs)
    if not ok then
      notify("Failed to add plugins: " .. tostring(err), vim.log.levels.ERROR)
      return false
    end

    --notify("Plugins added successfully. Use :Pack to install/update them.", vim.log.levels.INFO)
  else
    notify("No valid plugins found for built-in manager", vim.log.levels.WARN)
  end

  -- Create user commands for convenience - FIXED COMMAND NAMES
  vim.api.nvim_create_user_command("Package", function(opts)
    local subcommand = opts.fargs[1] or "update"
    local names = vim.list_slice(opts.fargs, 2)

    if subcommand == "add" then
      -- For add, we need to re-run setup to add new plugins
      --notify("Re-running builtin manager setup to add new plugins...")
      Builtin.setup()
    elseif subcommand == "update" then
      if #names == 0 then
        names = nil -- Update all plugins
      end
      vim.pack.update(names)
    elseif subcommand == "status" then
      local plugins = vim.pack.get()
      print(string.format("Built-in manager: %d plugins managed", #plugins))
      for _, plugin in ipairs(plugins) do
        local status = plugin.active and "active" or "inactive"
        print(string.format("  %s (%s): %s", plugin.spec.name, status, plugin.path))
      end
    else
      -- Default behavior - treat as update
      if subcommand then
        table.insert(names, 1, subcommand)
      end
      if #names == 0 then
        names = nil
      end
      vim.pack.update(names)
    end
  end, {
    nargs = "*",
    complete = function(arglead, cmdline, cursorpos)
      local args = vim.split(cmdline, "%s+")
      if #args <= 2 then
        -- Complete subcommands
        local subcommands = { "add", "update", "status" }
        local matches = {}
        for _, cmd in ipairs(subcommands) do
          if cmd:find("^" .. arglead) then
            table.insert(matches, cmd)
          end
        end
        return matches
      else
        -- Complete plugin names
        local plugins = vim.pack.get()
        local names = {}
        for _, plugin in ipairs(plugins) do
          if plugin.spec.name:find("^" .. arglead) then
            table.insert(names, plugin.spec.name)
          end
        end
        return names
      end
    end,
    desc = "Manage plugins with built-in manager. Usage: :Pack [add|update|status] [plugin_names...]"
  })

  ---- Keep the old command for backwards compatibility
  --vim.api.nvim_create_user_command("PackageStatus", function()
  --  vim.cmd("Pack status")
  --end, {
  --  nargs = 0,
  --  desc = "Show status of plugins managed by built-in manager (deprecated, use :Pack status)"
  --})

  return true
end

function Builtin.is_available()
  return has_builtin_manager()
end

--- Manager registry
--
local MANAGERS = {
  packer = Packer,
  lazy = Lazy,
  builtin = Builtin,
}

--- Core management functions
--
local function activate_manager(manager_name)
  local manager = MANAGERS[manager_name]
  if not manager then
    notify("Unknown manager: " .. manager_name, vim.log.levels.ERROR)
    return false
  end

  -- Cleanup the old manager before activating the new one to prevent runtime conflicts.
  if state.manager_invoked and state.manager_invoked ~= manager_name then
    cleanup_manager(state.manager_invoked)
  end

  if not manager.bootstrap() then
    return false
  end

  local ok = manager.setup()
  if ok then
    state.manager_invoked = manager_name
    -- CRITICAL FIX: Persist the manager choice after successful setup
    save_manager_choice(manager_name)
  end
  return ok
end

--- Auto-detection and command setup
--
local function setup_auto_detection()
  -- Autocmd to activate Packer when Packer commands are used
  vim.api.nvim_create_autocmd("CmdUndefined", {
    pattern = "Packer*",
    callback = function(event)
      if state.manager_invoked ~= "packer" then
        local ok = activate_manager("packer")
        if ok then
          -- Re-execute the original command after setup
          vim.cmd(event.match)
        end
      end
    end,
    desc = "Auto-activate Packer when Packer commands are used"
  })

  -- Autocmd to activate Lazy when Lazy commands are used
  vim.api.nvim_create_autocmd("CmdUndefined", {
    pattern = "Lazy*",
    callback = function(event)
      if state.manager_invoked ~= "lazy" then
        local ok = activate_manager("lazy")
        if ok then
          -- CRITICAL FIX: Use vim.schedule to defer the command execution
          -- This ensures Lazy's setup is complete before running the command.
          vim.schedule(function()
            pcall(vim.cmd, event.match)
          end)
        end
      end
    end,
    desc = "Auto-activate Lazy and re-execute command"
  })

  vim.api.nvim_create_autocmd("CmdUndefined", {
    pattern = "Package*",
    callback = function(event)
      if state.manager_invoked ~= "builtin" and has_builtin_manager() then
        local ok = activate_manager("builtin")
        if ok then
          vim.cmd(event.match)
        end
      end
    end,
    desc = "Auto-activate built-in manager when Pack commands are used"
  })
end

--- Public API
--
function M.setup()
  if state.initialized then
    return
  end

  -- Initial bootstrap attempt for all managers to see what's available
  for name, manager in pairs(MANAGERS) do
    -- CRITICAL FIX: Always bootstrap, but don't set up yet
    pcall(manager.bootstrap)
  end

  -- CRITICAL FIX: Check for a previously saved choice
  local persistent_choice = load_manager_choice()
  if persistent_choice and MANAGERS[persistent_choice] then
    -- If a choice exists, immediately activate that manager for this session
    activate_manager(persistent_choice)
  else
    -- If no choice exists, set up the autocmds to wait for a command
    setup_auto_detection()
  end

  state.initialized = true
end

function M.use_manager(manager_name)
  if not state.initialized then
    M.setup()
  end

  local available = M.available_managers()
  if not vim.tbl_contains(available, manager_name) then
    notify(string.format("Manager '%s' is not available. Available: %s",
      manager_name, table.concat(available, ", ")), vim.log.levels.WARN)
    return false
  end

  return activate_manager(manager_name)
end

function M.available_managers()
  local managers = {}
  for name, manager in pairs(MANAGERS) do
    if manager.is_available() then
      table.insert(managers, name)
    end
  end
  return managers
end

function M.current_manager()
  return state.manager_invoked
end

function M.status()
  local info = {
    initialized = state.initialized,
    current_manager = state.manager_invoked,
    available_managers = M.available_managers(),
    bootstrap_completed = state.bootstrap_completed,
  }

  print("=== Neovim Plugin Manager Status ===")
  print(string.format("Initialized: %s", tostring(info.initialized)))
  print(string.format("Current Manager: %s", info.current_manager or "None"))
  print(string.format("Available Managers: %s", table.concat(info.available_managers, ", ")))

  -- FIX: Properly format the Neovim version
  local major, minor, patch = get_nvim_version()
  print(string.format("Neovim Version: %d.%d.%d", major, minor, patch))
  print(string.format("Built-in Support: %s", tostring(has_builtin_manager())))

  return info
end

-- FIX: Added M.get_nvim_version function to the public API
function M.get_nvim_version()
  local major, minor, patch = get_nvim_version()
  return { major = major, minor = minor, patch = patch }
end

function M.reset_nvim()
  vim.ui.input({
    prompt = "Are you sure you want to reset Neovim? This will delete all data, state, cache, and plugins. (y/N): "
  }, function(input)
    if input and input:lower() == "y" then
      local fn = vim.fn
      local is_windows = vim.loop.os_uname().version:match("Windows")

      local paths_to_remove = {
        fn.stdpath("data"),
        fn.stdpath("state"),
        fn.stdpath("cache"),
        fn.stdpath("config") .. "/plugin",
      }

      local cmd = ""
      if is_windows then
        local paths_quoted = {}
        for _, path in ipairs(paths_to_remove) do
          table.insert(paths_quoted, string.format('"%s"', path))
        end
        cmd = "powershell -Command \"Remove-Item " ..
            table.concat(paths_quoted, ", ") .. " -Recurse -Force -ErrorAction SilentlyContinue\""
      else
        local paths_quoted = {}
        for _, path in ipairs(paths_to_remove) do
          table.insert(paths_quoted, vim.fn.shellescape(path))
        end
        cmd = "rm -rf " .. table.concat(paths_quoted, " ")
      end

      notify("Resetting Neovim... Please restart after this operation.")

      vim.defer_fn(function()
        local result = os.execute(cmd)
        if result ~= 0 then
          notify("Reset command may have failed. You might need to delete directories manually.", vim.log.levels.WARN)
        else
          notify("Reset completed successfully. Please restart Neovim.")
        end
      end, 100)
    else
      notify("Reset cancelled.")
    end
  end)
end

-- Clear manager choice function
function M.clear_choice()
  vim.g.nvim_manager_choice = nil
  local data_dir = vim.fn.stdpath("data")
  local choice_file = data_dir .. "/.manager_choice"
  os.remove(choice_file)
  notify("Manager choice cleared. Next command will determine the manager.")
end

vim.api.nvim_create_user_command("Reset", function()
  M.reset_nvim()
end, {
  nargs = 0,
  desc = "Reset Neovim's data, state, cache, and plugin directories"
})

local function manager_command(opts)
  local subcommand = opts.fargs[1]

  if subcommand == "status" then
    M.status()
  elseif subcommand == "packer" or subcommand == "Packer" then
    M.use_manager("packer")
  elseif subcommand == "lazy" or subcommand == "Lazy" then
    M.use_manager("lazy")
  elseif subcommand == "builtin" or subcommand == "built-in" or subcommand == "Builtin" or subcommand == "Built-in" then
    M.use_manager("builtin")
  elseif subcommand == "clear" then
    M.clear_choice()
  else
    print("Unknown subcommand. Try 'status', 'packer', 'lazy', 'builtin' or 'clear'.")
  end
end

vim.api.nvim_create_user_command("Manager", manager_command, {
  nargs = "+",
  complete = function(arglead)
    local subcommands = { "status", "packer", "Packer", "lazy", "Lazy", "builtin", "built-in", "Builtin", "Built-in",
      "clear" }
    local result = {}
    for _, subcommand in ipairs(subcommands) do
      if subcommand:find("^" .. arglead, 1) then
        table.insert(result, subcommand)
      end
    end
    return result
  end,
  desc = "Manage plugins. Subcommands: status, packer, lazy, builtin, clear"
})

return M
