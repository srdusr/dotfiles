local lspconfig = require("lspconfig")
local mason_lspconfig = require("mason-lspconfig")
local null_ls = require("null-ls")
-- local lsp_lines = require('lsp_lines')
require("mason").setup()
require("mason-null-ls").setup({ handlers = {}, ensure_installed = nil, automatic_installation = true,
  automatic_setup = true })

local keymap = vim.keymap
local cmd = vim.cmd

local border = { { "┌", "FloatBorder" }, { "─", "FloatBorder" }, { "┐", "FloatBorder" }, { "│", "FloatBorder" },
  { "┘", "FloatBorder" }, { "─", "FloatBorder" }, { "└", "FloatBorder" }, { "│", "FloatBorder" } }

-- Set up LSP servers if not done before
if not vim.g.lsp_setup_done then
  -- Clear existing LSP clients
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local clients = require("user.mods").get_lsp_clients(bufnr)

    for _, client in ipairs(clients) do
      client.stop()
    end
  end

  local signs = { Error = " ", Warn = "▲", Info = "􀅳", Hint = "⚑" }
  -- 
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  -- lsp_lines.setup()

  -- vim.keymap.set("n", "g?", function()
  --  local lines_enabled = not vim.diagnostic.config().virtual_lines
  --  vim.diagnostic.config(
  --    {
  --      virtual_lines = lines_enabled,
  --      virtual_text = not lines_enabled
  --    }
  --  )
  -- end, { noremap = true, silent = true })

  vim.diagnostic.config({
    underline = false,
    signs = true,
    virtual_text = true, -- virtual_lines = { only_current_line = true },
    virtual_lines = false,
    float = {
      show_header = true,
      source = "if_many", -- border = 'rounded',
      border = border,
      focusable = true,
    },
    update_in_insert = false, -- default to false
    severity_sort = true,     -- default to false
  })

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics,
    { underline = false, virtual_text = false, signs = true, update_in_insert = false })

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

  -- Use an on_attach function to only map the following keys after the language server attaches to the current buffer
  local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
    local map = function(mode, l, r, opts)
      opts = opts or {}
      opts.silent = true
      opts.noremap = true
      opts.buffer = bufnr
      keymap.set(mode, l, r, opts)
    end
    -- Mappings
    map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>")
    -- map("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>")
    map("n", "gd", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>")
    -- map("n", "gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>")
    map("n", "gi", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
    -- map("n", "gr", "<Cmd>lua vim.lsp.buf.references()<CR>")
    map("n", "gr", "<cmd>lua require('goto-preview').goto_preview_references()<CR>")
    map("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>") -- most lsp servers don't implement textDocument/Declaration, so gD is useless for now.
    map("n", "<leader>k", "<Cmd>lua vim.lsp.buf.signature_help()<CR>")
    -- map("n", "gt", "<Cmd>lua vim.lsp.buf.type_definition()<CR>")
    map("n", "gt", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>")
    map("n", "gn", "<Cmd>lua vim.lsp.buf.rename()<CR>")
    map("n", "ga", "<Cmd>lua vim.lsp.buf.code_action()<CR>")
    map("n", "gf", "<Cmd>lua vim.lsp.buf.format()<CR>")
    map("n", "go", "<Cmd>lua vim.diagnostic.open_float()<CR>")
    map("n", "<leader>go",
      ":call utils#ToggleDiagnosticsOpenFloat()<CR> | :echom ('Toggle Diagnostics Float open/close...')<CR> | :sl! | echo ('')<CR>")
    map("n", "gq", "<Cmd>lua vim.diagnostic.setloclist()<CR>")
    map("n", "[d", "<Cmd>lua vim.diagnostic.goto_prev()<CR>")
    map("n", "]d", "<Cmd>lua vim.diagnostic.goto_next()<CR>")
    map("n", "gs", "<Cmd>lua vim.lsp.buf.document_symbol()<CR>")
    map("n", "gw", "<Cmd>lua vim.lsp.buf.workspace_symbol()<CR>")
    map("n", "<leader>wa", "<Cmd>lua vim.lsp.buf.add_workspace_folder()<CR>")
    map("n", "<leader>wr", "<Cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>")
    map("n", "<leader>wl", function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end)

    -- TODO: Use the nicer new API for autocommands
    cmd("augroup lsp_aucmds")
    if client.server_capabilities.documentHighlightProvider then
      cmd("au CursorHold <buffer> lua vim.lsp.buf.document_highlight()")
      cmd("au CursorMoved <buffer> lua vim.lsp.buf.clear_references()")
    end
    cmd("augroup END")
  end

  -- Toggle diagnostics visibility
  vim.g.diagnostics_visible = true
  function _G.toggle_diagnostics()
    if vim.g.diagnostics_visible then
      vim.g.diagnostics_visible = false
      vim.diagnostic.disable()
    else
      vim.g.diagnostics_visible = true
      vim.diagnostic.enable()
    end
  end

  -- Open float for diagnostics automatically
  vim.cmd([[
  augroup OpenFloat
        " autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focusable = false,})
        autocmd CursorHold * lua vim.diagnostic.open_float(nil, {focusable = false,})

  augroup END
  ]])

  -- Suppress error messages from lang servers
  vim.lsp.set_log_level("debug")
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require("cmp_nvim_lsp").default_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.offsetEncoding = { "utf-8", "utf-16" }

  local function prefer_null_ls_fmt(client)
    client.server_capabilities.documentHighlightProvider = true
    client.server_capabilities.documentFormattingProvider = true
    on_attach(client)
  end

  --local cmp_nvim_lsp = require('cmp_nvim_lsp')
  local servers = {
    asm_lsp = {},
    bashls = {},
    clangd = {
      on_attach = on_attach,
      capabilites = capabilities,
      cmd = { "clangd", "--offset-encoding=utf-16", "--cross-file-rename", "--header-insertion=never",
        "--suggest-missing-includes" },
      init_options = {
        clangdFileStatus = true,
      },
      root_files = {
        ".clangd",
        ".clang-tidy",
        ".clang-format",
        "compile_commands.json",
        "compile_flags.txt",
        "configure.ac", -- AutoTools
      },
    },
    cssls = { filetypes = { "css", "scss", "less", "sass" },
      root_dir = lspconfig.util.root_pattern("package.json", ".git") },                                                        -- ghcide = {},
    html = {},
    jsonls = { prefer_null_ls = true, cmd = { "--stdio" } },
    intelephense = {},
    julials = {
      on_new_config = function(new_config, _)
        local julia = vim.fn.expand("~/.julia/environments/nvim-lspconfig/bin/julia")
        if lspconfig.util.path.is_file(julia) then
          new_config.cmd[1] = julia
        end
      end,
      settings = { julia = { format = { indent = 2 } } },
    },
    pyright = { settings = { python = { formatting = { provider = "yapf" }, linting = { pytypeEnabled = true } } } },
    rust_analyzer = {
      settings = {
        ["rust-analyzer"] = { cargo = { allFeatures = true }, checkOnSave = { command = "clippy",
          extraArgs = { "--no-deps" } } },
      },
    },
    dartls = {
      cmd = { "dart", "language-server", "--protocol=lsp" },
      filetypes = { "dart" },
      init_options = {
        closingLabels = true,
        flutterOutline = true,
        onlyAnalyzeProjectsWithOpenFiles = true,
        outline = true,
        suggestFromUnimportedLibraries = true,
      }, -- root_dir = root_pattern("pubspec.yaml"),
      settings = { dart = { completeFunctionCalls = true, showTodos = true } },
      on_attach = function(client, bufnr) end,
    },
    lua_ls = {
      on_attach = on_attach,
      capabilities = capabilities,
      debounce_text_changes = 500,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
          diagnostics = { enable = true, globals = { "vim" } },
          workspace = { maxPreload = 2000, preloadFileSize = 50000, checkThirdParty = false },
        },
      },
    },
    sqlls = {},
    tsserver = {
      capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
      on_attach = function(client)
        client.server_capabilities.document_formatting = false
        client.server_capabilities.document_range_formatting = false
      end,
      filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    },
    vimls = {},
    yamlls = {},
  }

  mason_lspconfig.setup({
    ensure_installed = servers, -- will be installed by mason
    automatic_installation = true,
  })

  -- Your other configurations ...
  -- require("lspconfig").dartls.setup({ capabilities = capabilities })
  -- local installed_lsp = mason_lspconfig.ensure_installed
  -- local mason_lspconfig = require("mason-lspconfig").ensure_installed

  -- require("lspconfig").setup({
  --  function()
  --    for _, lsp in ipairs(installed_lsp) do
  --      if
  --        lsp ~= "sqls"
  --        --and lsp ~= "sumneko_lua"
  --        --and lsp ~= "stylelint_lsp"
  --        --and lsp ~= "rust_analyzer"
  --        --and lsp ~= "sourcekit"
  --        and lsp ~= "dartls"
  --      then
  --        lspconfig[lsp].setup({
  --          on_attach = on_attach,
  --          capabilities = capabilities,
  --        })
  --      end
  --    end
  --  end,
  -- })

  for server, config in pairs(servers) do
    if config.prefer_null_ls then
      if config.on_attach then
        local old_on_attach = config.on_attach
        config.on_attach = function(client, bufnr)
          old_on_attach(client, bufnr)
          prefer_null_ls_fmt(client)
        end
      else
        config.on_attach = prefer_null_ls_fmt
      end
    elseif not config.on_attach then
      config.on_attach = on_attach
    end

    lspconfig[server].setup(config)
  end

  -- null_ls setup
  local builtins = null_ls.builtins
  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

  -- local eslint_opts = {
  --  -- condition = function(utils)
  --  --   return utils.root_has_file ".eslintrc.js" or utils.root_has_file ".eslintrc" or utils.root_has_file ".eslintrc.json"
  --  -- end,
  --  -- diagnostics_format = "#{m} [#{c}]",
  --  prefer_local = true,
  -- }

  -- null_ls.setup({
  local sources = {
    -- Diagnostics
    builtins.diagnostics.chktex,
    -- null_ls.builtins.code_actions.eslint_d,
    -- null_ls.builtins.diagnostics.eslint_d,
    -- null_ls.builtins.formatting.eslint_d,
    -- null_ls.builtins.diagnostics.cppcheck,
    -- null_ls.builtins.diagnostics.proselint,
    -- null_ls.builtins.diagnostics.pylint,
    -- builtins.diagnostics.selene,
    builtins.diagnostics.dotenv_linter,
    builtins.diagnostics.shellcheck.with({ -- shell script diagnostics
      diagnostic_config = {                -- see :help vim.diagnostic.config()
        underline = true,
        virtual_text = false,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
      },
      diagnostics_format = "[#{c}] #{m} (#{s})", -- this will run every time the source runs,
      -- so you should prefer caching results if possible
    }),
    builtins.diagnostics.zsh.with({ filetypes = "zsh", "sh" }),
    builtins.diagnostics.todo_comments,
    builtins.diagnostics.teal,
    -- null_ls.builtins.diagnostics.vale,
    builtins.diagnostics.vint,
    builtins.diagnostics.tidy,
    builtins.diagnostics.php,
    builtins.diagnostics.phpcs,
    builtins.diagnostics.flake8,
    builtins.diagnostics.eslint_d.with({
      condition = function(utils)
        return utils.root_has_file(".eslintrc.json")
      end,
    }),
    builtins.formatting.eslint_d,
    -- null_ls.builtins.diagnostics.write_good.with { filetypes = { 'markdown', 'tex' } },

    -- Formatting
    builtins.formatting.shfmt.with({ filetypes = { "bash", "zsh", "sh" }, extra_args = { "-i", "2", "-ci" } }),
    builtins.formatting.shellharden,
    builtins.formatting.trim_whitespace.with({ filetypes = { "tmux", "teal", "zsh" } }), -- builtins.formatting.beautysh,
    builtins.formatting.beautysh.with({ filetypes = "zsh" }),
    builtins.formatting.clang_format.with({
      filetypes = { "c", "cpp", "cs", "java", "cuda", "proto" },
      extra_args = {
        "--style",
        "{BasedOnStyle: Google, IndentWidth: 4, BreakBeforeBinaryOperators: NonAssignment, AllowShortFunctionsOnASingleLine: None}",
      },
    }),
    --builtins.formatting.rustfmt,
    builtins.formatting.sql_formatter,
    -- null_ls.builtins.formatting.cmake_format,
    builtins.formatting.isort,
    builtins.formatting.htmlbeautifier, -- null_ls.builtins.formatting.prettier,
    builtins.formatting.prettierd,
    builtins.formatting.prettier.with({
      filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "yaml", "markdown", "html",
        "css", "scss", "less", "graphql", "vue", "svelte" },
      extra_args = { "--single-quote", "--tab-width 4", "--print-width 200" },
    }),
    -- builtins.formatting.stylua,
    -- builtins.formatting.lua_format,
    builtins.formatting.stylua.with({
      filetypes = { "lua" },
      command = "stylua",
      args = { "--quote_style", "AutoPreferSingle", "--indent-width", "2", "--column-width", "160", "--indent-type",
        "Spaces", "-" },
    }),
    -- builtins.formatting.dart_format,
    builtins.formatting.dart_format.with({ filetypes = { "dart" } }),
    builtins.formatting.trim_whitespace,
    builtins.formatting.yapf,
    -- null_ls.builtins.formatting.black

    -- Code Actions
    builtins.code_actions.shellcheck, -- shell script code actions
    -- builtins.code_actions.eslint_d.with(eslint_opts),
    -- null_ls.builtins.code_actions.refactoring.with { filetypes = { 'javascript', 'typescript', 'lua', 'python', 'c', 'cpp' } },
    builtins.code_actions.gitsigns,
    builtins.code_actions.gitrebase, -- Hover
    builtins.hover.dictionary,
    builtins.hover.printenv,
  }
  -- })
  -- Linters/Formatters ensure installed
  -- for _, pkg_name in ipairs({
  --  "dart-debug-Adaptor",
  --  "stylua",
  --  "prettier",
  --  "prettierd",
  -- }) do

  -- Import the builtins table from the null-ls module and store it in the null_ls_sources variable
  null_ls.setup({
    sources = sources,
    update_in_insert = true,
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format()
          end,
        })
      end
    end,
  })

  -- Install all the null-ls sources using Mason
  local registry = require("mason-registry")
  for _, source_name in ipairs(sources) do
    local ok, pkg = pcall(registry.get_package, source_name)
    if ok then
      if not pkg:is_installed() then
        pkg:install()
      end
    end
  end
  -- Loop through the null_ls_sources table and install the packages
  -- Install all sources for null-ls
  -- local null_ls_sources = require("null-ls").builtins

  -- for _, source_name in ipairs(null_ls_sources) do
  --  local ok, pkg = pcall(mason.get_package, source_name)
  --  if ok then
  --    if not pkg:is_installed() then
  --      pkg:install()
  --    end
  --  end
  -- end
  vim.api.nvim_create_user_command("NullLsToggle", function()
    -- you can also create commands to disable or enable sources
    require("null-ls").toggle({})
  end, {})

  local null_ls_stop = function()
    local null_ls_client
    local clients = require("user.mods").get_lsp_clients(bufnr)

    for _, client in ipairs(clients) do
      if client.name == "null-ls" then
        null_ls_client = client
      end
    end
    if not null_ls_client then
      return
    end

    null_ls_client.stop()
  end

  vim.api.nvim_create_user_command("NullLsStop", null_ls_stop, {})

  vim.g.lsp_setup_done = true
end
