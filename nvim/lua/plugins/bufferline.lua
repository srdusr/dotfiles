require("bufferline").setup({
	options = {
		numbers = "buffer_id", -- | "ordinal" | "buffer_id" | "both" | "none" | function({ ordinal, id, lower, raise }): string,
		close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
		right_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
		left_mouse_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
		middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
    --indicator = {
    --    icon = '', -- this should be omitted if indicator style is not 'icon'
    --    style = 'icon', -- | 'underline' | 'none',
    --},
		--indicator_icon = " ",
		--left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
    modified_icon = '●',
		left_trunc_marker = "",
		right_trunc_marker = "",
		show_buffer_close_icons = true,
		--diagnostics = "nvim_lsp",
		diagnostics = false, --"nvim_lsp", --false, -- | "nvim_lsp" | "coc",
		diagnostics_update_in_insert = false,
		buffer_close_icon = "",
		separator_style = "thin",
		enforce_regular_tabs = true,
		always_show_bufferline = true,
		max_name_length = 25,
		offsets = {
			{
				filetype = "NvimTree",
				text = "File Explorer",
				highlight = "StatusLine",
				text_align = "center",
			},
		},
		custom_areas = {
			right = function()
				local result = {}
				local error = vim.diagnostic.get_count(0, [[Error]])
				local warning = vim.diagnostic.get_count(0, [[Warning]])
				local info = vim.diagnostic.get_count(0, [[Information]])
				local hint = vim.diagnostic.get_count(0, [[Hint]])

				if error ~= 0 then
					result[1] = { text = "  " .. error, fg = "#EC5241" }
				end

				if warning ~= 0 then
					result[2] = { text = "  " .. warning, fg = "#EFB839" }
				end

				if hint ~= 0 then
					result[3] = { text = "  " .. hint, fg = "#A3BA5E" }
				end

				if info ~= 0 then
					result[4] = { text = "  " .. info, fg = "#7EA9A7" }
				end

				return result
			end,
		},
	},
	highlights = {
    background = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    tab = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    tab_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        --fg = tabline_sel_bg,
    },
    tab_close = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    close_button = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    close_button_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    close_button_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    buffer_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    buffer_selected = {
        fg = "002b36",
        bg = "#fdf6e3",
        bold = true,
        italic = true,
    },
    numbers = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    numbers_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    numbers_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        bold = true,
        italic = true,
    },
    diagnostic = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    diagnostic_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    diagnostic_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        bold = true,
        italic = true,
    },
    hint = {
        fg = "#fdf6e3",
        sp = "#002b36",
        bg = "#002b36",
    },
    hint_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    hint_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    hint_diagnostic = {
        fg = "#fdf6e3",
        sp = "#002b36",
        bg = "#002b36",
    },
    hint_diagnostic_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    hint_diagnostic_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    info = {
        fg = "#fdf6e3",
        sp = "#002b36",
        bg = "#002b36",
    },
    info_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    info_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    info_diagnostic = {
        fg = "#fdf6e3",
        sp = "#002b36",
        bg = "#002b36",
    },
    info_diagnostic_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    info_diagnostic_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    warning = {
        fg = "#fdf6e3",
        sp = "#002b36",
        bg = "#002b36",
    },
    warning_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    warning_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    warning_diagnostic = {
        fg = "#fdf6e3",
        sp = "#002b36",
        bg = "#002b36",
    },
    warning_diagnostic_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    warning_diagnostic_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        bold = true,
        italic = true,
    },
    error = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
    },
    error_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    error_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    error_diagnostic = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
    },
    error_diagnostic_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    error_diagnostic_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        sp = "#002b36",
        bold = true,
        italic = true,
    },
    modified = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    modified_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    modified_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    duplicate_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        italic = true,
    },
    duplicate_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
        italic = true
    },
    duplicate = {
        fg = "#fdf6e3",
        bg = "#002b36",
        italic = true
    },
    separator_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    separator_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    separator = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    indicator_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
    },
    pick_selected = {
        fg = "#fdf6e3",
        bg = "#002b36",
        bold = true,
        italic = true,
    },
    pick_visible = {
        fg = "#fdf6e3",
        bg = "#002b36",
        bold = true,
        italic = true,
    },
    pick = {
        fg = "#fdf6e3",
        bg = "#002b36",
        bold = true,
        italic = true,
    },
    --offset_separator = {
    --    fg = win_separator_fg,
    --    bg = separator_background_color,
    --},
   }
})
