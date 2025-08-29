require('notify').setup({
  background_colour = '#000000',
  icons = {
    ERROR = '',
    WARN = '',
    INFO = '',
    DEBUG = '',
    TRACE = '✎',
  },
})

vim.api.nvim_command('hi default link NotifyERRORBody Normal')
vim.api.nvim_command('hi default link NotifyWARNBody Normal')
vim.api.nvim_command('hi default link NotifyINFOBody Normal')
vim.api.nvim_command('hi default link NotifyDEBUGBody Normal')
vim.api.nvim_command('hi default link NotifyTRACEBody Normal')
vim.api.nvim_command('hi default link NotifyLogTime Comment')
vim.api.nvim_command('hi default link NotifyLogTitle Special')
