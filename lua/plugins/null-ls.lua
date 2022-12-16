local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end
--[[null-ls.]]
--
-- null-language-server i.e. a sort of language server which does not provide any services such as formatting and diagnostics you expect from a language server. Instead it will need to install corresponding external “sources” and then hook these sources into the neovim lsp client through null-ls.
--

null_ls.setup({
	debug = true,
	sources = {
		require("null-ls").builtins.formatting.stylua, -- lua formatting
		require("null-ls").builtins.formatting.prettier.with({ -- markdown, html/js formatting
			filetypes = { "html", "css", "javascript", "javascriptreact", "markdown", "json", "yaml" },
		}),
		require("null-ls").builtins.formatting.shfmt.with({ -- shell script formatting
			filetypes = { "bash", "zsh", "sh" },
		}),
		require("null-ls").builtins.diagnostics.shellcheck, -- shell script diagnostics
    require("null-ls").builtins.code_actions.shellcheck, -- shell script code actions
    --require("null-ls").builtins.formatting.black,
		--require("null-ls").builtins.formatting.prettierd,
		--require("null-ls").builtins.diagnostics.luacheck,
		--require("null-ls").builtins.diagnostics.eslint,
		--require("null-ls").builtins.diagnostics.eslint_d,
		--require("null-ls").builtins.diagnostics.mdl,
		--require("null-ls").builtins.diagnostics.vint,
		--require("null-ls").builtins.codeactions.eslint_d,
    --require("null-ls").builtins.completion.spell,
	},
	on_attach = function(client, bufnr)
		if client.server_capabilities.document_formatting then
			local group = vim.api.nvim_create_augroup("NullLsFormatting", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePre", {
				callback = function()
					vim.lsp.buf.formatting_sync(nil, 4000)
				end,
				buffer = bufnr,
				group = group,
			})
		end
	end,
})
