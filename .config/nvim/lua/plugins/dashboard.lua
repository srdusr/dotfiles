local db = require("dashboard")
--vim.api.nvim_create_autocmd("VimEnter", {
--    callback = function()
--        -- disable line numbers
--        vim.opt_local.number = false
--        vim.opt_local.relativenumber = false
--        -- always start in insert mode
--    end,
--})
db.setup({
	theme = "hyper",
	config = {
		header = {
			[[  ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗]],
			[[  ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║]],
			[[  ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║]],
			[[  ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║]],
			[[  ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║]],
			[[  ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝]],
		},
    disable_move = false,
		shortcut = {
			{ desc = " Plugins", group = "Number", action = "PackerStatus", key = "p" },
			--{ desc = " Plugins", group = "@property", action = "PackerStatus", key = "p" },
			{
				desc = " Files",
        group = "Number",
				--group = "Label",
				action = "Telescope find_files",
				key = "f",
			},
			{
				desc = " Text",
        group = "Number",
				--group = "Label",
        action =  'enew',
				key = "t",
			},
			{
				desc = " Grep",
        group = "Number",
				--group = "Label",
				action = "Telescope live_grep",
				key = "g",
			},
			{
				desc = " Scheme",
        group = "Number",
				--group = "Label",
				action = "Telescope colorscheme",
				key = "s",
			},
			{
        desc = ' Config',
        group = "Number",
				--group = "Label",
        action = ':edit ~/.config.nvim/init.lua',
        key = "c",
			},
		},
	},
	hide = {
	  statusline = false,
	  tabline = false,
	  winbar = false,
	},
	--  preview = {
--    command,       -- preview command
--    file_path,     -- preview file path
--    file_height,   -- preview file height
--    file_width,    -- preview file width
--  },
--  footer = {}  --your footer
})

--vim.cmd([[
--    autocmd FileType dashboard :highlight DashboardHeader guifg='#b2b2b2'
--    autocmd FileType dashboard :highlight DashboardCenter guifg='#5f8700'
--    autocmd FileType dashboard :highlight DashboardCenterIcon guifg='#0087af'
--    autocmd FileType dashboard :highlight DashboardShortCut guifg='#ffd7ff'
--    autocmd FileType dashboard :highlight DashboardFooter guifg='#878787'
--]])
