local M = {}

function M.setup()
  local ok, ls = pcall(require, "luasnip")
  if not ok or not ls then
    return false
  end

  -- Safely load snippets
  pcall(function() require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" }) end)
  pcall(function() require("luasnip.loaders.from_vscode").lazy_load() end)
  pcall(function() require("luasnip.loaders.from_snipmate").lazy_load() end)

  ls.config.set_config {
    history = true,
    updateevents = "TextChanged,TextChangedI",
    enable_autosnippets = true,
    region_check_events = "InsertEnter",
    delete_check_events = "TextChanged",
    store_selection_keys = "<Tab>",
    ext_opts = {
      [require("luasnip.util.types").choiceNode] = {
        active = {
          virt_text = { { "«", "GruvboxOrange" } },
        },
      },
    },
  }

  return true
end

return M
