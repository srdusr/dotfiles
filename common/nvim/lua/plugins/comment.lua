local M = {}

--- Setup and configure comment.nvim
-- This function initializes and configures the comment plugin
-- @return boolean True if setup was successful, false otherwise
function M.setup()
  local ok, comment = pcall(require, 'Comment')
  if not ok then
    vim.notify("Comment.nvim not found", vim.log.levels.WARN)
    return false
  end

  -- Configure comment.nvim
  comment.setup({
    -- Add a space b/w comment and the line
    padding = true,
    
    -- Whether the cursor should stay at its position
    sticky = true,
    
    -- Lines to be ignored while (un)commenting
    ignore = '^$',
    
    -- LHS of toggle mappings in NORMAL mode
    toggler = {
      -- Line-comment toggle keymap
      line = 'gcc',
      -- Block-comment toggle keymap
      block = 'gbc',
    },
    
    -- LHS of operator-pending mappings in NORMAL and VISUAL mode
    opleader = {
      -- Line-comment keymap
      line = 'gc',
      -- Block-comment keymap
      block = 'gb',
    },
    
    -- LHS of extra mappings
    extra = {
      -- Add comment on the line above
      above = 'gcO',
      -- Add comment on the line below
      below = 'gco',
      -- Add comment at the end of line
      eol = 'gcA',
    },
    
    -- Enable keybindings
    -- NOTE: If given `false` then the plugin won't create any mappings
    mappings = {
      -- Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
      basic = true,
      -- Extra mapping; `gco`, `gcO`, `gcA`
      extra = true,
      -- Extended mapping; `g>` `g<` `g>[count]{motion}` `g<[count]{motion}`
      extended = false,
    },
    
    -- Function to call before (un)comment
    pre_hook = nil,
    
    -- Function to call after (un)comment
    post_hook = nil,
  })

  -- Additional keymaps for better UX
  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true }
  
  -- Toggle comment for current line or visual selection
  keymap('n', '<leader>cc', '<Plug>(comment_toggle_linewise_current)', opts)
  keymap('n', '<leader>bc', '<Plug>(comment_toggle_blockwise_current)', opts)
  
  -- Toggle comment for current line or visual selection and add new line
  keymap('n', '<leader>cO', '<Plug>(comment_toggle_linewise_above)', opts)
  keymap('n', '<leader>co', '<Plug>(comment_toggle_linewise_below)', opts)
  
  -- Toggle comment for visual selection
  keymap('v', '<leader>cc', '<Plug>(comment_toggle_linewise_visual)', { noremap = false })
  keymap('v', '<leader>bc', '<Plug>(comment_toggle_blockwise_visual)', { noremap = false })
  
  -- Filetype specific settings
  local ft = require('Comment.ft')
  
  -- Set comment string for specific filetypes
  ft.set('lua', { '--%s', '--[[%s]]' })
  ft.set('vim', { '" %s' })
  ft.set('python', { '# %s', '"""%s"""' })
  ft.set('javascript', { '// %s', '/*%s*/' })
  ft.set('typescript', { '// %s', '/*%s*/' })
  ft.set('css', { '/* %s */' })
  ft.set('html', { '<!-- %s -->' })
  
  -- Set up autocommands for specific filetypes
  local group = vim.api.nvim_create_augroup('CommentCustom', { clear = true })
  
  -- Disable comment plugin for certain filetypes
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = {
      'qf', 'help', 'man', 'notify', 'lspinfo', 'packer',
      'checkhealth', 'startuptime', 'Trouble', 'alpha', 'dashboard'
    },
    callback = function()
      vim.b.comment_disable = true
    end,
  })
  
  -- Re-enable comment plugin for normal files
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = { '*' },
    callback = function()
      if vim.bo.buftype == '' then
        vim.b.comment_disable = nil
      end
    end,
  })
  
  return true
end

return M
