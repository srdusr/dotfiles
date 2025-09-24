-- Fix C filetype comments
vim.api.nvim_create_autocmd("Filetype", {
  pattern = "c",
  callback = function()
    vim.bo.commentstring = "//%s"
  end,
  group = comment_augroup,
})

