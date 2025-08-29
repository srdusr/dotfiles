local conditions = require('heirline.conditions')
local utils = require('heirline.utils')

local colors = {
  --bg = "#23232e",
  bg = nil,
  nobg = 'NONE',
  white = '#f8f8f2',
  black = '#000000',
  darkgray = '#23232e',
  gray = '#2d2b3a',
  lightgray = '#d6d3ea',
  pink = '#f92672',
  green = '#50fa7b',
  blue = '#39BAE6',
  yellow = '#f1fa8c',
  orange = '#ffb86c',
  purple = '#BF40BF',
  violet = '#7F00FF',
  red = '#ff5555',
  cyan = '#66d9eC',
  diag = {
    warn = utils.get_highlight('DiagnosticSignWarn').fg,
    error = utils.get_highlight('DiagnosticSignError').fg,
    hint = utils.get_highlight('DiagnosticSignHint').fg,
    info = utils.get_highlight('DiagnosticSignInfo').fg,
  },
  git = {
    active = '#f34f29',
    del = '#ff5555',
    add = '#50fa7b',
    change = '#ae81ff',
  },
}

require('heirline').load_colors(colors)

local Align = { provider = '%=', hl = { bg = colors.bg } }
local Space = { provider = ' ', hl = { bg = colors.bg } }
local Tab = { provider = ' ' }
local LeftSpace = { provider = '' }
local RightSpace = { provider = '' }

local ViMode = {
  init = function(self)
    self.mode = vim.fn.mode(1)
    --if not self.once then
    --  vim.cmd("au ModeChanged *:*o redrawstatus")
    --end
    --self.once = true
  end,
  static = {
    mode_names = {
      n = ' NORMAL ',
      no = 'PENDING ',
      nov = '   N?   ',
      noV = '   N?   ',
      ['no\22'] = '   N?   ',
      niI = '   Ni   ',
      niR = '   Nr   ',
      niV = '   Nv   ',
      nt = 'TERMINAL',
      v = ' VISUAL ',
      vs = '   Vs   ',
      V = ' V·LINE ',
      ['\22'] = 'V·BLOCK ',
      ['\22s'] = 'V·BLOCK ',
      s = ' SELECT ',
      S = ' S·LINE ',
      ['\19'] = 'S·BLOCK ',
      i = ' INSERT ',
      ix = 'insert x',
      ic = 'insert c',
      R = 'REPLACE ',
      Rc = '   Rc   ',
      Rx = '   Rx   ',
      Rv = 'V·REPLACE ',
      Rvc = '   Rv   ',
      Rvx = '   Rv   ',
      c = 'COMMAND ',
      cv = ' VIM EX ',
      ce = '   EX   ',
      r = ' PROMPT ',
      rm = '  MORE  ',
      ['r?'] = 'CONFIRM ',
      ['!'] = ' SHELL  ',
      t = 'TERMINAL',
    },
  },
  provider = function(self)
    return ' %2(' .. self.mode_names[self.mode] .. '%) '
  end,
  hl = function(self)
    return { fg = 'colors.black', bg = self.mode_color, bold = true }
  end,
  update = {
    'ModeChanged',
    'VimEnter',
    pattern = '*:*',
    callback = vim.schedule_wrap(function()
      vim.cmd('redrawstatus')
    end),
  },
}

