local M = {}

function M.setup()
  local ok, statuscol = pcall(require, "statuscol")
  if not ok or not statuscol then
    return false
  end

  local builtin_ok, builtin = pcall(require, "statuscol.builtin")
  if not builtin_ok or not builtin then
    return false
  end

  statuscol.setup({
    segments = {
        { text = { builtin.lnumfunc }, click = "v:lua.ScLa" },
        { text = { "%s" }, click = "v:lua.ScSa" },
        { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
    },
    ft_ignore = {
        "NvimTree",
        "packer",
        "NeogitStatus",
        "toggleterm",
        "dapui_scopes",
        "dapui_breakpoints",
        "dapui_stacks",
        "dapui_watches",
        "dapui_console",
        "dapui_repl",
    },
  })
  
  return true
end

return M
