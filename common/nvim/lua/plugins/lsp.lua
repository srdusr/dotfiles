local M = {}

-- Safe require helper
local function safe_require(name)
  local ok, mod = pcall(require, name)
  return ok and mod or nil
end

-- Autocmd groups for managing event listeners
local augroup_format = vim.api.nvim_create_augroup("LspFormattingOnSave", { clear = true })
local augroup_diag_float = vim.api.nvim_create_augroup("ShowLineDiagnostics", { clear = true })
local augroup_diag_load = vim.api.nvim_create_augroup("OpenDiagnosticsOnLoad", { clear = true })
local augroup_highlight = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = true })

-- Border for floating windows
local border = {
    { "┌", "FloatBorder" }, { "─", "FloatBorder" }, { "┐", "FloatBorder" },
    { "│", "FloatBorder" }, { "┘", "FloatBorder" }, { "─", "FloatBorder" },
    { "└", "FloatBorder" }, { "│", "FloatBorder" }
}

-- Initialize LSP modules
local function init_modules()
  -- Silently try to load each module
  M.lspconfig = safe_require("lspconfig")
  M.mason = safe_require("mason")
  M.mason_lspconfig = safe_require("mason-lspconfig")
  M.mason_tool_installer = safe_require("mason-tool-installer")
  M.null_ls = safe_require("null-ls")

  if M.null_ls then
    M.builtins = M.null_ls.builtins
  end

  return true
end

-- Check Neovim version compatibility and feature availability
local function has_feature(feature)
  if feature == "diagnostic_api" then
    return vim.fn.has("nvim-0.6") == 1
  elseif feature == "native_lsp_config" then
    -- Check for both vim.lsp.enable AND vim.lsp.config
    return vim.fn.has("nvim-0.11") == 1 and vim.lsp.enable ~= nil
  elseif feature == "lsp_get_client_by_id" then
    return vim.fn.has("nvim-0.10") == 1
  elseif feature == "cmp_nvim_lsp" then
    return pcall(require, "cmp_nvim_lsp")
  elseif feature == "virtual_text_disabled_by_default" then
    return vim.fn.has("nvim-0.11") == 1
  elseif feature == "deprecated_lsp_handlers" then
    -- vim.lsp.handlers.hover and signature_help deprecated in 0.12, removed in 0.13
    return vim.fn.has("nvim-0.12") == 0
  elseif feature == "new_lsp_config_api" then
    -- New LSP config API available from 0.12+
    return vim.fn.has("nvim-0.12") == 1 and vim.lsp.config ~= nil
  end
  return false
end

-- Backwards compatible capabilities setup
local function setup_capabilities()
  local capabilities

  if has_feature("cmp_nvim_lsp") then
    capabilities = require('cmp_nvim_lsp').default_capabilities()
  elseif vim.lsp.protocol and vim.lsp.protocol.make_client_capabilities then
    capabilities = vim.lsp.protocol.make_client_capabilities()
  else
    capabilities = {}
  end

  -- Add snippet support if available
  if capabilities.textDocument then
    capabilities.textDocument.completion = capabilities.textDocument.completion or {}
    capabilities.textDocument.completion.completionItem =
      capabilities.textDocument.completion.completionItem or {}
    capabilities.textDocument.completion.completionItem.snippetSupport = true
  end

  -- Set offset encoding for newer versions (0.11+ supports utf-8 and utf-32)
  if vim.fn.has("nvim-0.11") == 1 then
    capabilities.offsetEncoding = { "utf-8", "utf-32", "utf-16" }
  elseif vim.fn.has("nvim-0.9") == 1 then
    capabilities.offsetEncoding = { "utf-8", "utf-16" }
  end

  return capabilities
end

-- Default LSP keymaps (fallback if external not available)
local function setup_fallback_keymaps(bufnr)
  -- Only set up minimal fallbacks, prefer external setup
  local opts = { buffer = bufnr, silent = true, noremap = true }
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
end

