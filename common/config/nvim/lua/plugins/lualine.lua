-- lualine.nvim plugin config (modular, robust)
local ok, lualine = pcall(require, 'lualine')
if not ok then return end
local nvim_version = vim.version()
if nvim_version.major == 0 and nvim_version.minor < 5 then return end
lualine.setup({
  options = {
    theme = 'auto',
    icons_enabled = true,
    section_separators = '',
    component_separators = '',
    disabled_filetypes = {},
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'},
  },
}) 