local M = {}

function M.loclist_toggle()
  for _, info in ipairs(vim.fn.getwininfo()) do
    if info.loclist == 1 then
      vim.cmd('lclose')
      return
    end
  end

  if next(vim.fn.getloclist(0)) == nil then
    print('loc list empty')
    return
  end
  vim.cmd('lopen')
end

return M