-- Create LSP directory and config files for native LSP
local function setup_native_lsp_configs()
  local config_path = vim.fn.stdpath("config")
  local lsp_dir = config_path .. "/lsp"

  -- Create lsp directory if it doesn't exist
  vim.fn.mkdir(lsp_dir, "p")

  -- LSP server configurations for native config
  local server_configs = {
    lua_ls = {
      cmd = { "lua-language-server" },
      filetypes = { "lua" },
      root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim", "use", "_G", "packer_plugins", "P" },
            disable = {
              "undefined-global",
              "lowercase-global",
              "unused-local",
              "unused-vararg",
              "trailing-space"
            },
          },
          workspace = {
            library = {
              vim.env.VIMRUNTIME,
              "${3rd}/luv/library",
              "${3rd}/busted/library",
            },
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    },

    pyright = {
      cmd = { "pyright-langserver", "--stdio" },
      filetypes = { "python" },
      root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json" },
      settings = {
        python = {
          formatting = {
            provider = "none"
          }
        }
      }
    },

    ts_ls = {
      cmd = { "typescript-language-server", "--stdio" },
      filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
      root_markers = { "tsconfig.json", "jsconfig.json", "package.json" },
      init_options = {
        disableAutomaticTypeAcquisition = true
      },
    },

    rust_analyzer = {
      cmd = { "rust-analyzer" },
      filetypes = { "rust" },
      root_markers = { "Cargo.toml", "rust-project.json" },
    },

    clangd = {
      cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
      root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac" },
    },

    gopls = {
      cmd = { "gopls" },
      filetypes = { "go", "gomod", "gowork", "gotmpl" },
      root_markers = { "go.work", "go.mod" },
      settings = {
        gopls = {
          gofumpt = true,
          codelenses = {
            gc_details = false,
            generate = true,
            regenerate_cgo = true,
            run_govulncheck = true,
            test = true,
            tidy = true,
            upgrade_dependency = true,
            vendor = true,
          },
          hints = {
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            parameterNames = true,
            rangeVariableTypes = true,
          },
          analyses = {
            fieldalignment = true,
            nilness = true,
            unusedparams = true,
            unusedwrite = true,
            useany = true,
          },
          usePlaceholders = true,
          completeUnimported = true,
          staticcheck = true,
          directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
          semanticTokens = true,
        },
      },
    },

    -- Add more basic configs
    bashls = {
      cmd = { "bash-language-server", "start" },
      filetypes = { "sh", "bash" },
    },

    --html = {
    --  cmd = { "vscode-html-language-server", "--stdio" },
    --  filetypes = { "html" },
    --},

    --cssls = {
    --  cmd = { "vscode-css-language-server", "--stdio" },
    --  filetypes = { "css", "scss", "less" },
    --},

    --jsonls = {
    --  cmd = { "vscode-json-language-server", "--stdio" },
    --  filetypes = { "json", "jsonc" },
    --},

    yamlls = {
      cmd = { "yaml-language-server", "--stdio" },
      filetypes = { "yaml", "yml" },
    },
  }

  -- Write config files to lsp directory
  for server_name, config in pairs(server_configs) do
    local file_path = lsp_dir .. "/" .. server_name .. ".lua"
    local file_content = "return " .. vim.inspect(config)

    -- Only write if file doesn't exist to avoid overwriting user customizations
    if vim.fn.filereadable(file_path) == 0 then
      local file = io.open(file_path, "w")
      if file then
        file:write(file_content)
        file:close()
        vim.notify("Created LSP config: " .. file_path, vim.log.levels.DEBUG)
      end
    end
  end

  return vim.tbl_keys(server_configs)
end

-- Set up LSP on_attach function
local function create_on_attach()
  return function(client, bufnr)
    -- Your existing keymap setup function from keys.lua
    if _G.setup_lsp_keymaps then
      _G.setup_lsp_keymaps(bufnr)
    else
      setup_fallback_keymaps(bufnr)
    end

    -- Disable LSP formatting in favor of null-ls (if null-ls is available)
    if M.null_ls then
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    -- Disable specific LSP capabilities to avoid conflicts
    if client.name == "ruff" then
      -- Disable ruff hover in favor of Pyright
      client.server_capabilities.hoverProvider = false
    elseif client.name == "ts_ls" then
      -- Disable ts_ls formatting in favor of prettier via null-ls
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    elseif client.name == "pyright" and M.null_ls then
      -- Disable pyright formatting in favor of black/isort via null-ls
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    -- Set log level (backwards compatible)
    if vim.lsp.set_log_level then
      vim.lsp.set_log_level("warn")
    end

    -- Document highlight on cursor hold
    if client.server_capabilities and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd("CursorHold", {
        group = augroup_highlight,
        buffer = bufnr,
        callback = function()
          if vim.lsp.buf.document_highlight then
            vim.lsp.buf.document_highlight()
          end
        end,
      })
      vim.api.nvim_create_autocmd("CursorMoved", {
        group = augroup_highlight,
        buffer = bufnr,
        callback = function()
          if vim.lsp.buf.clear_references then
            vim.lsp.buf.clear_references()
          end
        end,
      })
    end
  end
end

