local M = {}

function M.setup()
  local ok, treesitter = pcall(require, "nvim-treesitter.configs")
  if not ok or not treesitter then
    return false
  end

  -- Add custom parser directory to runtime path
  vim.opt.runtimepath:append("$HOME/.local/share/treesitter")

  -- Configure treesitter
  treesitter.setup({
    -- Install parsers in custom directory
    parser_install_dir = "$HOME/.local/share/treesitter",
    
    -- Enable syntax highlighting
    highlight = {
      enable = true,
      -- Disable additional regex-based highlighting to improve performance
      additional_vim_regex_highlighting = false,
    },
    
    -- Enable indentation
    indent = {
      enable = true,
    },
    
    -- Additional modules to enable
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
    
    -- Ensure parsers are installed automatically
    ensure_installed = {
      "bash", "c", "cpp", "css", "dockerfile", "go", "html", 
      "javascript", "json", "lua", "markdown", "python", "rust", 
      "toml", "typescript", "vim", "yaml"
    },
    
    -- Auto-install parsers
    auto_install = true,
  })
  
  return true
end

return M
