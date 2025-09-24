local M = {}

function M.setup()
  local ok, harpoon = pcall(require, "harpoon")
  if not ok or not harpoon then
    return false
  end

  harpoon.setup({
  menu = {
    width = vim.api.nvim_win_get_width(0) - 4,
  },
  --keys = {
  --  { "mt", function() require("harpoon.mark").toggle_file() end, desc = "Toggle File" },
  --  { "mm", function() require("harpoon.ui").toggle_quick_menu() end, desc = "Harpoon Menu" },
  --  { "mc", function() require("harpoon.cmd-ui").toggle_quick_menu() end, desc = "Command Menu" },
  --  --{ "<leader>1", function() require("harpoon.ui").nav_file(1) end, desc = "File 1" },
  --  --{ "<leader>2", function() require("harpoon.ui").nav_file(2) end, desc = "File 2" },
  --  --{ "<leader>3", function() require("harpoon.term").gotoTerminal(1) end, desc = "Terminal 1" },
  --  --{ "<leader>4", function() require("harpoon.term").gotoTerminal(2) end, desc = "Terminal 2" },
  --  --{ "<leader>5", function() require("harpoon.term").sendCommand(1,1) end, desc = "Command 1" },
  --  --{ "<leader>6", function() require("harpoon.term").sendCommand(1,2) end, desc = "Command 2" },
  })

  -- Set up keymaps safely
  local function safe_keymap(mode, lhs, rhs, opts)
    local opts_with_noremap = vim.tbl_extend('force', {noremap = true, silent = true}, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts_with_noremap)
  end

  safe_keymap("n", "<leader>ma", function() require('harpoon.mark').add_file() end, { desc = "Harpoon: Add file" })
  safe_keymap("n", "<leader>mt", function() require('harpoon.mark').toggle_file() end, { desc = "Harpoon: Toggle file" })
  safe_keymap("n", "<leader>mq", function() require('harpoon.ui').toggle_quick_menu() end, { desc = "Harpoon: Toggle quick menu" })
  safe_keymap("n", "<leader>mh", function() require('harpoon.ui').nav_file(1) end, { desc = "Harpoon: Navigate to file 1" })
  safe_keymap("n", "<leader>mj", function() require('harpoon.ui').nav_file(2) end, { desc = "Harpoon: Navigate to file 2" })
  safe_keymap("n", "<leader>mk", function() require('harpoon.ui').nav_file(3) end, { desc = "Harpoon: Navigate to file 3" })
  safe_keymap("n", "<leader>ml", function() require('harpoon.ui').nav_file(4) end, { desc = "Harpoon: Navigate to file 4" })

  return true
end

return M
--
--vim.keymap.set("n", "<leader>a", mark.add_file)
--vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
--
--vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
--vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
--vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
--vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
