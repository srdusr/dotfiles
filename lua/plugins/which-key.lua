local M = {}

function M.setup()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return false
  end

  -- Basic configuration
  wk.setup({
    plugins = {
      marks = true,
      registers = true,
      spelling = { enabled = true, suggestions = 20 },
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
    --window = {
    --  border = "none",
    --  position = "bottom",
    --  margin = { 1, 0, 1, 0 },
    --  padding = { 2, 2, 2, 2 },
    --  winblend = 0
    --},
    --layout = {
    --  height = { min = 4, max = 25 },
    --  width = { min = 20, max = 50 },
    --  spacing = 3,
    --  align = "left"
    --},
    --ignore_missing = false,
    --hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
    --show_help = true,
    --triggers = "<leader>",
    --triggers_blacklist = {
    --  i = { "j", "k" },
    --  v = { "j", "k" },
    --}
  })



  return true
end

return M
