-- Colorscheme
-- ayu gruvbox molokai onedark srcery everblush vscode edge nightfly doom-one
local colorscheme = "doom-one"
local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
	vim.notify("colorscheme " .. colorscheme .. " not found!")
	return
end

vim.api.nvim_command("syntax on")
vim.api.nvim_command("highlight Normal guibg=none")
vim.api.nvim_command("highlight SignColumn guibg=none")
vim.api.nvim_command("highlight TabLine guibg=#333842 gui=bold")
--vim.api.nvim_command("highlight TabLine guibg=none gui=bold")
--vim.api.nvim_command("highlight TabLineSel guibg=none guifg=none gui=bold")
--vim.api.nvim_command("highlight StatusLine guibg=#333842 gui=bold")
--vim.api.nvim_command("highlight StatusLine guibg=#333842 guifg=#d6d3ea gui=bold")
--vim.api.nvim_command("highlight StatusLine guibg=none gui=bold")
--vim.api.nvim_command("highlight TabLineNC guibg=none gui=bold")
--vim.api.nvim_command("highlight TabLineSel guibg=#bd93f9 gui=bold")
vim.api.nvim_command("highlight Title guibg=none gui=bold")
--vim.api.nvim_command("highlight WinSeparator guibg=none gui=bold")
vim.api.nvim_command("highlight TabLineSel guibg=#333842 gui=bold")
vim.api.nvim_command("highlight TabLineFill guibg=none gui=bold")
vim.api.nvim_command("highlight WinBar guibg=none gui=bold")
vim.api.nvim_command("highlight NormalFloat guibg=none")
--vim.api.nvim_command("highlight MsgSeparator guibg=none")
--vim.api.nvim_command("highlight PmenuSel guibg=none")
--vim.api.nvim_command("highlight winblend guibg=none")
--vim.api.nvim_command("highlight StatusLine guibg=none gui=bold")
--vim.api.nvim_command("highlight StatusLineNC guibg=none gui=bold")
--vim.api.nvim_command("highlight StatusLineNC guibg=none ctermfg=Cyan guifg=#80a0ff gui=bold")
vim.cmd[[
au WinEnter * setl winhl=WinSeparator:WinSeparatorA
au WinLeave * setl winhl=WinSeparator:WinSeparator
]]
require("notify").setup({
	background_colour = "#000000",
})
