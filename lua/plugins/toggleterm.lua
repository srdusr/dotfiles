local M = {}

--- Setup and configure toggleterm.nvim
-- This function initializes and configures the toggleterm plugin for terminal management
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, toggleterm = pcall(require, 'toggleterm')
  if not ok or not toggleterm then
    return false
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
  
  -- Set up keymaps for toggleterm
  local Terminal = require('toggleterm.terminal').Terminal
  
  -- Custom terminal commands
  local lazygit
  if not Terminal then return end
  local term = Terminal:new({
    cmd = 'lazygit',
    dir = 'git_dir',
    direction = 'float',
    float_opts = {
      border = 'curved',
    },
    on_open = function(term)
      vim.cmd('startinsert!')
      vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 'q', '<cmd>close<CR>', {noremap = true, silent = true})
    end,
  })
  if term then
    lazygit = term
  end
  
  -- Toggle functions
  local function _lazygit_toggle()
    if not Terminal then return end
    if not lazygit then
      init_lazygit()
    end
    if lazygit then
      pcall(lazygit.toggle, lazygit)
    end
  end
  
  -- Set up keymaps
  vim.keymap.set('n', '<leader>tt', '<cmd>ToggleTerm<CR>', {noremap = true, silent = true, desc = 'Toggle Terminal'})
  vim.keymap.set('n', '<leader>tf', '<cmd>ToggleTerm direction=float<CR>', {noremap = true, silent = true, desc = 'Toggle Float Terminal'})
  vim.keymap.set('n', '<leader>th', '<cmd>ToggleTerm size=10 direction=horizontal<CR>', {noremap = true, silent = true, desc = 'Toggle Horizontal Terminal'})
  vim.keymap.set('n', '<leader>tv', '<cmd>ToggleTerm size=80 direction=vertical<CR>', {noremap = true, silent = true, desc = 'Toggle Vertical Terminal'})
  vim.keymap.set('n', '<leader>tl', _lazygit_toggle, {noremap = true, silent = true, desc = 'Toggle Lazygit'})
  
  -- Terminal mode mappings
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], {noremap = true, silent = true})
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], {noremap = true, silent = true})
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], {noremap = true, silent = true})
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], {noremap = true, silent = true})
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], {noremap = true, silent = true})
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], {noremap = true, silent = true})
  
  return true
end

-- Terminal utility functions
local mods = {}

-- Simple empty check function if mods.empty is not available
function mods.empty(v)
  return v == nil or v == ''
end
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
local Terminal
local horizontal_term, vertical_term

-- Safely require toggleterm.terminal
local toggleterm_ok, toggleterm = pcall(require, 'toggleterm.terminal')
if toggleterm_ok and toggleterm and toggleterm.Terminal then
  Terminal = toggleterm.Terminal
  -- Initialize terminals only if Terminal is available
  if Terminal then
    local ok1, hterm = pcall(Terminal.new, Terminal, { hidden = true, direction = 'horizontal' })
    local ok2, vterm = pcall(Terminal.new, Terminal, { hidden = true, direction = 'vertical' })
    if ok1 then horizontal_term = hterm end
    if ok2 then vertical_term = vterm end
  end
end

function Horizontal_term_toggle()
  if horizontal_term then
    pcall(horizontal_term.toggle, horizontal_term, 8, 'horizontal')
  end
end

function Vertical_term_toggle()
  if vertical_term then
    pcall(vertical_term.toggle, vertical_term, math.floor(vim.o.columns * 0.5), 'vertical')
  end
end

-- Initialize lazygit terminal instance
local lazygit = nil
local Cur_cwd = vim.fn.getcwd()

-- Function to initialize lazygit terminal
local function init_lazygit()
  if not Terminal then return nil end
  if not lazygit then
    local ok, term = pcall(function()
      return Terminal:new({
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
      })
    end)
    if ok and term then
      lazygit = term
    end
  end
  return lazygit
end

-- Initialize lazygit on first use
function Lazygit_toggle()
  -- Initialize lazygit if not already done
  if not init_lazygit() then return end
  
  -- cwd is the root of project. if cwd is changed, change the git.
  local cwd = vim.fn.getcwd()
  if cwd ~= Cur_cwd then
    Cur_cwd = cwd
    if lazygit then
      lazygit:close()
    end
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
  if lazygit then
    lazygit:toggle()
  else
    vim.notify("Failed to initialize lazygit terminal", vim.log.levels.ERROR)
  end
end

local node = nil
local ncdu = nil

-- Initialize node terminal if Terminal is available
if Terminal then
  local ok1, nterm = pcall(function() return Terminal:new({ cmd = 'node', hidden = true }) end)
  local ok2, ncduterm = pcall(function() return Terminal:new({ cmd = 'ncdu', hidden = true }) end)
  if ok1 then node = nterm end
  if ok2 then ncdu = ncduterm end
end

function _NODE_TOGGLE()
  if not node then return end
  pcall(node.toggle, node)
end

function _NCDU_TOGGLE()
  if not ncdu then return end
  pcall(ncdu.toggle, ncdu)
end

local htop = nil

function _HTOP_TOGGLE()
  if not Terminal then return end
  if not htop then
    local ok, term = pcall(function() return Terminal:new({ cmd = 'htop', hidden = true }) end)
    if ok then htop = term end
  end
  if htop then
    pcall(htop.toggle, htop)
  end
end

local python = nil

function _PYTHON_TOGGLE()
  if not Terminal then return end
  if not python then
    local ok, term = pcall(function() return Terminal:new({ cmd = 'python', hidden = true }) end)
    if ok then python = term end
  end
  if python then
    pcall(python.toggle, python)
  end
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
