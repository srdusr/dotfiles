local M = {}

--- Setup and configure indent-blankline.nvim
-- This function initializes and configures the indent guides
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, ibl = pcall(require, 'ibl')
  if not ok then
    return false
  end

  local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
  }

  local hooks = require("ibl.hooks")
  -- create the highlight groups in the highlight setup hook, so they are reset
  -- every time the colorscheme changes
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
  end)

  ibl.setup({
  indent = { highlight = highlight },
    exclude = {
      filetypes = {
        "", -- for all buffers without a file type
        "NvimTree",
        "Trouble",
        "TelescopePrompt",
        "TelescopeResults",
        "mason",
        "help",
        "dashboard",
        "packer",
        "neogitstatus",
        "Trouble",
        "text",
        "terminal",
        "lazy",
      },
      buftypes = {
        "terminal",
        "nofile",
        "quickfix",
        "prompt",
      },
    },
  })
  
  -- Toggle indent blankline with <leader>ti
  vim.keymap.set('n', '<leader>ti', '<cmd>IBLToggle<CR>', {
    noremap = true,
    silent = true,
    desc = 'Toggle indent guides'
  })
  
  return true
end

return M
