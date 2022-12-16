local status, treesitter = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

treesitter.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
    --disable = { "python", "css" }
  },
  ensure_installed = {
    "c",
    "bash",
    "lua",
    "rust",
  },
  --ensure_installed = "all", -- one of "all" or a list of languages
  --ignore_install = { "" }, -- List of parsers to ignore installing
  autotag = {
    enable = true,
  },
  efactor = {
    highlight_definitions = { enable = true },
    highlight_current_scope = { enable = true }
  }
}
--vim.opt.foldmethod = "expr"
--vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

--local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
--parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
