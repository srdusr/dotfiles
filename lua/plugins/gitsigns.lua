local M = {}

--- Setup and configure gitsigns
-- This function initializes and configures the git signs in the gutter
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, gitsigns = pcall(require, 'gitsigns')
  if not ok then
    return false
  end
  
  gitsigns.setup({
				signs = {
					--add = {
					--	hl = "GitSignsAdd",
					--	text = "▍", --│
					--	numhl = "GitSignsAddNr",
					--	linehl = "GitSignsAddLn",
					--},
					--change = {
					--	hl = "GitSignsChange",
					--	text = "▍", --│
					--	numhl = "GitSignsChangeNr",
					--	linehl = "GitSignsChangeLn",
					--},
					delete = {
						hl = "GitSignsDelete",
						text = "▁", --_━─
						numhl = "GitSignsDeleteNr",
						linehl = "GitSignsDeleteLn",
					},
					topdelete = {
						hl = "GitSignsDelete",
						text = "▔", --‾
						numhl = "GitSignsDeleteNr",
						linehl = "GitSignsDeleteLn",
					},
					changedelete = {
						hl = "GitSignsDelete",
						text = "~",
						numhl = "GitSignsChangeNr",
						linehl = "GitSignsChangeLn",
					},
				},
				current_line_blame = true,
			})

vim.api.nvim_command("highlight DiffAdd guibg=none guifg=#21c7a8")
vim.api.nvim_command("highlight DiffModified guibg=none guifg=#82aaff")
vim.api.nvim_command("highlight DiffDelete guibg=none guifg=#fc514e")
vim.api.nvim_command("highlight DiffText guibg=none guifg=#fc514e")
vim.cmd([[
hi link GitSignsAdd DiffAdd
hi link GitSignsChange DiffModified
hi link GitSignsDelete DiffDelete
hi link GitSignsTopDelete DiffDelete
hi link GitSignsChangedDelete DiffDelete
]])
  -- Set up highlights
  vim.cmd([[
    highlight DiffAdd guibg=none guifg=#21c7a8
    highlight DiffModified guibg=none guifg=#82aaff
    highlight DiffDelete guibg=none guifg=#fc514e
    highlight DiffText guibg=none guifg=#fc514e
    
    hi link GitSignsAdd DiffAdd
    hi link GitSignsChange DiffModified
    hi link GitSignsDelete DiffDelete
    hi link GitSignsTopDelete DiffDelete
    hi link GitSignsChangedelete DiffDelete
    hi link GitSignsChangedeleteLn DiffDelete
    hi link GitSignsChangedeleteNr DiffDeleteNr
  ]])
  
  return true
end

return M
--'signs.delete.hl' is now deprecated, please define highlight 'GitSignsDelete'
--'signs.delete.linehl' is now deprecated, please define highlight 'GitSignsDeleteLn'
--'signs.delete.numhl' is now deprecated, please define highlight 'GitSignsDeleteNr'
--'signs.topdelete.hl' is now deprecated, please define highlight 'GitSignsTopdelete'
--'signs.topdelete.linehl' is now deprecated, please define highlight 'GitSignsTopdeleteLn'
--'signs.topdelete.numhl' is now deprecated, please define highlight 'GitSignsTopdeleteNr'

