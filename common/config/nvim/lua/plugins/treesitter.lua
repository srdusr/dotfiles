require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the four listed parsers should always be installed)

  ensure_installed = {
    "c",
    "bash",
    "lua",
    "rust",
  },
  --ensure_installed = "all", -- one of "all" or a list of languages
  --ignore_install = { "" }, -- List of parsers to ignore installing
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = false,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
    --disable = { "python", "css" }
  },
  autotag = {
    enable = true,
  },
}
--vim.opt.foldmethod = "expr"
--vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

--local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
--parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
