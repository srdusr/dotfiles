
local fn = vim.fn
local keymap = vim.keymap

local utils = require("utils")

local custom_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

	-- Mappings.
	local map = function(mode, l, r, opts)
		opts = opts or {}
		opts.silent = true
    opts.noremap = true
		opts.buffer = bufnr
		keymap.set(mode, l, r, opts)
	end
--map("n", "gd", "<Cmd>Lspsaga lsp_finder<CR>") -- Press "o" to open the reference location
--map("n", "gp", "<Cmd>Lspsaga peek_definition<CR>")
--	--map("n", "gd", vim.lsp.buf.definition, { desc = "go to definition" })
--  map("n", "<C-]>", vim.lsp.buf.definition)
--	map("n", "K", vim.lsp.buf.hover)
--	map("n", "<C-k>", vim.lsp.buf.signature_help)
--	map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "varialble rename" })
--	map("n", "gr", vim.lsp.buf.references, { desc = "show references" })
--	map("n", "[d", vim.diagnostic.goto_prev, { desc = "previous diagnostic" })
--	map("n", "]d", vim.diagnostic.goto_next, { desc = "next diagnostic" })
--	map("n", "<leader>q", function()
--		vim.diagnostic.setqflist({ open = true })
--	end, { desc = "put diagnostic to qf" })
--	--map.('n', '<space>q', vim.diagnostic.setloclist)
--	map("n", "ga", vim.lsp.buf.code_action, { desc = "LSP code action" })
--	map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "add workspace folder" })
--	map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, { desc = "remove workspace folder" })
--	map("n", "<leader>wl", function()
--		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
--	end, { desc = "list workspace folder" })
--	map("n", "gs", "vim.lsp.buf.document_symbol()<cr>")
--	map("n", "gw", "vim.lsp.buf.workspace_symbol()<cr>", { desc = "list workspace folder" })
--	--map("n", "gs", ":lua vim.lsp.buf.document_symbol()<cr>")
--	map("n", "gt", ":lua vim.lsp.buf.type_definition()<cr>")
--	map("n", "gD", ":lua vim.lsp.buf.declaration()<cr>") -- most lsp servers don't implement textDocument/Declaration, so gD is useless for now.
--	map("n", "gi", ":lua vim.lsp.buf.implementation()<cr>")
--	map("n", "go", ":lua vim.diagnostic.open_float()<cr>")
--	map("n", "gk", "<Cmd>Lspsaga diagnostic_jump_prev<CR>")
--	map("n", "gj", "<Cmd>Lspsaga diagnostic_jump_next<CR>")

	-- Set some key bindings conditional on server capabilities
	if client.server_capabilities.documentFormattingProvider then
		map("n", "<space>f", vim.lsp.buf.format, { desc = "format code" })
	end

	-- add rust specific keymappings
	if client.name == "rust_analyzer" then
		map("n", "<leader>rr", "<cmd>RustRunnables<CR>")
		map("n", "<leader>ra", "<cmd>RustHoverAction<CR>")
	end

	-- Diagnostic position
	vim.api.nvim_create_autocmd("CursorHold", {
		buffer = bufnr,
		callback = function()
			local float_opts = {
				focusable = false,
				close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
				border = "rounded",
				source = "always", -- show source in diagnostic popup window
				prefix = " ",
			}

			if not vim.b.diagnostics_pos then
				vim.b.diagnostics_pos = { nil, nil }
			end

			local cursor_pos = vim.api.nvim_win_get_cursor(0)
			if
				(cursor_pos[1] ~= vim.b.diagnostics_pos[1] or cursor_pos[2] ~= vim.b.diagnostics_pos[2])
				and #vim.diagnostic.get() > 0
			then
				vim.diagnostic.open_float(nil, float_opts)
			end

			vim.b.diagnostics_pos = cursor_pos
		end,
	})

	-- The below command will highlight the current variable and its usages in the buffer.
	if client.server_capabilities.documentHighlightProvider then
		vim.cmd([[
      hi! link LspReferenceRead Visual
      hi! link LspReferenceText Visual
      hi! link LspReferenceWrite Visual
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]])
	end

	if vim.g.logging_level == "debug" then
		local msg = string.format("Language server %s started!", client.name)
		vim.notify(msg, vim.log.levels.DEBUG, { title = "Server?" })
	end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.offsetEncoding = { "utf-16" }