-- Set up basic LSP configuration
function M.setup()
  -- Initialize all required modules
  init_modules()

  -- Enable virtual_text diagnostics by default for 0.11+ (since it's disabled by default)
  if has_feature("virtual_text_disabled_by_default") then
    vim.diagnostic.config({ virtual_text = true })
  end

  -- Set up Mason if available (useful for tool management)
  if M.mason then
    M.mason.setup({
      ui = {
        border = 'rounded',
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗'
        }
      }
    })
  end

  -- Set up mason-tool-installer if available
  if M.mason_tool_installer then
    M.mason_tool_installer.setup({
      ensure_installed = {
        -- Language servers
        "lua-language-server", "pyright", "typescript-language-server", "rust-analyzer",
        "clangd", "bash-language-server", "yaml-language-server",
        -- Formatters
        "stylua", "clang-format", "prettier", "shfmt", "black", "isort", "goimports",
        "sql-formatter", "shellharden",
        -- Linters/Diagnostics
        "eslint_d", "selene", "flake8", "dotenv-linter", "phpcs",
        -- Utilities
        "jq"
      },
      auto_update = false,
      run_on_start = true,
      start_delay = 3000,
    })
  end

  -- Set up null-ls if available
  if M.null_ls and M.builtins then
    local sources = {
      M.builtins.diagnostics.selene.with({
        condition = function(utils)
          return utils.root_has_file({"selene.toml"})
        end,
      }),
      M.builtins.diagnostics.dotenv_linter,
      M.builtins.diagnostics.tidy,
      M.builtins.diagnostics.phpcs.with({
        condition = function(utils)
          return utils.root_has_file({"phpcs.xml", "phpcs.xml.dist", ".phpcs.xml", ".phpcs.xml.dist"})
        end,
      }),

      -- Formatters (prioritized over LSP formatting)
      M.builtins.formatting.stylua.with({
        extra_args = { "--quote-style", "AutoPreferSingle", "--indent-width", "2", "--column-width", "160" },
        condition = function(utils)
          return utils.root_has_file({"stylua.toml", ".stylua.toml"})
        end,
      }),
      M.builtins.formatting.prettier.with({
        extra_args = { "--single-quote", "--tab-width", "4", "--print-width", "100" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "css", "scss", "less", "html", "json", "jsonc", "yaml", "markdown", "graphql", "handlebars" },
        prefer_local = "node_modules/.bin",
      }),
      M.builtins.formatting.black.with({
        extra_args = { "--fast" },
        prefer_local = ".venv/bin",
      }),
      M.builtins.formatting.isort.with({
        extra_args = { "--profile", "black" },
        prefer_local = ".venv/bin",
      }),
      M.builtins.formatting.goimports,
      M.builtins.formatting.clang_format.with({
        extra_args = { "--style", "{BasedOnStyle: Google, IndentWidth: 4}" }
      }),
      M.builtins.formatting.shfmt.with({
        extra_args = { "-i", "2", "-ci" }
      }),
      M.builtins.formatting.shellharden,
      M.builtins.formatting.sql_formatter,
      M.builtins.formatting.dart_format,

      -- Code actions
      M.builtins.code_actions.gitsigns,
      M.builtins.code_actions.gitrebase,
    }

    M.null_ls.setup({
      sources = sources,
      update_in_insert = false,
      on_attach = function(client, bufnr)
        -- Disable LSP formatting in favor of null-ls
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        local function lsp_supports_method(client, method)
          if client.supports_method then
            return client:supports_method(method)
          elseif client.server_capabilities then
            local capability_map = {
              ["textDocument/formatting"] = "documentFormattingProvider",
              ["textDocument/rangeFormatting"] = "documentRangeFormattingProvider",
              ["textDocument/hover"] = "hoverProvider",
              ["textDocument/signatureHelp"] = "signatureHelpProvider",
              ["textDocument/documentHighlight"] = "documentHighlightProvider",
            }
            local cap = capability_map[method]
            return cap and client.server_capabilities[cap]
          end
          return false
        end

        if lsp_supports_method(client, "textDocument/formatting") then
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup_format,
            buffer = bufnr,
            callback = function()
              if vim.fn.has("nvim-0.8") == 1 then
                vim.lsp.buf.format({
                  async = false,
                  bufnr = bufnr,
                  filter = function(formatting_client)
                    return formatting_client.name == "null-ls"
                  end,
                })
              else
                vim.lsp.buf.formatting_sync()
              end
            end,
          })
        end
      end,
    })
  end

  -- Set up LSP capabilities
  local capabilities = setup_capabilities()
  local on_attach = create_on_attach()

  -- Set up LSP handlers with version compatibility (avoid deprecated APIs)
  if has_feature("deprecated_lsp_handlers") then
    -- Use old handler setup for versions before 0.12
    if vim.lsp.handlers then
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
        vim.lsp.handlers.hover, { border = 'rounded' }
      )

      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
        vim.lsp.handlers.signature_help, { border = 'rounded' }
      )
    end
  else
    -- Use new handler setup for 0.12+ (when old handlers are deprecated/removed)
    if vim.lsp.handlers then
      vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
        vim.lsp.handlers['textDocument/hover'], { border = 'rounded' }
      )

      vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
        vim.lsp.handlers['textDocument/signatureHelp'], { border = 'rounded' }
      )
    end
  end

  -- Choose configuration method based on Neovim version and available features
  if has_feature("native_lsp_config") then
    -- Set up native LSP configuration
    local servers = setup_native_lsp_configs()

    -- Set default on_attach and capabilities for all LSP servers
    vim.lsp.config('*', {
      on_attach = on_attach,
      capabilities = capabilities,
    })

    -- Enable the LSP servers
    vim.lsp.enable(servers)

  elseif M.mason_lspconfig and M.lspconfig then
    -- Set up mason-lspconfig if available
    if M.mason_lspconfig then
      M.mason_lspconfig.setup({
        ensure_installed = {
          "lua_ls", "pyright", "ts_ls", "rust_analyzer", "clangd", "gopls",
          "bashls", "html", "cssls", "jsonls", "yamlls"
        },
        automatic_installation = true,
      })
    end

    -- Use traditional lspconfig with mason
    local enabled_servers = {}

    local server_configs = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim", "use", "_G", "packer_plugins", "P" },
            },
            workspace = {
              library = {
                vim.env.VIMRUNTIME,
                "${3rd}/luv/library",
                "${3rd}/busted/library",
              },
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      },
      pyright = {
        settings = {
          python = {
            formatting = { provider = "none" }
          }
        }
      },
      ts_ls = {
        init_options = {
          disableAutomaticTypeAcquisition = true
        },
      },
      clangd = {
        cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
      },
      gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
          },
        },
      },
    }

    M.mason_lspconfig.setup_handlers({
      function(server_name)
        if not enabled_servers[server_name] then
          local config = server_configs[server_name] or {}
          config.on_attach = on_attach
          config.capabilities = capabilities
          M.lspconfig[server_name].setup(config)
          enabled_servers[server_name] = true
        end
      end,
    })

  elseif M.lspconfig then
    -- Fallback: Set up servers manually if mason-lspconfig is not available
    local servers = { 'lua_ls', 'pyright', 'ts_ls', 'rust_analyzer', 'clangd', 'gopls', 'bashls', 'html', 'cssls', 'jsonls', 'yamlls' }
    local enabled_servers = {}

    for _, server in ipairs(servers) do
      if not enabled_servers[server] and M.lspconfig[server] then
        local config = {
          on_attach = on_attach,
          capabilities = capabilities,
        }
        M.lspconfig[server].setup(config)
        enabled_servers[server] = true
      end
    end
  end

  return true
