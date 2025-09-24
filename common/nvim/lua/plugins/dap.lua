local M = {}

function M.setup()
  local ok, dap = pcall(require, "dap")
  if not ok or not dap then
    return false
  end

-- options
dap.defaults.fallback.switchbuf = "uselast"
dap.defaults.fallback.focus_terminal = true
dap.defaults.fallback.external_terminal = {
  command = "/usr/bin/wezterm",
  args = { "-e" },
}

-- Autocmds
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "dap-float" },
  callback = function(event)
    vim.keymap.set("n", "<Tab>", "", { buffer = event.buf, silent = true })
    vim.keymap.set("n", "<S-Tab>", "", { buffer = event.buf, silent = true })
  end,
})

dap.adapters.cppdbg = {
  id = "cppdbg",
  type = "executable",
  --command = vim.fn.stdpath('data') .. '/mason/bin/OpenDebugAD7',
  command = os.getenv("HOME") .. "/apps/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
  --command = cpptools:get_install_path() .. '/extension/debugAdapters/bin/OpenDebugAD7'
}

dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  --host = "localhost",
  --host = '127.0.0.1',
  --port = 13000, -- 💀 Use the port printed out or specified with `--port`
  executable = {
    --command = os.getenv("HOME") .. '/apps/codelldb/extension/adapter/codelldb',
    command = os.getenv("HOME") .. "/.vscode-oss/extensions/vadimcn.vscode-lldb-1.9.0-universal/adapter/codelldb",
    args = { "--port", "${port}" },
  },
  --detached = true,
}

dap.adapters.lldb = {
  type = "executable",
  command = "/usr/bin/lldb-vscode",
  name = "lldb",
}
dap.configurations.cpp = {
  {
    name = "Debugger",
    --type = "lldb",
    --type = "cppdbg",
    type = "codelldb",
    request = "launch",
    cwd = "${workspaceFolder}",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    --program = '${file}',
    --program = function()
    --  -- First, check if exists CMakeLists.txt
    --  local cwd = vim.fn.getcwd()
    --  if (file.exists(cwd, "CMakeLists.txt")) then
    --    -- Todo. Then invoke cmake commands
    --    -- Then ask user to provide execute file
    --    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    --  else
    --    local fileName = vim.fn.expand("%:t:r")
    --    if (not file.exists(cwd, "bin")) then
    --      -- create this directory
    --      os.execute("mkdir " .. "bin")
    --    end
    --    local cmd = "!gcc -g % -o bin/" .. fileName
    --    -- First, compile it
    --    vim.cmd(cmd)
    --    -- Then, return it
    --    return "${fileDirname}/bin/" .. fileName
    --  end
    --end,
    stopAtEntry = true,
    args = {},
    --runInTerminal = true,
    --runInTerminal = false,
    --console = 'integratedTerminal',

    --MIMode = 'gdb',
    --miDebuggerServerAddress = 'localhost:1234',
    --miDebuggerPath = 'gdb-oneapi',
    --miDebuggerPath = '/usr/bin/gdb',
    externalConsole = true,
    --setupCommands = {
    --  {
    --    text = '-enable-pretty-printing',
    --    description =  'enable pretty printing',
    --    ignoreFailures = false
    --  }
    --},
  },
}

-- If you want to use this for Rust and C, add something like this:
dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

-- javascript
--dap.adapters.node2 = {
--  type = 'executable',
--  command = 'node-debug2-adapter',
--  args = {},
--}

--dap.configurations.javascript = {
--  {
--    name = 'Launch',
--    type = 'node2',
--    request = 'attach',
--    program = '${file}',
--    cwd = vim.fn.getcwd(),
--    sourceMaps = true,
--    protocol = 'inspector',
--    console = 'integratedTerminal',
--  },
--}

dap.adapters.python = {
  type = "executable",
  command = vim.trim(vim.fn.system("which python")),
  args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    -- The first three options are required by nvim-dap
    type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
    request = "launch",
    name = "Launch file",
    -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
    program = "${file}", -- This configuration will launch the current file if used.
    stopOnEntry = true,
  },
}

local dapui = require("dapui")
--local dap_ui_status_ok, dapui = pcall(require, "dapui")
--if not dap_ui_status_ok then
--  return
--end

-- setup repl
--dap.repl.commands = vim.tbl_extend('force', dap.repl.commands, {
--    exit = { 'q', 'exit' },
--    custom_commands = {
--        ['.run_to_cursor'] = dap.run_to_cursor,
--        ['.restart'] = dap.run_last
--    }
--})

-- Load dapui configuration only if it hasn't been loaded before
  local dapui_ok, dapui = pcall(require, "dapui")
  if dapui_ok and dapui then
    dapui.setup({
      mappings = {
        expand = "<CR>",
        open = "o",
      remove = "D",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    controls = {
      enabled = true,
    },
    layouts = {
      {
        elements = {
          -- Elements can be strings or table with id and size keys.
          { id = "watches",     size = 0.25 },
          { id = "scopes",      size = 0.25 },
          { id = "breakpoints", size = 0.25 },
          { id = "stacks",      size = 0.25 },
        },
        size = 50, -- 40 columns
        position = "left",
      },
      {
        elements = {
          { id = "console", size = 0.6 },
          { id = "repl",    size = 0.4 },
        },
        size = 0.3,
        position = "bottom",
      },
    },
    render = {
      max_value_lines = 3,
    },
    floating = {
      max_height = nil,  -- These can be integers or a float between 0 and 1.
      max_width = nil,   -- Floats will be treated as percentage of your screen.
      border = "single", -- Border style. Can be "single", "double" or "rounded"
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    --icons = { expanded = "-", collapsed = "$" },
    icons = {
      expanded = "",
      collapsed = "",
      current_frame = "",
    },
  })
  vim.g.loaded_dapui = true
end

-- Signs
local sign = vim.fn.sign_define
sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
sign("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }) --
sign("DapBreakpointRejected", { text = "R", texthl = "DiagnosticError", numhl = "DiagnosticError" })
sign("DapLogPoint", { text = "L", texthl = "DapLogPoint", linehl = "", numhl = "" })
sign("DapStopped", { text = "", texthl = "DiagnosticSignHint", numbhl = "", linehl = "" })

--sign('DapBreakpoint', { text = '', texthl = 'DiagnosticSignError', numbhl = '', linehl = '' })
--sign("DapLogPoint", { text = '.>', texthl = 'DiagnosticInfo', numhl = 'DiagnosticInfo' })
--vim.fn.sign_define("DapBreakpointCondition", { text = '?>', texthl = 'DiagnosticInfo', numhl = 'DiagnosticInfo' })
--vim.fn.sign_define("DapStopped", { text = '=>', texthl = 'DiagnosticWarn', numhl = 'DiagnosticWarn' })
--vim.fn.sign_define("DapBreakpoint", { text = '<>', texthl = 'DiagnosticInfo', numhl = 'DiagnosticInfo' })

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.disconnect["dapui_config"] = function()
  dapui.close()
end

require("nvim-dap-virtual-text").setup({
  enabled = true,
  enabled_commands = true,
    highlight_changed_variables = true,
    highlight_new_as_changed = false,
    show_stop_reason = true,
    commented = true,
    only_first_definition = true,
    all_references = false,
    filter_references_pattern = "<module",
    virt_text_pos = "eol",
    all_frames = false,
    virt_text_win_col = nil,
  })
  
  return true
end

return M
