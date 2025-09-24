local M = {}

-- List of preferred colorschemes in order of preference
local preferred_colorschemes = {
  'tokyonight',
  'desert',
  'default'
}

function M.setup()
  -- Try each colorscheme in order of preference
  for _, scheme in ipairs(preferred_colorschemes) do
    local ok = pcall(vim.cmd, 'colorscheme ' .. scheme)
    if ok then
      return true
    end
  end
  
  -- If all else fails, use the built-in default
  vim.cmd('colorscheme default')
  return true
end

return M
