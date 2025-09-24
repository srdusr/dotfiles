local M = {}

function M.setup()
  local ok, neotest = pcall(require, "neotest")
  if not ok or not neotest then
    return false
  end

  -- Safely require adapters
  local python_ok, python_adapter = pcall(require, "neotest-python")
  local plenary_ok, plenary_adapter = pcall(require, "neotest-plenary")
  local vim_test_ok, vim_test_adapter = pcall(require, "neotest-vim-test")

  local adapters = {}
  if python_ok and python_adapter then
    table.insert(adapters, python_adapter({
      dap = { justMyCode = false },
    }))
  end
  
  if plenary_ok and plenary_adapter then
    table.insert(adapters, plenary_adapter)
  end
  
  if vim_test_ok and vim_test_adapter then
    table.insert(adapters, vim_test_adapter({
      ignore_file_types = { "python", "vim", "lua" },
    }))
  end

  neotest.setup({
    adapters = adapters,
  })
  
  return true
end

return M
