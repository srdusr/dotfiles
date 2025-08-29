local db = require('dashboard')
local messages = require('plugins.messages')

function GetRandomMessage()
  -- Get a random index from the messages array
  local randomIndex = math.random(1, #messages)
  return messages[randomIndex]
end

--vim.api.nvim_create_autocmd("VimEnter", {
--    callback = function()
--        -- disable line numbers
--        vim.opt_local.number = false
--        vim.opt_local.relativenumber = false
--        -- always start in insert mode
--    end,
--})

db.setup({
  theme = 'hyper',
  config = {
    mru = { limit = 10, label = '' },
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
      { desc = ' Plugins', group = 'Number', action = 'PackerStatus', key = 'p' },
      --{ desc = " Plugins", group = "@property", action = "PackerStatus", key = "p" },
      {
        desc = ' Files',
        group = 'Number',
        --group = "Label",
        action = 'Telescope find_files',
        key = 'f',
      },
      {
        desc = ' Text',
        group = 'Number',
        --group = "Label",
        action = 'enew',
        key = 't',
      },
      {
        desc = ' Grep',
        group = 'Number',
        --group = "Label",
        action = 'Telescope live_grep',
        key = 'g',
      },
      {
        desc = ' Scheme',
        group = 'Number',
        --group = "Label",
        action = 'Telescope colorscheme',
        key = 's',
      },
      {
        desc = ' Config',
        group = 'Number',
        --group = "Label",
        action = ':edit ~/.config/nvim/init.lua',
        key = 'c',
      },
    },
    footer = function()
      return { '', GetRandomMessage() }
    end,
  },
  hide = {
    statusline = false,
    tabline = false,
    winbar = false,
  },
})

--highlights
---- General
--DashboardHeader DashboardFooter
---- Hyper theme
--DashboardProjectTitle DashboardProjectTitleIcon DashboardProjectIcon
--DashboardMruTitle DashboardMruIcon DashboardFiles DashboardShotCutIcon
---- Doome theme
--DashboardDesc DashboardKey DashboardIcon DashboardShotCut
