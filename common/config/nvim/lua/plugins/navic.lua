local M = {}

function M.setup()
  local ok, navic = pcall(require, "nvim-navic")
  if not ok or not navic then
    return false
  end

  navic.setup({
    icons = {
      File          = " ",
      Module        = " ",
      Namespace     = " ",
      Package       = " ",
      Class         = " ",
      Method        = " ",
      Property      = " ",
      Field         = " ",
      Constructor   = " ",
      Enum          = "練",
      Interface     = "練",
      Function      = " ",
      Variable      = " ",
      Constant      = " ",
      String        = " ",
      Number        = " ",
      Boolean       = "◩ ",
      Array         = " ",
      Object        = " ",
      Key           = " ",
      Null          = "ﳠ ",
      EnumMember    = " ",
      Struct        = " ",
      Event         = " ",
      Operator      = " ",
      TypeParameter = " "
    },
    highlight = false,
    separator = " > ",
    depth_limit = 0,
    depth_limit_indicator = "..",
    safe_output = true,
    lsp = {
      auto_attach = true
    }
  })
  
  return true
end

return M
