require("harpoon").setup({
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
  --},
})
vim.api.nvim_set_keymap("n", "<leader>ma", ":lua require('harpoon.mark').add_file()<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>mt", ":lua require('harpoon.mark').toggle_file()<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>mq", ":lua require('harpoon.ui').toggle_quick_menu()<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>mh", ":lua require('harpoon.ui').nav_file(1)<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>mj", ":lua require('harpoon.ui').nav_file(2)<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>mk", ":lua require('harpoon.ui').nav_file(3)<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>ml", ":lua require('harpoon.ui').nav_file(4)<CR>", {})

--local mark = require("harpoon.mark")
--local ui = require("harpoon.ui")
--
--vim.keymap.set("n", "<leader>a", mark.add_file)
--vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
--
--vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
--vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
--vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
--vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
