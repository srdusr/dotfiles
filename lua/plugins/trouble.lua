local M = {}

--- Setup and configure trouble.nvim
-- This function initializes and configures the trouble plugin for diagnostics and references
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, trouble = pcall(require, 'trouble')
  if not ok then
    return false
  end
  
  trouble.setup({
  position = "bottom", -- bottom, top, left, right
  height = 10,
  width = 50,
  icons = {
    indent = {
      fold = {
        open = "",
        closed = "",
      },
    },
    kinds = {
      -- you can use LSP kind symbols or devicons here
      -- remove if you want default
    },
  },
  modes = {
    diagnostics = {
      groups = { "filename", "kind" },
    },
    symbols = {
      format = "{kind_icon} {symbol.name} {symbol.kind} [{symbol.scope}]",
    },
  },
  action_keys = {
    close = "q",
    cancel = "<esc>",
    refresh = "r",
    jump = { "<cr>", "<tab>" },
    open_split = { "<c-x>" },
    open_vsplit = { "<c-v>" },
    open_tab = { "<c-t>" },
    jump_close = { "o" },
    toggle_preview = "P",
    hover = "K",
    preview = "p",
    close_folds = { "zM", "zm" },
    open_folds = { "zR", "zr" },
    toggle_fold = { "zA", "za" },
    previous = "k",
    next = "j",
  },
  indent_lines = true,
  auto_open = false,
  auto_close = false,
  auto_preview = true,
  auto_fold = false,
  auto_jump = { "lsp_definitions" },
  signs = {
    error = "",
    warning = "▲",
    info = "󰋼",
    hint = "⚑",
    other = "•",
  },
  use_diagnostic_signs = true,
  })
  
  return true
end

return M
