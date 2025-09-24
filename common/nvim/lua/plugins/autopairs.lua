local M = {}

--- Setup and configure nvim-autopairs
-- This function initializes and configures the autopairs plugin
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, autopairs = pcall(require, "nvim-autopairs")
  if not ok then
    return false
  end
  
  -- Configure autopairs
  autopairs.setup({
  check_ts = true,
  ts_config = {
    lua = { "string", "source" },
    javascript = { "string", "template_string" },
    java = false,
  },
  map = "<M-e>",
  pairs_map = {
    ["<"] = ">",
  },
  disable_filetype = { "TelescopePrompt", "spectre_panel" },
  disable_in_macro = true,
  disable_in_visualblock = true,
  enable_moveright = true,
  enable_afterquote = true,          -- add bracket pairs after quote
  enable_check_bracket_line = false, --- check bracket in same line
  enable_bracket_in_quote = true,    --
  break_undo = true,                 -- switch for basic rule break undo sequence
  --fast_wrap = {
  --  chars = { "{", "[", "(", '"', "'" },
  --  pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
  --  offset = 0, -- Offset from pattern match
  --  end_key = "$",
  --  keys = "qwertyuiopzxcvbnmasdfghjkl",
  --  check_comma = true,
  --  highlight = "PmenuSel",
  --  highlight_grey = "LineNr",
  --},
})
local Rule = require("nvim-autopairs.rule")

local cond = require("nvim-autopairs.conds")

autopairs.add_rules({
  Rule("`", "'", "tex"),
  Rule("$", "$", "tex"),
  Rule(" ", " ")
      :with_pair(function(opts)
        local pair = opts.line:sub(opts.col, opts.col + 1)
        return vim.tbl_contains({ "$$", "()", "{}", "[]", "<>" }, pair)
      end)
      :with_move(cond.none())
      :with_cr(cond.none())
      :with_del(function(opts)
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local context = opts.line:sub(col - 1, col + 2)
        return vim.tbl_contains({ "$  $", "(  )", "{  }", "[  ]", "<  >" }, context)
      end),
  Rule("$ ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
  Rule("[ ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
  Rule("{ ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
  Rule("( ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
  Rule("< ", " ", "tex"):with_pair(cond.not_after_regex(" ")):with_del(cond.none()),
})

autopairs.get_rule("$"):with_move(function(opts)
  return opts.char == opts.next_char:sub(1, 1)
end)

-- import nvim-cmp plugin (completions plugin)
local cmp = require("cmp")

-- import nvim-autopairs completion functionality
local cmp_autopairs = require("nvim-autopairs.completion.cmp")

-- make autopairs and completion work together
cmp.event:on(
  "confirm_done",
  cmp_autopairs.on_confirm_done({
    filetypes = {
      tex = false, -- Disable for tex
    },
  })
)

--local cmp_autopairs = require "nvim-autopairs.completion.cmp"
--local cmp_status_ok, cmp = pcall(require, "cmp")
--if not cmp_status_ok then
--  return
--end
--cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done { map_char = { tex = "" } })

  return true
end

return M
