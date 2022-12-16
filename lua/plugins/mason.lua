local status, mason = pcall(require, "mason")
if (not status) then return end
local status2, lspconfig = pcall(require, "mason-lspconfig")
if (not status2) then return end

mason.setup({

})

lspconfig.setup {
  ensure_installed = { "sumneko_lua" },
}
local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true }


keymap('n', 'gd', ':lua vim.lsp.buf.definition()<cr>', opts)
keymap('n', 'gD', ':lua vim.lsp.buf.declaration()<cr>', opts)
keymap('n', 'gi', ':lua vim.lsp.buf.implementation()<cr>', opts)
keymap('n', 'gw', ':lua vim.lsp.buf.document_symbol()<cr>', opts)
keymap('n', 'gw', ':lua vim.lsp.buf.workspace_symbol()<cr>', opts)
keymap('n', 'gr', ':lua vim.lsp.buf.references()<cr>', opts)
keymap('n', 'gt', ':lua vim.lsp.buf.type_definition()<cr>', opts)
keymap('n', 'K', ':lua vim.lsp.buf.hover()<cr>', opts)
keymap('n', '<c-k>', ':lua vim.lsp.buf.signature_help()<cr>', opts)
keymap('n', '<leader>af', ':lua vim.lsp.buf.code_action()<cr>', opts)
keymap('n', '<leader>rn', ':lua vim.lsp.buf.rename()<cr>', opts)



--local mason = require("mason")
--
--local options = {
--  ensure_installed = { "lua-language-server" }, -- not an option from mason.nvim
--
--  ui = {
--    icons = {
--      package_pending = " ",
--      package_installed = " ",
--      package_uninstalled = " ﮊ",
--    },
--
--    keymaps = {
--      toggle_server_expand = "<CR>",
--      install_server = "i",
--      update_server = "u",
--      check_server_version = "c",
--      update_all_servers = "U",
--      check_outdated_servers = "C",
--      uninstall_server = "X",
--      cancel_installation = "<C-c>",
--    },
--  },
--
--  max_concurrent_installers = 10,
--}
--
--
--
--mason.setup(options)