-- LSP
local LSPActive = {
  condition = conditions.lsp_attached,
  update = { 'LspAttach', 'LspDetach' },
  provider = function()
    local buf_clients = vim.lsp.buf_get_clients()
    local buf_client_names = {}

    -- add client
    for _, client in pairs(buf_clients) do
      if client.name ~= 'null-ls' then
        table.insert(buf_client_names, client.name)
      end
    end
    return '⚙️ ' .. table.concat(buf_client_names, '')
  end,
  hl = { fg = colors.lightgray, bold = false },
}
local Navic = {
  condition = function()
    return require('nvim-navic').is_available()
  end,
  static = {
    -- create a type highlight map
    type_hl = {
      File = 'Directory',
      Module = '@include',
      Namespace = '@namespace',
      Package = '@include',
      Class = '@structure',
      Method = '@method',
      Property = '@property',
      Field = '@field',
      Constructor = '@constructor',
      Enum = '@field',
      Interface = '@type',
      Function = '@function',
      Variable = '@variable',
      Constant = '@constant',
      String = '@string',
      Number = '@number',
      Boolean = '@boolean',
      Array = '@field',
      Object = '@type',
      Key = '@keyword',
      Null = '@comment',
      EnumMember = '@field',
      Struct = '@structure',
      Event = '@keyword',
      Operator = '@operator',
      TypeParameter = '@type',
    },
    -- bit operation dark magic, see below...
    enc = function(line, col, winnr)
      return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
    end,
    -- line: 16 bit (65535); col: 10 bit (1023); winnr: 6 bit (63)
    dec = function(c)
      local line = bit.rshift(c, 16)
      local col = bit.band(bit.rshift(c, 6), 1023)
      local winnr = bit.band(c, 63)
      return line, col, winnr
    end,
  },
  init = function(self)
    local data = require('nvim-navic').get_data() or {}
    local children = {}
    -- create a child for each level
    for i, d in ipairs(data) do
      -- encode line and column numbers into a single integer
      local pos = self.enc(d.scope.start.line, d.scope.start.character, self.winnr)
      local child = {
        {
          provider = d.icon,
          hl = self.type_hl[d.type],
        },
        {
          -- escape `%`s (elixir) and buggy default separators
          provider = d.name:gsub('%%', '%%%%'):gsub('%s*->%s*', ''),
          -- highlight icon only or location name as well
          -- hl = self.type_hl[d.type],

          on_click = {
            -- pass the encoded position through minwid
            minwid = pos,
            callback = function(_, minwid)
              -- decode
              local line, col, winnr = self.dec(minwid)
              vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), { line, col })
            end,
            name = 'heirline_navic',
          },
        },
      }
      -- add a separator only if needed
      if #data > 1 and i < #data then
        table.insert(child, {
          provider = ' > ',
          hl = { fg = 'bright_fg' },
        })
      end
      table.insert(children, child)
    end
    -- instantiate the new child, overwriting the previous one
    self.child = self:new(children, 1)
  end,
  -- evaluate the children containing navic components
  provider = function(self)
    return self.child:eval()
  end,
  hl = { fg = 'gray' },
  update = 'CursorMoved',
}

-- Diagnostics
local Diagnostics = {
  condition = conditions.has_diagnostics,
  static = {
    error_icon = vim.fn.sign_getdefined('DiagnosticSignError')[1].text,
    warn_icon = vim.fn.sign_getdefined('DiagnosticSignWarn')[1].text,
    info_icon = vim.fn.sign_getdefined('DiagnosticSignInfo')[1].text,
    hint_icon = vim.fn.sign_getdefined('DiagnosticSignHint')[1].text,
  },
  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,
  update = { 'DiagnosticChanged', 'BufEnter' },
  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.errors > 0 and (self.error_icon .. self.errors .. ' ')
    end,
    hl = { fg = colors.diag.error, bg = colors.bg },
  },
  {
    provider = function(self)
      return self.warnings > 0 and (self.warn_icon .. self.warnings .. ' ')
    end,
    hl = { fg = colors.diag.warn, bg = colors.bg },
  },
  {
    provider = function(self)
      return self.info > 0 and (self.info_icon .. self.info .. ' ')
    end,
    hl = { fg = colors.diag.info, bg = colors.bg },
  },
  {
    provider = function(self)
      return self.hints > 0 and (self.hint_icon .. self.hints)
    end,
    hl = { fg = colors.diag.hint, bg = colors.bg },
  },
  on_click = {
    callback = function()
      require('trouble').toggle({ mode = 'document_diagnostics' })
      -- or
      -- vim.diagnostic.setqflist()
    end,
    name = 'heirline_diagnostics',
  },
}

-- Git
-- For the ones who're not (too) afraid of changes! Uses gitsigns.
local Git = {
  condition = conditions.is_git_repo,
  init = function(self)
    self.status_dict = vim.b.gitsigns_status_dict
    self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
  end,
  --{
  --  -- git branch name
  --  provider = function(self)
  --    --return ' ' .. self.status_dict.head
  --    return '   ' .. self.status_dict.head
  --  end,
  --  --hl = { bold = true },
  --  hl = { fg = colors.git.active, bold = true, bg = colors.bg },
  --},
  -- You could handle delimiters, icons and counts similar to Diagnostics
  {
    -- git branch icon
    provider = function()
      return '  '
    end,
    hl = { fg = colors.git.active, bg = colors.bg },
  },

  {
    -- git branch name
    provider = function(self)
      return self.status_dict.head
    end,
    hl = { fg = colors.white, bg = colors.bg },
  },

  {
    condition = function(self)
      return self.has_changes
    end,
    --provider = "("
    provider = '',
  },
  {
    provider = function(self)
      local count = self.status_dict.added or 0
      --return count > 0 and ("+" .. count)
      return count > 0 and ('  ' .. count)
    end,
    --hl = { fg = "git_add" },
    hl = { fg = colors.git.add, bg = colors.bg },
  },
  {
    provider = function(self)
      local count = self.status_dict.removed or 0
      --return count > 0 and ("-" .. count)
      return count > 0 and ('  ' .. count)
    end,
    --hl = { fg = "git_del" },
    hl = { fg = colors.git.del, bg = colors.bg },
  },
  {
    provider = function(self)
      local count = self.status_dict.changed or 0
      --return count > 0 and ("~" .. count)
      return count > 0 and ('  ' .. count)
    end,
    --hl = { fg = "git_change" },
    hl = { fg = colors.git.change, bg = colors.bg },
  },
  --{
  --    condition = function(self)
  --        return self.has_changes
  --    end,
  --    provider = ")",
  --},
  on_click = {
    callback = function()
      -- If you want to use Fugitive:
      -- vim.cmd("G")

      -- If you prefer Lazygit
      -- use vim.defer_fn() if the callback requires
      -- opening of a floating window
      -- (this also applies to telescope)
      vim.defer_fn(function()
        vim.cmd('Lazygit')
      end, 100)
    end,
    name = 'heirline_git',
  },
}

