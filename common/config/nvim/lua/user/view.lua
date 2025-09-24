-- ============================================================================
-- View/UI
-- ============================================================================

local M = {}

-- List of available themes (for reference or user selection UI)
M.available_themes = {
  "nightfly", "ayu", "onedark", "doom-one", "nvimgelion", "github_dark", "tokyonight", "bamboo", "oxocarbon"
}

-- Configuration
local default_colorscheme = "tokyonight"
local fallback_colorscheme = "default"

-- Diagnostic icons
local Signs = {
  Error = "✘",
  Warn  = "",
  Hint = "◉",
  Info = "",
}

-- Setup Function
function M.setup()
  -- Truecolor & syntax
  vim.opt.termguicolors = true
  vim.cmd("syntax on")

  -- Colorscheme setup with fallback
  local ok = pcall(vim.cmd, "colorscheme " .. default_colorscheme)
  if not ok then
    vim.cmd("colorscheme " .. fallback_colorscheme)
  end

  -- Optional: Tokyonight configuration
  pcall(function()
    require("tokyonight").setup({
      style = "night",
      transparent = true,
      transparent_sidebar = true,
      dim_inactive = false,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    })
  end)

  -- Highlight groups
  local highlights = {
    -- Core UI
    { group = "Normal", options = { bg = "none" } },
    { group = "NormalNC", options = { bg = "none" } },
    { group = "NormalFloat", options = { bg = "none" } },
    { group = "Float", options = { bg = "none" } },
    { group = "FloatBorder", options = { bg = "none", fg = "#7f8493" } },
    { group = "StatusLine", options = { bg = "none" } },
    { group = "TabLine", options = { bg = "#333842", bold = true } },
    { group = "TabLineSel", options = { bg = "#333842", bold = true } },
    { group = "TabLineFill", options = { bg = "none", bold = true } },
    { group = "WinBar", options = { bg = "none", bold = true } },
    { group = "WinBarNC", options = { bg = "none" } },
    { group = "WinSeparator", options = { bg = "none", fg = "#444b62", bold = true } },
    { group = "EndOfBuffer", options = { bg = "none", fg = "#7f8493" } },
    { group = "NonText", options = { bg = "none", fg = "#555b71" } },
    { group = "LineNr", options = { bg = "none", fg = "#555b71" } },
    { group = "SignColumn", options = { bg = "none" } },
    { group = "FoldColumn", options = { bg = "none" } },
    { group = "CursorLine", options = { bg = "#3a3f52" } },
    { group = "CursorLineNr", options = { bg = "#3a3f52", fg = "#cdd6f4" } },
    { group = "CursorLineSign", options = { bg = "none" } },
    { group = "Title", options = { bg = "none", bold = true } },
    { group = "Comment", options = { bg = "none", fg = "#6b7089" } },
    { group = "MsgSeparator", options = { bg = "none" } },
    { group = "WarningMsg", options = { bg = "none", fg = "#e6c384" } },
    { group = "MoreMsg", options = { bg = "none", fg = "#7f8493" } },

    -- Pop-up / menu
    { group = "Pmenu", options = { bg = "none" } },
    { group = "PmenuSel", options = { fg = "black", bg = "white" } },
    { group = "PmenuThumb", options = { bg = "none" } },
    { group = "PmenuSbar", options = { bg = "none" } },
    { group = "PmenuExtra", options = { bg = "none" } },
    { group = "PmenuExtraSel", options = { bg = "none" } },
    { group = "WildMenu", options = { link = "PmenuSel" } },

    -- Telescope
    { group = "TelescopeNormal", options = { bg = "none" } },
    { group = "TelescopePromptNormal", options = { bg = "none" } },
    { group = "TelescopeResultsNormal", options = { bg = "none" } },
    { group = "TelescopePreviewNormal", options = { bg = "none" } },
    { group = "TelescopeBorder", options = { bg = "none", fg = "#7f8493" } },
    { group = "TelescopeMatching", options = { fg = "#cba6f7", bold = true } },

    -- Blending
    { group = "Winblend", options = { bg = "none" } },
    { group = "Pumblend", options = { bg = "none" } },

    ---- NvimTree
    --{ group = "NvimTreeNormal", options = { bg = "none", fg = "NONE" } },
    --{ group = "NvimTreeNormalNC", options = { bg = "none", fg = "NONE" } },
    --{ group = "NvimTreeNormalFloat", options = { bg = "none" } },
    --{ group = "NvimTreeEndOfBuffer", options = { bg = "none" } },
    --{ group = "NvimTreeCursorLine", options = { bg = "#50fa7b", fg = "#000000" } },
    --{ group = "NvimTreeSymlinkFolderName", options = { fg = "#f8f8f2", bg = "none" } },
    --{ group = "NvimTreeFolderName", options = { fg = "#f8f8f2", bg = "none" } },
    --{ group = "NvimTreeRootFolder", options = { fg = "#f8f8f2", bg = "none" } },
    --{ group = "NvimTreeEmptyFolderName", options = { fg = "#f8f8f2", bg = "none" } },
    --{ group = "NvimTreeOpenedFolderName", options = { fg = "#f8f8f2", bg = "none" } },
    --{ group = "NvimTreeOpenedFile", options = { fg = "#50fa7b", bg = "none" } },
    --{ group = "NvimTreeExecFile", options = { fg = "#ff882a", bg = "none" } },
  }

  for _, hl in ipairs(highlights) do
    vim.api.nvim_set_hl(0, hl.group, hl.options)
  end

  -- Reapply highlights on ColorScheme change
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("CustomHighlights", { clear = true }),
    pattern = "*",
    callback = function()
      for _, hl in ipairs(highlights) do
        vim.api.nvim_set_hl(0, hl.group, hl.options)
      end
    end,
  })

  -- Optional window separator styling
  vim.cmd([[
    augroup CustomWinSeparator
      autocmd!
      autocmd WinEnter * setlocal winhl=WinSeparator:WinSeparatorA
      autocmd WinLeave * setlocal winhl=WinSeparator:WinSeparator
    augroup END
  ]])

  -- Diagnostics configuration
  local border = "rounded"
  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = Signs.Error,
        [vim.diagnostic.severity.WARN] = Signs.Warn,
        [vim.diagnostic.severity.HINT] = Signs.Hint,
        [vim.diagnostic.severity.INFO] = Signs.Info,
      },
    },
    underline = true,
    virtual_text = false,
    virtual_lines = false,
    float = {
      show_header = true,
      source = "always",
      border = border,
      focusable = true,
    },
    update_in_insert = false,
    severity_sort = true,
  })

  -- Fallback statusline if heirline is missing
  local heirline_ok, _ = pcall(require, "heirline")
  if not heirline_ok then
    local statusline_path = vim.fn.stdpath("config") .. "/autoload/statusline.vim"
    if vim.fn.filereadable(statusline_path) == 1 then
      vim.cmd.source(statusline_path)
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.cmd("call autoload#statusline#ActivateStatusline()")
        end,
      })
    else
      vim.notify("Fallback statusline script not found:\n" .. statusline_path, vim.log.levels.ERROR)
    end
  end
end

return M
