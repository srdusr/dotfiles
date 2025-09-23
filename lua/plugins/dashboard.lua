local M = {}

--- Setup and configure dashboard.nvim
-- This function initializes and configures the dashboard plugin
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, db = pcall(require, 'dashboard')
  if not ok then
    return false
  end

  local messages = {
    "The only way to do great work is to love what you do. - Steve Jobs",
    "Code is like humor. When you have to explain it, it's bad. - Cory House",
    "First, solve the problem. Then, write the code. - John Johnson",
    "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. - Martin Fowler",
    "The most disastrous thing that you can ever learn is your first programming language. - Alan Kay",
    "The most important property of a program is whether it accomplishes the intention of its user. - C.A.R. Hoare",
    "The best error message is the one that never shows up. - Thomas Fuchs",
    "The most important skill for a programmer is the ability to effectively communicate ideas. - Gastón Jorquera",
    "The only way to learn a new programming language is by writing programs in it. - Dennis Ritchie",
    "The most damaging phrase in the language is 'We've always done it this way!' - Grace Hopper"
  }

  local function get_random_message()
    local random_index = math.random(1, #messages)
    return messages[random_index]
  end

--vim.api.nvim_create_autocmd("VimEnter", {
--    callback = function()
--        -- disable line numbers
--        vim.opt_local.number = false
--        vim.opt_local.relativenumber = false
--        -- always start in insert mode
--    end,
--})

  -- Configure dashboard
  db.setup({
  theme = "hyper",
  config = {
    mru = { limit = 20, label = "" },
    project = { limit = 10 },
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
      {
        desc = " Files",
        group = "Number",
        action = "Telescope find_files",
        key = "f",
      },
      {
        desc = " TODO",
        group = "Number",
        action = ":edit ~/documents/main/inbox/tasks/TODO.md",
        key = "t",
      },
      {
        desc = " New",
        group = "Number",
        action = "enew",
        key = "e",
      },
      {
        desc = " Grep",
        group = "Number",
        action = "Telescope live_grep",
        key = "g",
      },
      {
        desc = " Scheme",
        group = "Number",
        action = "Telescope colorscheme",
        key = "s",
      },
      {
        desc = " Config",
        group = "Number",
        action = ":edit ~/.config/nvim/init.lua",
        key = "c",
      },
    },
    footer = function()
      return { "", "" }
      --return { "", GetRandomMessage() }
    end,
  },
  hide = {
    statusline = false,
    tabline = false,
    winbar = false,
  },
})

-- Set keymaps only when dashboard is active
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("DashboardMappings", { clear = true }),
  pattern = "dashboard",
  callback = function()
    vim.keymap.set("n", "e", "<Cmd>DashboardNewFile<CR>", { buffer = true })
    vim.keymap.set("n", "q", "<Cmd>q!<CR>", { buffer = true })
    vim.keymap.set("n", "<C-o>", "<C-o><C-o>", { buffer = true }) -- Allow Ctrl + o to act normally
  end,
})
---- General
--DashboardHeader DashboardFooter
---- Hyper theme
--DashboardProjectTitle DashboardProjectTitleIcon DashboardProjectIcon
--DashboardMruTitle DashboardMruIcon DashboardFiles DashboardShotCutIcon
---- Doome theme
--DashboardDesc DashboardKey DashboardIcon DashboardShotCut

  return true
end

return M
