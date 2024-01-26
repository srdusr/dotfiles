local hardtime = require('hardtime')

hardtime.setup({
  -- hardtime config here
  enabled = true,
  restriction_mode = 'hint',
  disabled_filetypes = { 'qf', 'netrw', 'NvimTree', 'NvimTree_1', 'lazy', 'mason', 'oil', 'dashboard' },
  disable_mouse = false,
  disabled_keys = {
    ['<Up>'] = {},
    ['<Down>'] = {},
    ['<Left>'] = {},
    ['<Right>'] = {},
  },
})

-- Function to toggle the hardtime state and echo a message
local hardtime_enabled = true

function ToggleHardtime()
  hardtime.toggle()
  hardtime_enabled = not hardtime_enabled
  local message = hardtime_enabled and 'hardtime on' or 'hardtime off'
  vim.cmd('echo "' .. message .. '"')
end

return {
  ToggleHardtime = ToggleHardtime,
}
