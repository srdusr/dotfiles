-- Colorscheme

-- Colors
vim.opt.termguicolors = true

-- Available colorschemes:
-- [[ nightfly ayu onedark doom-one nvimgelion github_dark tokyonight bamboo ]]

require('tokyonight').setup({
  style = 'night',
  transparent = true,
  transparent_sidebar = true,
  dim_inactive = false,
  styles = {
    sidebars = 'transparent',
    floats = 'transparent',
  },
})

-- Define default color scheme
local default_colorscheme = 'tokyonight-night'
local fallback_colorscheme = 'desert'

-- Attempt to set the default color scheme
local status_ok, _ = pcall(vim.cmd, 'colorscheme ' .. default_colorscheme)

-- If the default color scheme is not found, use the fallback color scheme
if not status_ok then
  vim.cmd('colorscheme ' .. fallback_colorscheme)
end

vim.api.nvim_command('syntax on')
vim.api.nvim_command('highlight Normal guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight NormalNC guibg=NONE')
vim.api.nvim_command('highlight NormalFloat guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight Float guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight NonText guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight SignColumn guibg=NONE')
vim.api.nvim_command('highlight FoldColumn guibg=NONE')
vim.api.nvim_command('highlight CursorLineSign guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight Title guibg=NONE gui=bold')
vim.api.nvim_command('highlight TabLine guibg=#333842 gui=bold')
vim.api.nvim_command('highlight TabLineSel guibg=#333842 gui=bold')
vim.api.nvim_command('highlight TabLineFill guibg=NONE gui=bold')
vim.api.nvim_command('highlight WinBar guibg=NONE ctermbg=NONE gui=bold')
vim.api.nvim_command('highlight WinBarNC guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight LineNr guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight WinSeparator guibg=NONE gui=bold ctermbg=NONE')
vim.api.nvim_command('highlight MsgSeparator guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight EndOfBuffer guibg=NONE guifg=Normal')
vim.api.nvim_command('highlight Comment guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight Winblend guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight NormalFloat guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight Pumblend guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight WildMenu guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight WarningMsg guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight Pmenu guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight PmenuSel guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight PmenuThumb guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight PmenuSbar guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight PmenuExtra guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight PmenuExtraSel guibg=NONE ctermbg=NONE')
vim.api.nvim_command('highlight MoreMsg guibg=NONE ctermbg=NONE')

-- Set different window separator colorscheme
vim.cmd([[
au WinEnter * setl winhl=WinSeparator:WinSeparatorA
au WinLeave * setl winhl=WinSeparator:WinSeparator
]])
