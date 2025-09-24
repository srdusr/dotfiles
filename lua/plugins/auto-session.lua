local M = {}

function M.setup()
  local auto = pcall(require, 'auto-session') and require('auto-session')
  if not auto then
    return false
  end

  local nvim_version = vim.version()
  if nvim_version.major == 0 and nvim_version.minor < 5 then
    return false
  end

  -- Configure session options
  vim.opt.sessionoptions:append("localoptions")  -- Add localoptions to sessionoptions

  -- Set up auto-session
  auto.setup({
    log_level = 'info',
    auto_session_suppress_dirs = { '~/', '~/Projects', '~/projects', '~/Downloads', '~/downloads' },
    auto_session_use_git_branch = true,
    bypass_save_filetypes = { "dashboard" },

    -- Additional configuration to handle session options
    pre_save_cmds = {
      -- Ensure local options are saved with the session
      function() vim.opt.sessionoptions:append("localoptions") end,
    },

    -- Post restore hook to ensure local options are properly set
    post_restore = function()
      vim.opt.sessionoptions:append("localoptions")
    end,
  })

  return true
end

return M
