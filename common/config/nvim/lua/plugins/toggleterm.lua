local status_ok, toggleterm = pcall(require, 'toggleterm')
if not status_ok then
  return
end
toggleterm.setup({
  --open_mapping = [[<leader>tt]],
  autochdir = true,
  hide_numbers = true,
  shade_filetypes = {},
  shade_terminals = false,
  --shading_factor = 1,
  start_in_insert = true,
  insert_mappings = true,
  terminal_mappings = true,
  persist_size = true,
  direction = 'float',
  --direction = "vertical",
  --direction = "horizontal",
  close_on_exit = true,
  shell = vim.o.shell,
  highlights = {
    -- highlights which map to a highlight group name and a table of it's values
    -- NOTE: this is only a subset of values, any group placed here will be set for the terminal window split
    --Normal = {
    --  background = "#000000",
    --},
    --Normal = { guibg = 'Black', guifg = 'White' },
    --FloatBorder = { guibg = 'Black', guifg = 'DarkGray' },
    --NormalFloat = { guibg = 'Black' },
    float_opts = {
      --winblend = 3,
    },
  },
  size = function(term)
    if term.direction == 'horizontal' then
      return 7
    elseif term.direction == 'vertical' then
      return math.floor(vim.o.columns * 0.4)
    end
  end,
  float_opts = {
    width = 70,
    height = 15,
    border = 'curved',
    highlights = {
      border = 'Normal',
      --background = 'Normal',
    },
    --winblend = 0,
  },
})
local mods = require('user.mods')
local float_handler = function(term)
  if not mods.empty(vim.fn.mapcheck('jk', 't')) then
    vim.keymap.del('t', 'jk', { buffer = term.bufnr })
    vim.keymap.del('t', '<esc>', { buffer = term.bufnr })
  end
end

function _G.set_terminal_keymaps()
  local opts = { noremap = true }
  --local opts = {buffer = 0}
  --vim.api.nvim_buf_set_keymap(0, "i", ";to", "[[<Esc>]]<cmd>Toggleterm", opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-c>', [[<Esc>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
local Terminal = require('toggleterm.terminal').Terminal

local horizontal_term = Terminal:new({ hidden = true, direction = 'horizontal' })
local vertical_term = Terminal:new({ hidden = true, direction = 'vertical' })

function Horizontal_term_toggle()
  horizontal_term:toggle(8, 'horizontal')
end

function Vertical_term_toggle()
  horizontal_term:toggle(math.floor(vim.o.columns * 0.5), 'vertical')
end

local lazygit = Terminal:new({
  cmd = 'lazygit',
  count = 5,
  id = 1000,
  dir = 'git_dir',
  direction = 'float',
  on_open = float_handler,
  hidden = true,
  float_opts = {
    border = { '╒', '═', '╕', '│', '╛', '═', '╘', '│' },
    width = 150,
    height = 40,
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
  -- cwd is the root of project. if cwd is changed, change the git.
  local cwd = vim.fn.getcwd()
  if cwd ~= Cur_cwd then
    Cur_cwd = cwd
    lazygit:close()
    lazygit = Terminal:new({
      cmd = "zsh --login -c 'lazygit'",
      dir = 'git_dir',
      direction = 'float',
      hidden = true,
      on_open = float_handler,
      float_opts = {
        border = { '╒', '═', '╕', '│', '╛', '═', '╘', '│' },
        width = 150,
        height = 40,
      },
    })
  end
  lazygit:toggle()
end

local node = Terminal:new({ cmd = 'node', hidden = true })

function _NODE_TOGGLE()
  node:toggle()
end

local ncdu = Terminal:new({ cmd = 'ncdu', hidden = true })

function _NCDU_TOGGLE()
  ncdu:toggle()
end

local htop = Terminal:new({ cmd = 'htop', hidden = true })

function _HTOP_TOGGLE()
  htop:toggle()
end

local python = Terminal:new({ cmd = 'python', hidden = true })

function _PYTHON_TOGGLE()
  python:toggle()
end

function Gh_dash()
  Terminal:new({
    cmd = 'gh dash',
    hidden = true,
    direction = 'float',
    on_open = float_handler,
    float_opts = {
      height = function()
        return math.floor(vim.o.lines * 0.8)
      end,
      width = function()
        return math.floor(vim.o.columns * 0.95)
      end,
    },
  })
  Gh_dash:toggle()
end
