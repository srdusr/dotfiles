local M = {}

function M.setup()
  local ok, notify = pcall(require, 'notify')
  if not ok or not notify then
    return false
  end

  notify.setup({
    background_colour = '#000000',
    icons = {
      ERROR = '',
      WARN = '',
      INFO = '',
      DEBUG = '',
      TRACE = '✎',
    }
  })

  -- Set highlight groups safely
  local function set_hl(group, link)
    vim.cmd(('hi default link %s %s'):format(group, link))
  end

  set_hl('NotifyERRORBody', 'Normal')
  set_hl('NotifyWARNBody', 'Normal')
  set_hl('NotifyINFOBody', 'Normal')
  set_hl('NotifyDEBUGBody', 'Normal')
  set_hl('NotifyTRACEBody', 'Normal')
  set_hl('NotifyLogTime', 'Comment')
  set_hl('NotifyLogTitle', 'Special')

  return true
end

return M
