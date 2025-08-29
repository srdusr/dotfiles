local ls = require "luasnip" --

require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })
--local options = {
ls.config.set_config {
  history = true,
  updateevents = "TextChanged,TextChangedI",
  -- Autosnippets:
  enable_autosnippets = true, --
  region_check_events = "InsertEnter",
  delete_check_events = "TextChanged",
  update_events = "TextChanged,TextChangedI",
  store_selection_keys = "<Tab>",
  ext_opts = { --
    [require("luasnip.util.types").choiceNode] = {
      active = {
        virt_text = { { "«", "GruvboxOrange" } },
      },
    },
  },
}

--local keymap = vim.keymap
--local keymap = vim.api.nvim_set_keymap
local keymap = vim.keymap.set
--keymap('i', '<c-f>', 'luasnip#expand_or_jumpable() ? "<Plug>luasnip-expand-or-jump" : "<Tab>"', {expr = true, silent = true})
keymap({ "i", "s"}, "<c-f>", function()
  if ls.expand_or_jumpable() then
    ls.expand()
  end
end)

keymap({ "i", "s"}, "<c-j>", function()
  if ls.jumpable(1) then
    ls.jump(1)
  end
end)

keymap({ "i", "s"}, "<c-k>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end)

keymap({ "i", "s"}, "<c-c>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end)

keymap({ "i", "s"}, "<a-c>", function()
  if ls.choice_active() then
    ls.change_choice(-1)
  end
end)

-- Character class	Matching
--  %a	letters (A-Z, a-z)
--  %c	control characters (\n, \t, \r, ...)
--  %d	digits (0-9)
--  %l	lower-case letter (a-z)
--  %p	punctuation characters (!, ?, &, ...)
--  %s	space characters
--  %u	upper-case letters
--  %w	alphanumeric characters (A-Z, a-z, 0-9)
--  %x	hexadecimal digits (\3, \4, ...)
--  %z	the character with representation 0
--  .	  Matches any character