local lspconfig = require("lspconfig")

if utils.executable("pylsp") then
	lspconfig.pylsp.setup({
		settings = {
			pylsp = {
				plugins = {
					pylint = { enabled = true, executable = "pylint" },
					pyflakes = { enabled = false },
					pycodestyle = { enabled = false },
					jedi_completion = { fuzzy = true },
					pyls_isort = { enabled = true },
					pylsp_mypy = { enabled = true },
				},
			},
		},
		flags = {
			debounce_text_changes = 200,
		},
		capabilities = capabilities,
	})
else
	vim.notify("pylsp not found!", vim.log.levels.WARN, { title = "Server?" })
end

-- if utils.executable('pyright') then
--   lspconfig.pyright.setup{
--     on_attach = custom_attach,
--     capabilities = capabilities
--   }
-- else
--   vim.notify("pyright not found!", vim.log.levels.WARN, {title = 'Server?'})
-- end

if utils.executable("clangd") then
	lspconfig.clangd.setup({
		on_attach = custom_attach,
		capabilities = capabilities,
		filetypes = { "c", "cpp", "cc" },
		flags = {
			debounce_text_changes = 500,
		},
	})
else
	vim.notify("clangd not found!", vim.log.levels.WARN, { title = "Server?" })
end

-- set up vim-language-server
if utils.executable("vim-language-server") then
	lspconfig.vimls.setup({
		on_attach = custom_attach,
		flags = {
			debounce_text_changes = 500,
		},
		capabilities = capabilities,
	})
else
	vim.notify("vim-language-server not found!", vim.log.levels.WARN, { title = "Server?" })
end

-- set up bash-language-server
if utils.executable("bash-language-server") then
	lspconfig.bashls.setup({
		on_attach = custom_attach,
		capabilities = capabilities,
	})
end

if utils.executable("lua-language-server") then
	lspconfig.sumneko_lua.setup({
		on_attach = custom_attach,
		settings = {
			Lua = {
				runtime = {
					-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
					version = "LuaJIT",
				},
				diagnostics = {
					-- Get the language server to recognize the `vim` global
					globals = { "vim" },
				},
				workspace = {
					-- Make the server aware of Neovim runtime files,
					library = {
						fn.stdpath("data") .. "/site/pack/packer/opt/emmylua-nvim",
						fn.stdpath("config"),
					},
					maxPreload = 2000,
					preloadFileSize = 50000,
				},
			},
		},
		capabilities = capabilities,
	})
end


if utils.executable("rust-language-server") then
require("lspconfig").rust_analyzer.setup{
    cmd = { "rustup", "run", "nightly", "rust-analyzer" },
    on_attach = custom_attach,
  	flags = {
			debounce_text_changes = 500,
		},
	--[[
    settings = {
        rust = {
            unstable_features = true,
            build_on_save = false,
            all_features = true,
        },
    }
    --]]
}
end



-- Global config for diagnostic
vim.diagnostic.config({
	underline = false,
	virtual_text = true,
	signs = true,
	severity_sort = true,
	float = {
    focusable = true, --
    style = "minimal", --
		--border = "rounded",
    border = "shadow",
		source = "always",
		header = "",
		prefix = "",
	},
})

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = false,
	virtual_text = false,
	signs = true,
	update_in_insert = false,
})
--vim.lsp.buf.definition
--vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })

--local signs = { Error = " ", Warn = " ", Info = "􀅴 ", Hint = " " }
--local signs = { Error = "✘", Warn = "▲", Info = "🛈 ", Hint = "⚑" }
local signs = { Error = "✘", Warn = "▲", Info = "􀅳", Hint = "⚑" }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end
