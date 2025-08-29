require("gitsigns").setup({
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
