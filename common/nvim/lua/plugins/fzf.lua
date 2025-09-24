local M = {}

if not fzfLua then
  return M
end

local ok_fzfLua, actions = pcall(require, "fzf-lua")
if not ok_fzfLua then
  return
end

local ok_fzfLua, actions = pcall(require, "fzf-lua.actions")
if not ok_fzfLua then
  return
end


local ok, fzfLua = pcall(require, "fzf-lua")
if not ok then
  vim.notify("fzf-lua not found", vim.log.levels.WARN)
  return M
end

fzfLua.setup({
  defaults = {
    file_icons = "mini",
  },
  winopts = {
    row = 0.5,
    height = 0.7,
  },
  files = {
    previewer = false,
  },
})

vim.keymap.set("n", "<leader>fz", "<cmd>FzfLua files<cr>", { desc = "Fuzzy find files" })
vim.keymap.set("n", "<leader>fzg", "<cmd>FzfLua live_grep<cr>", { desc = "Fuzzy grep files" })
vim.keymap.set("n", "<leader>fzh", "<cmd>FzfLua helptags<cr>", { desc = "Fuzzy grep tags in help files" })
vim.keymap.set("n", "<leader>fzt", "<cmd>FzfLua btags<cr>", { desc = "Fuzzy search buffer tags" })
vim.keymap.set("n", "<leader>fzb", "<cmd>FzfLua buffers<cr>", { desc = "Fuzzy search opened buffers" })

return M
