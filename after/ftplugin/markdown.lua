vim.wo.spell = true
vim.bo.spelllang = "en"
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.colorcolumn = "0"
--vim.wo.conceallevel = 3
vim.opt.softtabstop = 2 -- Tab key indents by 2 spaces.
vim.opt.shiftwidth = 2  -- >> indents by 2 spaces.
-- vim.g.markdown_recommended_style = 0 -- prevents markdown from changing tabs to 4 spaces

vim.b[0].undo_ftplugin = "setlocal nospell nowrap nolinebreak nobreakindent conceallevel=0"

vim.cmd([[
  autocmd FileType markdown iabbrev <buffer> `` ``
]])

require("nvim-surround").buffer_setup({
  surrounds = {
    -- ["e"] = {
    --   add = function()
    --     local env = require("nvim-surround.config").get_input ("Environment: ")
    --     return { { "\\begin{" .. env .. "}" }, { "\\end{" .. env .. "}" } }
    --   end,
    -- },
    ["b"] = {
      add = { "**", "**" },
      find = "**.-**",
      delete = "^(**)().-(**)()$",
    },
    ["i"] = {
      add = { "_", "_" },
      find = "_.-_",
      delete = "^(_)().-(_)()$",
    },
  },
})