-- Debugger
-- Display informations from nvim-dap!
-- Note that we add spaces separately, so that only the icon characters will be clickable
--local DAPMessages = {
--  condition = function()
--    local session = require("dap").session()
--    return session ~= nil
--  end,
--  provider = function()
--    return " " .. require("dap").status() .. " "
--  end,
--  hl = "Debug",
--  {
--    provider = "",
--    on_click = {
--      callback = function()
--        require("dap").step_into()
--      end,
--      name = "heirline_dap_step_into",
--    },
--  },
--  { provider = " " },
--  {
--    provider = "",
--    on_click = {
--      callback = function()
--        require("dap").step_out()
--      end,
--      name = "heirline_dap_step_out",
--    },
--  },
--  { provider = " " },
--  {
--    provider = " ",
--    on_click = {
--      callback = function()
--        require("dap").step_over()
--      end,
--      name = "heirline_dap_step_over",
--    },
--  },
--  { provider = " " },
--  {
--    provider = "ﰇ",
--    on_click = {
--      callback = function()
--        require("dap").run_last()
--      end,
--      name = "heirline_dap_run_last",
--    },
--  },
--  { provider = " " },
--  {
--    provider = "",
--    on_click = {
--      callback = function()
--        require("dap").terminate()
--        require("dapui").close({})
--      end,
--      name = "heirline_dap_close",
--    },
--  },
--  { provider = " " },
--  -- icons:       ﰇ  
--}

-- Tests
-- This requires the great ultest.
--local UltTest = {
--    condition = function()
--        return vim .api.nvim_call_function("ultest#is_test_file", {}) ~= 0
--    end,
--    static = {
--        passed_icon = vim.fn.sign_getdefined("test_pass")[1].text,
--        failed_icon = vim.fn.sign_getdefined("test_fail")[1].text,
--        passed_hl = { fg = utils.get_highlight("UltestPass").fg },
--        failed_hl = { fg = utils.get_highlight("UltestFail").fg },
--    },
--    init = function(self)
--        self.status = vim.api.nvim_call_function("ultest#status", {})
--    end,
--
--    -- again, if you'd like icons and numbers to be colored differently,
--    -- just split the component in two
--    {
--        provider = function(self)
--            return self.passed_icon .. self.status.passed .. " "
--        end,
--        hl = function(self)
--            return self.passed_hl
--        end,
--    },
--    {
--        provider = function(self)
--            return self.failed_icon .. self.status.failed .. " "
--        end,
--        hl = function(self)
--            return self.failed_hl
--        end,
--    },
--    {
--        provider = function(self)
--            return "of " .. self.status.tests - 1
--        end,
--    },
--}

-- FileNameBlock: FileIcon, FileName and friends
local FileNameBlock = {
  -- let's first set up some attributes needed by this component and it's children
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
  end,
  --hl = { fg = utils.get_highlight("Statusline").fg, bold = true, bg = colors.bg },
  hl = { bg = colors.bg },
}

-- FileIcon, FileName, FileFlags and FileNameModifier
local FileIcon = {
  init = function(self)
    local filename = self.filename
    local extension = vim.fn.fnamemodify(filename, ':e')
    self.icon, self.icon_color = require('nvim-web-devicons').get_icon_color(filename, extension, { default = true })
  end,
  provider = function(self)
    return self.icon and (self.icon .. ' ')
  end,
  hl = function(self)
    return { fg = self.icon_color, bg = colors.bg }
  end,
}

