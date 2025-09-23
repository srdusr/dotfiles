local M = {}

function M.setup()
  local ok, overseer = pcall(require, 'overseer')
  if not ok or not overseer then
    return false
  end

  overseer.setup({})
  
  return true
end

return M