end

-- Global toggle for diagnostics (backwards compatible)
vim.g.diagnostics_visible = true
function _G.toggle_diagnostics()
  if has_feature("diagnostic_api") then
    if vim.g.diagnostics_visible then
      vim.g.diagnostics_visible = false
      vim.diagnostic.disable()
    else
      vim.g.diagnostics_visible = true
      vim.diagnostic.enable()
    end
  else
    -- Fallback for older versions
    if vim.g.diagnostics_visible then
      vim.g.diagnostics_visible = false
      vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end
    else
      vim.g.diagnostics_visible = true
      vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {}
      )
    end
  end
end

-- Create Mason command if Mason is available
if M.mason then
  vim.api.nvim_create_user_command("Mason", function()
    require("mason.ui").open()
  end, {})
end

-- Automatically show diagnostics in a float window for the current line
if has_feature("diagnostic_api") then
  vim.api.nvim_create_autocmd("CursorHold", {
    group = augroup_diag_float,
    pattern = "*",
    callback = function()
      local opts = {
        focusable = false,
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        border = border,
        source = "always",
        prefix = " ",
        scope = "cursor",
      }
      vim.diagnostic.open_float(nil, opts)
    end,
  })

  -- Autocmd to open the diagnostic window when a file with errors is opened
  vim.api.nvim_create_autocmd({ "LspAttach", "BufReadPost" }, {
    group = augroup_diag_load,
    callback = function()
      local has_errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }) > 0
      if has_errors then
        vim.diagnostic.setqflist({
          open = true,
          title = "Diagnostics",
        })
      end
    end,
  })
end

-- Create Toggle Diagnostic command
vim.api.nvim_create_user_command("ToggleDiagnostics", _G.toggle_diagnostics, {
  desc = "Toggle global diagnostics visibility"
})

return M