local FileName = {
  provider = function(self)
    -- first, trim the pattern relative to the current directory. For other
    -- options, see :h filename-modifers
    local filename = vim.fn.fnamemodify(self.filename, ':.')
    if filename == '' then
      return 'No Name'
    end
    -- now, if the filename would occupy more than 1/4th of the available
    -- space, we trim the file path to its initials
    -- See Flexible Components section below for dynamic truncation
    if not conditions.width_percent_below(#filename, 0.25) then
      filename = vim.fn.pathshorten(filename)
    end
    return filename
  end,
  --hl = { fg = utils.get_highlight("Statusline").fg, bold = false, bg = colors.bg },
  hl = { fg = colors.white, bold = false, bg = colors.bg },
}

local FileFlags = {
  {
    provider = function()
      if vim.bo.modified then
        return ' [+]' -- ±[+]
      end
    end,
    hl = { fg = colors.green, bg = colors.bg },
  },
  {
    provider = function()
      if not vim.bo.modifiable or vim.bo.readonly then
        return ' '
      end
    end,
    --hl = { fg = colors.orange },
    hl = { fg = colors.orange, bold = true, bg = colors.bg },
  },
}

local FileNameModifier = {
  hl = function()
    if vim.bo.modified then
      return { fg = colors.green, bold = false, force = true }
    end
  end,
}

-- FileType, FileEncoding and FileFormat
local FileType = {
  provider = function()
    return vim.bo.filetype
  end,
  hl = { fg = colors.white, bold = false, bg = colors.bg },
}

local FileEncoding = {
  Space,
  provider = function()
    local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
    return enc:lower()
  end,
  --hl = { fg = utils.get_highlight("Statusline").fg, bold = true, bg = colors.bg },
  hl = { bg = colors.bg, bold = false },
}

local FileFormat = {
  provider = function()
    local fmt = vim.bo.fileformat
    --return fmt ~= "unix" and fmt:upper()
    return fmt ~= 'unix' and fmt:lower()
  end,
  hl = { fg = utils.get_highlight('Statusline').fg, bold = true, bg = colors.bg },
}

-- FileSize and FileLastModified
local FileSize = {
  provider = function()
    -- stackoverflow, compute human readable file size
    local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
    local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
    fsize = (fsize < 0 and 0) or fsize
    if fsize < 1024 then
      return fsize .. suffix[1]
    end
    local i = math.floor((math.log(fsize) / math.log(1024)))
    return string.format('%.2g%s', fsize / math.pow(1024, i), suffix[i + 1])
  end,
  hl = { fg = utils.get_highlight('Statusline').fg, bold = true, bg = colors.bg },
}

local FileLastModified = {
  -- did you know? Vim is full of functions!
  provider = function()
    local ftime = vim.fn.getftime(vim.api.nvim_buf_get_name(0))
    return (ftime > 0) and os.date('%c', ftime)
  end,
  hl = { fg = utils.get_highlight('Statusline').fg, bold = true, bg = colors.bg },
}

-- Spell
-- Add indicator when spell is set!
local Spell = {
  condition = function()
    return vim.wo.spell
  end,
  provider = ' 暈',
  hl = { bold = true, fg = colors.yellow },
}

local HelpFileName = {
  condition = function()
    return vim.bo.filetype == 'help'
  end,
  provider = function()
    local filename = vim.api.nvim_buf_get_name(0)
    return vim.fn.fnamemodify(filename, ':t')
  end,
  hl = { fg = colors.blue },
}

local SearchCount = {
  condition = function()
    return vim.v.hlsearch ~= 0 and vim.o.cmdheight == 0
  end,
  init = function(self)
    local ok, search = pcall(vim.fn.searchcount)
    if ok and search.total then
      self.search = search
    end
  end,
  provider = function(self)
    local search = self.search
    return string.format('[%d/%d]', search.current, math.min(search.total, search.maxcount))
  end,
}

local MacroRec = {
  condition = function()
    return vim.fn.reg_recording() ~= '' and vim.o.cmdheight == 0
  end,
  provider = ' ',
  hl = { fg = 'orange', bold = true },
  utils.surround({ '[', ']' }, nil, {
    provider = function()
      return vim.fn.reg_recording()
    end,
    hl = { fg = 'green', bold = true },
  }),
  update = {
    'RecordingEnter',
    'RecordingLeave',
  },
}

local ShowCmd = {
  condition = function()
    return vim.o.cmdheight == 0
  end,
  provider = ':%3.5(%S%)',
}

local cursor_location = {
  { provider = '%1(%4l:%-3(%c%)%) %*', hl = { fg = colors.black, bold = true } },
}

local Ruler = { cursor_location }

--utils.make_flexible_component(
--	3,
--	{ Ruler, hl = { fg = utils.get_highlight("statusline").bg, force = true } },
--	{ provider = "%<" }
--),
--local cursor_location = {
--	{ provider = "%7(%l:%c%) ", hl = { bold = true } },
--	{
--		provider = " ",
--		hl = function(self)
--			local color = self:mode_color()
--			return { fg = color, bold = true }
--		end,
--	},
--}

local WordCount = {
  condition = function()
    return conditions.buffer_matches({
      filetype = {
        'markdown',
        'txt',
        'vimwiki',
      },
    })
  end,
  Space,
  {
    provider = function()
      return 'W:' .. vim.fn.wordcount().words
    end,
  },
}

-- Working Directory
local WorkDir = {
  init = function(self)
    self.icon = (vim.fn.haslocaldir(0) == 1 and 'l' or 'g') .. ' ' .. ' '
    local cwd = vim.fn.getcwd(0)
    self.cwd = vim.fn.fnamemodify(cwd, ':~')
  end,
  hl = { fg = 'colors.blue', bold = true },
  flexible = 1,
  {
    -- evaluates to the full-lenth path
    provider = function(self)
      local trail = self.cwd:sub(-1) == '/' and '' or '/'
      return self.icon .. self.cwd .. trail .. ' '
    end,
  },
  {
    -- evaluates to the shortened path
    provider = function(self)
      local cwd = vim.fn.pathshorten(self.cwd)
      local trail = self.cwd:sub(-1) == '/' and '' or '/'
      return self.icon .. cwd .. trail .. ' '
    end,
  },
  {
    -- evaluates to "", hiding the component
    provider = '',
  },
}

-- Snippets Indicator
-- This requires ultisnips
--local Snippets = {
--    -- check that we are in insert or select mode
--    condition = function()
--        return vim.tbl_contains({'s', 'i'}, vim.fn.mode())
--    end,
--    provider = function()
--        local forward = (vim.fn["UltiSnips#CanJumpForwards"]() == 1) and "" or ""
--        local backward = (vim.fn["UltiSnips#CanJumpBackwards"]() == 1) and " " or ""
--        return backward .. forward
--    end,
--    hl = { fg = "red", bold = true },
--}

-- let's add the children to our FileNameBlock component
FileNameBlock = utils.insert(
  FileNameBlock,
  FileIcon,
  utils.insert(FileNameModifier, FileName), -- a new table where FileName is a child of FileNameModifier
  unpack(FileFlags),                        -- A small optimisation, since their parent does nothing
  { provider = '%<' }                       -- this means that the statusline is cut here when there's not enough space
)

local FileInfoBlock = {
  -- let's first set up some attributes needed by this component and it's children
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
  end,
}

FileInfoBlock = utils.insert(
  FileInfoBlock,
  Space,
  FileIcon,
  FileType,
  { provider = '%<' } -- this means that the statusline is cut here when there's not enough space
)

LeftSpace = utils.surround({ '', '' }, function(self)
  return self:mode_color()
end, { LeftSpace, hl = { fg = utils.get_highlight('statusline').bg, force = true } })

RightSpace = utils.surround({ '', '' }, function(self)
  return self:mode_color()
end, { RightSpace, hl = { fg = utils.get_highlight('statusline').bg, force = true } })

LSPActive = utils.surround({ '', '' }, function(self)
  return self:mode_color()
end, { Space, LSPActive, hl = { bg = colors.darkgray, force = true } })

FileInfoBlock = utils.surround({ '', '' }, function(self)
  return self:mode_color()
end, { FileInfoBlock, Space, hl = { bg = colors.black, force = true } })

ViMode = utils.surround({ '', '' }, function(self)
  return self:mode_color()
end, { ViMode, hl = { fg = colors.black, force = true } })

Ruler = utils.surround({ '', '' }, function(self)
  return self:mode_color()
end, { Ruler, hl = { fg = colors.black, force = true } })

local left = {
  { RightSpace,    hl = { bg = colors.nobg, force = true } },
  { ViMode,        hl = { bg = utils.get_highlight('statusline').bg, bold = false } },
  { LeftSpace,     hl = { bg = colors.nobg, force = true } },
  { Space,         hl = { bg = colors.nobg, force = true } },
  { FileNameBlock, hl = { bg = colors.nobg, force = true } },
  { Space,         hl = { bg = colors.nobg, force = true } },
  { Git,           hl = { bg = colors.nobg, force = true } },
}

local middle = {
  { Align, hl = { bg = colors.nobg, force = true } },
  --{ Navic,       hl = { bg = colors.nobg, force = true } },
  --{ DAPMessages, hl = { bg = colors.nobg, force = true } },
  { Align, hl = { bg = colors.nobg, force = true } },
}

local right = {
  --{ Space,         hl = { bg = colors.nobg, force = true } },
  { Diagnostics,   hl = { bg = colors.nobg, force = true } },
  { Space,         hl = { bg = colors.nobg, force = true } },
  { LSPActive,     hl = { bg = colors.nobg, force = true } },
  { Space,         hl = { bg = colors.nobg, force = true } },
  { FileInfoBlock, hl = { bg = colors.nobg, force = true } },
  { RightSpace,    hl = { bg = colors.nobg, force = true } },
  { Ruler,         hl = { fg = utils.get_highlight('statusline').bg, bold = false } },
  { LeftSpace,     hl = { bg = colors.nobg, force = true } },
}

local sections = { left, middle, right }
local DefaultStatusline = { sections }

local specialleft = {
  { RightSpace, hl = { bg = colors.nobg, force = true } },
  { ViMode,     hl = { bg = utils.get_highlight('statusline').bg, bold = false } },
  { LeftSpace,  hl = { bg = colors.nobg, force = true } },
}

local specialmiddle = {
  { Align, hl = { bg = colors.nobg, force = true } },
  --{ DAPMessages, hl = { bg = colors.nobg, force = true } },
  { Align, hl = { bg = colors.nobg, force = true } },
}

local specialright = {
  { RightSpace, hl = { bg = colors.nobg, force = true } },
  { Ruler,      hl = { fg = utils.get_highlight('statusline').bg, bold = false } },
  { LeftSpace,  hl = { bg = colors.nobg, force = true } },
}

local specialsections = { specialleft, specialmiddle, specialright }

local InactiveStatusline = {
  condition = conditions.is_not_active,
  --{ FileNameBlock, hl = { bg = colors.nobg, force = true } },
  --{ Align,         hl = { bg = colors.nobg, force = true } },
  specialsections,
}

local SpecialStatusline = {
  condition = function()
    return conditions.buffer_matches({
      buftype = { 'nofile', 'prompt', 'help', 'quickfix' },
      filetype = { '^git.*', 'fugitive', 'dashboard' },
    })
  end,
  specialsections,
}

--local InactiveStatusline = SpecialStatusline

local TerminalStatusline = {
  condition = function()
    return conditions.buffer_matches({ buftype = { 'terminal' } })
  end,
  specialsections,
}

local StatusLine = {
  static = {
    --mode_colors = {
    --  n = colors.blue,
    --  i = colors.green,
    --  v = colors.purple,
    --  V = colors.purple,
    --  ["\22"] = colors.purple,
    --  c = colors.orange,
    --  s = colors.purple,
    --  S = colors.purple,
    --  ["\19"] = colors.purple,
    --  R = colors.red,
    --  r = colors.red,
    --  ["!"] = colors.orange,
    --  t = colors.orange,
    --},
    mode_colors = {
      n = colors.blue,
      no = colors.blue,
      nov = colors.blue,
      noV = colors.blue,
      ['no\22'] = colors.blue,
      niI = colors.blue,
      niR = colors.blue,
      niV = colors.blue,
      nt = colors.blue,
      v = colors.purple,
      vs = colors.purple,
      V = colors.purple,
      ['\22'] = colors.purple,
      ['\22s'] = colors.purple,
      s = colors.purple,
      S = colors.purple,
      ['\19'] = colors.purple,
      i = colors.green,
      ix = colors.green,
      ic = colors.green,
      R = colors.red,
      Rc = colors.red,
      Rx = colors.red,
      Rv = colors.red,
      Rvc = colors.red,
      Rvx = colors.red,
      c = colors.orange,
      cv = colors.orange,
      ce = colors.orange,
      r = colors.red,
      rm = colors.red,
      ['r?'] = colors.red,
      ['!'] = colors.orange,
      t = colors.orange,
    },
    mode_color = function(self)
      local mode = conditions.is_active() and vim.fn.mode() or 'n'
      return self.mode_colors[mode]
    end,
    hl = function(self)
      local color = self:mode_color() -- here!
      return { bg = color }
    end,
  },
  fallthrough = false,
  SpecialStatusline,
  TerminalStatusline,
  InactiveStatusline,
  DefaultStatusline,
}

--
--- WinBar
--
local WinbarFileNameBlock = {
  -- let's first set up some attributes needed by this component and it's children
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
  end,
  hl = { bg = colors.bg },
}

local WinbarFileName = {
  provider = function(self)
    -- first, trim the pattern relative to the current directory. For other
    -- options, see :h filename-modifers
    local filename = vim.fn.fnamemodify(self.filename, ':.')
    if filename == '' then
      return 'No Name'
    end
    -- now, if the filename would occupy more than 1/4th of the available
    -- space, we trim the file path to its initials
    -- See Flexible Components section below for dynamic truncation
    if not conditions.width_percent_below(#filename, 0.25) then
      filename = vim.fn.pathshorten(filename)
    end
    return filename
  end,
  --hl = { fg = utils.get_highlight("Statusline").fg, bold = false, bg = colors.bg },
  hl = { fg = colors.gray, bold = false, bg = colors.bg },
}

WinbarFileNameBlock = utils.insert(
  WinbarFileNameBlock,
  FileIcon,
  utils.insert(WinbarFileName), -- a new table where FileName is a child of FileNameModifier
  unpack(FileFlags),            -- A small optimisation, since their parent does nothing
  { provider = '%<' }           -- this means that the statusline is cut here when there's not enough space
)

vim.api.nvim_create_autocmd('User', {
  pattern = 'HeirlineInitWinbar',
  callback = function(args)
    local buf = args.buf
    local buftype = vim.tbl_contains({ 'prompt', 'nofile', 'help', 'quickfix' }, vim.bo[buf].buftype)
    local filetype = vim.tbl_contains({ 'gitcommit', 'fugitive' }, vim.bo[buf].filetype)
    if buftype or filetype then
      vim.opt_local.winbar = nil
    end
  end,
})

On_click = {
  -- get the window id of the window in which the component was evaluated
  minwid = function()
    return vim.api.nvim_get_current_win()
  end,
  callback = function(_, minwid)
    -- winid is the window id of the window the component was clicked from
    local winid = minwid
    -- do something with the window id, e.g.:
    local buf = vim.api.nvim_win_get_buf(winid)
    -- ...
  end,
}

local CloseButton = {
  condition = function(self)
    return not vim.bo.modified
  end,
  -- a small performance improvement:
  -- re register the component callback only on layout/buffer changes.
  update = { 'WinNew', 'WinClosed', 'BufEnter' },
  { provider = ' ' },
  {
    provider = '',
    hl = { fg = 'gray' },
    On_click = {
      minwid = function()
        return vim.api.nvim_get_current_win()
      end,
      callback = function(_, minwid)
        vim.api.nvim_win_close(minwid, true)
      end,
      name = 'heirline_winbar_close_button',
    },
  },
}

local Center = {
  fallthrough = false,
  {
    -- Hide the winbar for special buffers
    condition = function()
      return conditions.buffer_matches({
        buftype = { 'terminal', 'nofile', 'prompt', 'help', 'quickfix' },
        filetype = { 'dap-ui', 'NvimTree', '^git.*', 'fugitive', 'dashboard' },
      })
    end,
    init = function()
      vim.opt_local.winbar = nil
    end,
  },
  {
    -- A special winbar for terminals
    condition = function()
      return conditions.buffer_matches({ buftype = { 'terminal' } })
    end,
    FileType,
    Space,
    --TerminalName,
  },
  {
    -- An inactive winbar for regular files
    condition = function()
      return not conditions.is_active()
    end,
    --utils.surround({ "", "" }, colors.nobg, { FileIcon, { WinbarFileName, hl = { fg = colors.gray } }, FileFlags } ),
    utils.surround({ '', '' }, colors.nobg, { WinbarFileNameBlock }),
  },
  -- A winbar for regular files
  utils.surround({ '', '' }, colors.nobg, { FileNameBlock }),
}

--local WinBar = { Align, Center, Align }
local WinBar = { Space, Center }

-- TabLine
--local TablineBufnr = {
--	provider = function(self)
--		return tostring(self.bufnr) .. "."
--	end,
--	hl = { fg = colors.white, bold = false },
----	hl = "Comment",
--}

-- we redefine the filename component, as we probably only want the tail and not the relative path
local TablineFileName = {
  provider = function(self)
    -- self.filename will be defined later, just keep looking at the example!
    local filename = self.filename
    filename = filename == '' and 'No Name' or vim.fn.fnamemodify(filename, ':t')
    return filename
  end,
  hl = function(self)
    return { fg = colors.white, bold = self.is_active or self.is_visible, italic = true }
  end,
}

local TablineFileFlags = {
  {
    provider = function(self)
      if vim.bo[self.bufnr].modified then
        return ' [+] '
      end
    end,
    hl = { fg = colors.green },
  },
  {
    provider = function(self)
      if not vim.bo[self.bufnr].modifiable or vim.bo[self.bufnr].readonly then
        return '  '
      end
    end,
    hl = { fg = 'orange' },
  },
}

local TablineFileIcon = {
  init = function(self)
    local filename = self.filename
    local extension = vim.fn.fnamemodify(filename, ':e')
    self.icon, self.icon_color = require('nvim-web-devicons').get_icon_color(filename, extension, { default = true })
  end,
  provider = function(self)
    return self.icon and (' ' .. self.icon .. ' ')
  end,
  hl = function(self)
    return { fg = self.icon_color }
  end,
}

-- Here the filename block finally comes together
local TablineFileNameBlock = {
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(self.bufnr)
  end,
  hl = function(self)
    if self.is_active then
      return 'TabLineSel'
      -- why not?
      --elseif not vim.api.nvim_buf_is_loaded(self.bufnr) then
      --return { fg = "gray", bg = colors.bg }
    else
      return 'TabLineFill'
    end
  end,
  on_click = {
    callback = function(_, minwid, _, button)
      if button == 'm' then -- close on mouse middle click
        vim.api.nvim_buf_delete(minwid, { force = false })
      else
        vim.api.nvim_win_set_buf(0, minwid)
      end
    end,
    minwid = function(self)
      return self.bufnr
    end,
    name = 'heirline_tabline_buffer_callback',
  },
  --TablineBufnr,
  TablineFileIcon,
  TablineFileName,
  TablineFileFlags,
}

-- a nice "x" button to close the buffer
local TablineCloseButton = {
  condition = function(self)
    return not vim.api.nvim_buf_get_option(self.bufnr, 'modified')
  end,
  { provider = ' ' },
  {
    provider = ' ',
    --hl = { fg = "red", bg = colors.bg },
    hl = { fg = colors.red },
    on_click = {
      callback = function(_, minwid)
        vim.api.nvim_buf_delete(minwid, { force = false })
      end,
      minwid = function(self)
        return self.bufnr
      end,
      name = 'heirline_tabline_close_buffer_callback',
    },
  },
}

-- The final touch!
local TablineBufferBlock = utils.surround({ '', '' }, function(self)
  --local TablineBufferBlock = utils.surround({ "█", "█" }, function(self)
  if self.is_active then
    return utils.get_highlight('TabLineSel').bg
  else
    return utils.get_highlight('TabLineFill').bg
  end
end, { Tab, TablineFileNameBlock, TablineCloseButton })

local BufferLine = utils.make_buflist(
  TablineBufferBlock,
  { provider = ' ', hl = { fg = colors.white } }, -- left truncation, optional (defaults to "<")
  { provider = ' ', hl = { fg = colors.white } } -- right trunctation, also optional (defaults to ...... yep, ">")
-- by the way, open a lot of buffers and try clicking them ;)
)
-- TabList
local Tabpage = {
  provider = function(self)
    return '%' .. self.tabnr .. 'T ' .. self.tabnr .. ' %T'
  end,
  hl = function(self)
    if not self.is_active then
      return 'TabLineFill'
    else
      return 'TabLineSel'
    end
  end,
}

local TabpageClose = {
  provider = '%999X  %X',
  --hl = "TabLine",
  hl = { fg = colors.red, bg = colors.bg },
}

local TabPages = {
  -- only show this component if there's 2 or more tabpages
  condition = function()
    return #vim.api.nvim_list_tabpages() >= 2
  end,
  {
    provider = '%=',
  },
  utils.make_tablist(Tabpage),
  TabpageClose,
}

-- TabLineOffset
local TabLineOffset = {
  condition = function(self)
    local win = vim.api.nvim_tabpage_list_wins(0)[1]
    local bufnr = vim.api.nvim_win_get_buf(win)
    self.winid = win

    if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'NvimTree' then
      self.title = 'NvimTree'
      return true
    end
  end,
  provider = function(self)
    local title = self.title
    local width = vim.api.nvim_win_get_width(self.winid)
    local pad = math.ceil((width - #title) / 2)
    return string.rep(' ', pad) .. title .. string.rep(' ', pad)
  end,
  hl = { fg = colors.white, bg = '#333842', bold = true },

  --hl = function(self)
  --  if vim.api.nvim_get_current_win() == self.winid then
  --    return 'TablineSel'
  --  else
  --    return 'TablineFill'
  --  end
  --end,
}

local TabLine = {
  TabLineOffset,
  BufferLine,
  TabPages,
}

require('heirline').setup({
  statusline = StatusLine,
  winbar = WinBar,
  tabline = TabLine,
  --statuscolumn = StatusColumn
})

-- Yep, with heirline we're driving manual!
vim.o.showtabline = 2
vim.cmd([[au FileType * if index(['wipe', 'delete', 'unload'], &bufhidden) >= 0 | set nobuflisted | endif]])

local function get_bufs()
  return vim.tbl_filter(function(bufnr)
    return vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted
  end, vim.api.nvim_list_bufs())
end

local function goto_buf(index)
  local bufs = get_bufs()
  if index > #bufs then
    index = #bufs
  end
  vim.api.nvim_win_set_buf(0, bufs[index])
end

local function addKey(key, index)
  vim.keymap.set('', '<A-' .. key .. '>', function()
    goto_buf(index)
  end, { noremap = true, silent = true })
end

for i = 1, 9 do
  addKey(i, i)
end
addKey('0', 10)
