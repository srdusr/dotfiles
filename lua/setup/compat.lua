-- setup/compat.lua
-- Automatically patches deprecated APIs based on Neovim version

-- Version check helper
local function has_version(major, minor, patch)
  local v = vim.version()
  patch = patch or 0
  return v.major > major
    or (v.major == major and v.minor > minor)
    or (v.major == major and v.minor == minor and v.patch >= patch)
end

-- === GLOBAL PATCHES === --

-- Neovim 0.10+: vim.islist replaces deprecated vim.tbl_islist
if has_version(0, 10) then
  if vim.tbl_islist == nil then
    vim.tbl_islist = vim.islist
  end
end

-- Neovim 0.12+: vim.tbl_flatten removed → shim using vim.iter
if has_version(0, 12) then
  vim.tbl_flatten = function(t)
    return vim.iter(t):flatten():totable()
  end
end

-- === DEPRECATION SHIMS (0.13 / 1.0) === --

-- client.is_stopped → client:is_stopped()
if has_version(0, 13) then
  local mt = getmetatable(vim.lsp._client or {})
  if mt and mt.__index and mt.__index.is_stopped then
    mt.__index.is_stopped = function(client, ...)
      return client:is_stopped(...)
    end
  end
end

-- client.request → client:request()
if has_version(0, 13) then
  local mt = getmetatable(vim.lsp._client or {})
  if mt and mt.__index and mt.__index.request then
    mt.__index.request = function(client, ...)
      return client:request(...)
    end
  end
end

-- vim.validate{tbl} → vim.validate(tbl)
if has_version(1, 0) then
  if type(vim.validate) == "function" then
    local old_validate = vim.validate
    vim.validate = function(arg)
      -- Handle both forms for backward compatibility
      if type(arg) == "table" then
        return old_validate(arg)
      else
        return old_validate{ arg }
      end
    end
  end
end

-- Deprecated: vim.lsp.get_active_clients (moved in 0.11+)
if has_version(0, 11) then
  if vim.lsp.get_active_clients == nil then
    vim.lsp.get_active_clients = function(...)
      return vim.lsp.get_clients(...)
    end
  end
end

-- Deprecated: vim.diagnostic.setqflist / setloclist (moved in 0.11+)
if has_version(0, 11) then
  if vim.diagnostic.setqflist == nil then
    vim.diagnostic.setqflist = function(diags, opts)
      return vim.diagnostic.toqflist(diags, opts)
    end
  end
  if vim.diagnostic.setloclist == nil then
    vim.diagnostic.setloclist = function(diags, opts)
      return vim.diagnostic.toloclist(diags, opts)
    end
  end
end

-- Deprecated: vim.lsp.buf.formatting/formatting_sync (removed in 0.8+)
if has_version(0, 8) then
  if vim.lsp.buf.formatting == nil then
    vim.lsp.buf.formatting = function(opts)
      return vim.lsp.buf.format(opts)
    end
  end
  if vim.lsp.buf.formatting_sync == nil then
    vim.lsp.buf.formatting_sync = function(opts, timeout_ms)
      return vim.lsp.buf.format(vim.tbl_extend("force", opts or {}, { timeout_ms = timeout_ms }))
    end
  end
end

-- Return something to satisfy require()
return true
