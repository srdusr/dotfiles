local M = {}

function M.setup()
  local ok, neoscroll = pcall(require, 'neoscroll')
  if not ok then
    return false
  end
  
  -- Basic configuration
  neoscroll.setup({
    mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
    hide_cursor = true,
    stop_eof = true,
    respect_scrolloff = false,
    cursor_scrolls_alone = true,
    easing_function = 'quadratic',
  })
  
  return true
end

return M
