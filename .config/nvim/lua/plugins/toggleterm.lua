local status_ok, toggleterm = pcall(require, "toggleterm")
if not status_ok then
	return
end

toggleterm.setup({
	--size = function(term)
	--	if term.direction == "horizontal" then
	--		return 12
	--	elseif term.direction == "vertical" then
	--		return vim.o.columns * 0.3
	--	end
	--end,
	--size = 20,
	open_mapping = [[<leader>tt]],
	hide_numbers = true,
	shade_filetypes = {},
	shade_terminals = false,
	shading_factor = 1,
	start_in_insert = true,
	insert_mappings = true,
	persist_size = true,
	direction = "float",
	--direction = "vertical",
	--direction = "horizontal",
	close_on_exit = true,
	shell = vim.o.shell,
	highlights = {
		-- highlights which map to a highlight group name and a table of it's values
		-- NOTE: this is only a subset of values, any group placed here will be set for the terminal window split
		Normal = {
			background = "#000000",
		},
  --float_opts = {
  --  border = as.style.current.border,
  --  winblend = 3,
  --},
  size = function(term)
    if term.direction == 'horizontal' then
      return 15
    elseif term.direction == 'vertical' then
      return math.floor(vim.o.columns * 0.4)
    end
  end,
  },
	float_opts = {
		width = 70,
		height = 15,
		winblend = 3,
		border = "curved",
		--winblend = 0,
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
})
local mods = require("user.mods")
local float_handler = function(term)

  if not mods.empty(vim.fn.mapcheck('jj', 't')) then
    vim.keymap.del('t', 'jj', { buffer = term.bufnr })
    vim.keymap.del('t', '<esc>', { buffer = term.bufnr })
  end
end

function _G.set_terminal_keymaps()
	local opts = { noremap = true }
	--local opts = {buffer = 0}
	vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "jj", [[<C-\><C-n>]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
	vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
--vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")

local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({
  cmd = "lazygit",
  count = 5,
  dir = "git_dir",
  direction = "float",
  on_open = float_handler,
  hidden = true,
  float_opts = {
    border = { '╒', '═', '╕', '│', '╛', '═', '╘', '│' },
    width = 150,
    height = 40
  },
  ---- Function to run on opening the terminal
  --on_open = function(term)
  --  vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 'q', '<cmd>close<CR>',
  --                              {noremap = true, silent = true})
  --  vim.api.nvim_buf_set_keymap(term.bufnr, 'n', '<esc>', '<cmd>close<CR>',
  --                              {noremap = true, silent = true})
  --  vim.api.nvim_buf_set_keymap(term.bufnr, 'n', '<C-\\>', '<cmd>close<CR>',
  --                              {noremap = true, silent = true})
  --end,
  ---- Function to run on closing the terminal
  --on_close = function(term)
  --   vim.cmd("startinsert!")
  --end
})

function Lazygit_toggle()
  lazygit:toggle()
end

local node = Terminal:new({ cmd = "node", hidden = true })

function _NODE_TOGGLE()
	node:toggle()
end

local ncdu = Terminal:new({ cmd = "ncdu", hidden = true })

function _NCDU_TOGGLE()
	ncdu:toggle()
end

local htop = Terminal:new({ cmd = "htop", hidden = true })

function _HTOP_TOGGLE()
	htop:toggle()
end

local python = Terminal:new({ cmd = "python", hidden = true })

function _PYTHON_TOGGLE()
	python:toggle()
end

