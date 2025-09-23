-- LuaSnip plugin config (modular, robust)
local ok, luasnip = pcall(require, 'luasnip')
if not ok then return end
local nvim_version = vim.version()
if nvim_version.major == 0 and nvim_version.minor < 5 then return end
-- Load friendly-snippets if available
pcall(function()
  require('luasnip.loaders.from_vscode').lazy_load()
end)
luasnip.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
}) 