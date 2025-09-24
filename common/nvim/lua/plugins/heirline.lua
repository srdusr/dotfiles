local M = {}

-- Safe require function to handle missing dependencies
local function safe_require(module)
  local ok, result = pcall(require, module)
  return ok and result or nil
end

-- These will be initialized in M.setup()
local heirline = nil
local conditions = {}
local utils = {}
local colors = {}

function M.setup()
  heirline = safe_require("heirline")
  if not heirline then
    return
  end

  -- Initialize conditions and utils after heirline is loaded
  conditions = require("heirline.conditions") or {}
  utils = require("heirline.utils") or {}


  -- Initialize colors after safe_fg is defined
  colors = {
    bg = "NONE",
    nobg = "NONE",
    white = "#f8f8f2",
    black = "#000000",
    darkgray = "#23232e",
    gray = "#2d2b3a",
    lightgray = "#d6d3ea",
    pink = "#f92672",
    green = "#50fa7b",
    blue = "#39BAE6",
    yellow = "#f1fa8c",
    orange = "#ffb86c",
    purple = "#BF40BF",
    violet = "#7F00FF",
    red = "#ff5555",
    cyan = "#66d9eC",
    --diag = {
    --  warn = safe_fg("DiagnosticSignWarn", "#ffb86c"),
    --  error = safe_fg("DiagnosticSignError", "#ff5555"),
    --  hint = safe_fg("DiagnosticSignHint", "#50fa7b"),
    --  info = safe_fg("DiagnosticSignInfo", "#66d9eC"),
    --},
    diag = {
      warn = utils.get_highlight("DiagnosticSignWarn").fg,
      error = utils.get_highlight("DiagnosticSignError").fg,
      hint = utils.get_highlight("DiagnosticSignHint").fg,
      info = utils.get_highlight("DiagnosticSignInfo").fg,
    },
    git = {
      active = "#f34f29",
      del = "#ff5555",
      add = "#50fa7b",
      change = "#ae81ff",
    },
  }

  -- Only load colors if heirline is available
  if heirline.load_colors then
    local ok, err = pcall(heirline.load_colors, colors)
    if not ok then
      vim.notify("Failed to load Heirline colors: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  local function get_icon(icon, fallback)
    -- Check if we have Nerd Fonts available
    local has_nerd_fonts = vim.g.statusline_has_nerd_fonts
    if has_nerd_fonts == nil then
      -- Cache the result to avoid repeated checks
      if vim.fn.has('unix') == 1 and vim.fn.executable('fc-list') == 1 then
        local handle = io.popen('fc-list | grep -i nerd')
        local result = handle:read('*a')
        handle:close()
        has_nerd_fonts = result ~= ""
      else
        -- On non-Unix systems or if fc-list isn't available, assume no Nerd Fonts
        has_nerd_fonts = false
      end
      vim.g.statusline_has_nerd_fonts = has_nerd_fonts
    end

    -- Return the appropriate string based on font availability
    local result = has_nerd_fonts and icon or (fallback or '')
    -- Trim any whitespace to prevent layout issues
    return vim.trim(result)
  end

  -- Define all components after colors and utils are initialized

  --local Signs = {
  --  Error = "✘",
  --  Warn  = "",
  --  Hint = "◉",
  --  Info = "",
  --}
  local Icons = {
    Signs = {
      Error = "✘",
      Warn  = "",
      Hint = "◉",
      Info = "",
      LSP = get_icon("⚙️", "LSP"),
    },
    ---- LSP/Debug
    Error = get_icon("✘", "E"),
    Warn  = get_icon("", "W"),
    Hint = get_icon("◉", "H"),--
    Info = get_icon("ℹ", "I"),
    --LSP = get_icon("⚙️", "LSP"),

    -- Diagnostic
    Diagnostic = {
      error = get_icon("✘", "E"),
      warn = get_icon("", "W"),
      hint = get_icon("", "H"),
      info = get_icon("ℹ", "I"),
    },


--local GitIcons = {
--  added    = "✚", -- plus in diff style
--  modified = "", -- nf-oct-diff_modified
--  removed  = "", -- nf-oct-diff_removed
--}
--added    = "", -- nf-oct-diff_added
--modified = "", -- nf-oct-diff_modified
--removed  = "", -- nf-oct-diff_removed
--local GitIcons = {
--  added    = "", -- nf-fa-plus_square
--  modified = "", -- nf-fa-file_text_o
--  removed  = "", -- nf-fa-minus_square
--}
    -- Git
    Git = {
      branch = get_icon(" ", "⎇  "),
      added = get_icon("+ ", "+"),
      removed = get_icon("- ", "-"),
      modified = get_icon("~ ", "~"),
      renamed = get_icon("", "r"),
      untracked = get_icon("", "?"),
      ignored = get_icon("", "."),
    },

    -- UI Elements
    UI = {
      left_separator = get_icon("", ""),
      right_separator = get_icon("", ""),
      thin_separator = get_icon("▏", "|"),
      ellipsis = get_icon("…", "..."),
      arrow_left = get_icon("◀", "<"),
      arrow_right = get_icon("▶", ">"),
      close = get_icon("✕", "x"),
      big_close = get_icon(" ", "x "),
      modified = get_icon(" + ", "*"),
      readonly = get_icon("", "RO"),
      lock = get_icon("", "[L]"),
      clock = get_icon("🕒", "[TIME]"),
      buffer = get_icon("", "[BUF]"),
      tab = get_icon("", "[TAB]"),
      search = get_icon("🔍", "[SEARCH]"),
      spell = get_icon("暈", "[SPELL]"),
      whitespace = get_icon("␣", "[WS]"),
      newline = get_icon("↵", "[NL]"),
      indent = get_icon("▏", "|"),
      fold = get_icon("", ">"),
      fold_open = get_icon("", "v"),
      fold_closed = get_icon("", ">"),
    },

    -- File types
    File = {
      default = get_icon("", "[F]"),
      directory = get_icon("", "[D]"),
      symlink = get_icon("", "[L]"),
      executable = get_icon("", "[X]"),
      image = get_icon("", "[IMG]"),
      archive = get_icon("", "[ARC]"),
      audio = get_icon("", "[AUD]"),
      video = get_icon("", "[VID]"),
      document = get_icon("", "[DOC]"),
      config = get_icon("", "[CFG]"),
      code = get_icon("", "[CODE]"),
      terminal = get_icon("", "[TERM]"),
    },

    -- File format indicators
    Format = {
      unix = get_icon("", "[UNIX]"),
      dos = get_icon("", "[DOS]"),
      mac = get_icon("", "[MAC]"),
    },

    -- Version control
    VCS = {
      branch = get_icon("", "[BR]"),
      git = get_icon("", "[GIT]"),
      github = get_icon("", "[GH]"),
      gitlab = get_icon("", "[GL]"),
      bitbucket = get_icon("", "[BB]"),
    },

    -- Programming languages
    Lang = {
      lua = get_icon("", "[LUA]"),
      python = get_icon("", "[PY]"),
      javascript = get_icon("", "[JS]"),
      typescript = get_icon("", "[TS]"),
      html = get_icon("", "[HTML]"),
      css = get_icon("", "[CSS]"),
      json = get_icon("", "[JSON]"),
      markdown = get_icon("", "[MD]"),
      docker = get_icon("", "[DKR]"),
      rust = get_icon("", "[RS]"),
      go = get_icon("", "[GO]"),
      java = get_icon("", "[JAVA]"),
      c = get_icon("", "[C]"),
      cpp = get_icon("", "[C++]"),
      ruby = get_icon("", "[RB]"),
      php = get_icon("", "[PHP]"),
      haskell = get_icon("", "[HS]"),
      scala = get_icon("", "[SCALA]"),
      elixir = get_icon("", "[EXS]"),
      clojure = get_icon("", "[CLJ]"),
    },

    -- UI Indicators
    Indicator = {
      error = get_icon("✘", "[E]"),
      warning = get_icon("⚠", "[W]"),
      info = get_icon("ℹ", "[I]"),
      hint = get_icon("", "[H]"),
      success = get_icon("✓", "[OK]"),
      question = get_icon("?", "[?]"),
      star = get_icon("★", "[*]"),
      heart = get_icon("❤", "<3"),
      lightning = get_icon("⚡", "[!]"),
      check = get_icon("✓", "[√]"),
      cross = get_icon("✗", "[x]"),
      plus = get_icon("+", "[+]"),
      recording = get_icon(" ", "q")
    },

    -- File operations
    FileOp = {
      new = get_icon("", "[NEW]"),
      save = get_icon("💾", "[SAVE]"),
      open = get_icon("📂", "[OPEN]"),
      close = get_icon("✕", "[X]"),
      undo = get_icon("↩", "[UNDO]"),
      redo = get_icon("↪", "[REDO]"),
      cut = get_icon("✂", "[CUT]"),
      copy = get_icon("⎘", "[COPY]"),
      paste = get_icon("📋", "[PASTE]"),
      search = get_icon("🔍", "[FIND]"),
      replace = get_icon("🔄", "[REPLACE]"),
    },

    -- Navigation
    Nav = {
      left = get_icon("←", "[<]"),
      right = get_icon("→", "[>]"),
      up = get_icon("↑", "[^]"),
      down = get_icon("↓", "[v]"),
      first = get_icon("⏮", "[<<]"),
      last = get_icon("⏭", "[>>]"),
      prev = get_icon("◀", "[<]"),
      next = get_icon("▶", "[>]"),
      back = get_icon("↩", "[B]"),
      forward = get_icon("↪", "[F]"),
    },

    -- Editor states
    State = {
      insert = get_icon("", "[INS]"),
      normal = get_icon("🚀", "[NOR]"),
      visual = get_icon("👁", "[VIS]"),
      replace = get_icon("🔄", "[REP]"),
      command = get_icon("", "[CMD]"),
      terminal = get_icon("", "[TERM]"),
      select = get_icon("🔍", "[SEL]"),
    },

    -- Common symbols
    Symbol = {
      dot = get_icon("•", "•"),
      bullet = get_icon("•", "•"),
      middle_dot = get_icon("·", "·"),
      ellipsis = get_icon("…", "..."),
      check = get_icon("✓", "[OK]"),
      cross = get_icon("✗", "[X]"),
      arrow_right = get_icon(" ", "->"),
      arrow_left = get_icon(" ", "<-"),
      double_arrow_right = get_icon("»", ">>"),
      double_arrow_left = get_icon("«", "<<"),
      chevron_right = get_icon("›", ">"),
      chevron_left = get_icon("‹", "<"),
    },

    -- Document symbols
    DocSymbol = {
      class = get_icon("", "[C]"),
      function_icon = get_icon("", "[F]"),
      method = get_icon("", "[M]"),
      property = get_icon("", "[P]"),
      field = get_icon("ﰠ", "[F]"),
      constructor = get_icon("", "[C]"),
      enum = get_icon("", "[E]"),
      interface = get_icon("", "[I]"),
      variable = get_icon("", "[V]"),
      constant = get_icon("", "[C]"),
      string = get_icon("", "[S]"),
      number = get_icon("", "[N]"),
      boolean = get_icon("◩", "[B]"),
      array = get_icon("", "[A]"),
      object = get_icon("⦿", "[O]"),
      key = get_icon("🔑", "[K]"),
      null = get_icon("NULL", "Ø"),
      enum_member = get_icon("", "[E]"),
      struct = get_icon("פּ", "[S]"),
      event = get_icon("", "[E]"),
      operator = get_icon("", "[O]"),
      type_parameter = get_icon("", "[T]"),
    },
  }
  local Align = { provider = "%=", hl = { bg = colors.bg } }
  local Space = { provider = " ", hl = { bg = colors.bg } }
  local Tab = { provider = " " }
  local LeftSpace = { provider = "" }
  local RightSpace = { provider = "" }

  local ViMode = {
    init = function(self)
      self.mode = vim.fn.mode(1)
      -- Store the initial mode
      self.prev_mode = self.mode

      -- Set up autocommand to force redraw on mode change
      vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*:*",
        callback = function()
          -- Only redraw if the mode actually changed
          local current_mode = vim.fn.mode(1)
          if current_mode ~= self.prev_mode then
            self.prev_mode = current_mode
            vim.schedule(function()
              vim.cmd("redrawstatus")
            end)
          end
        end,
      })
    end,
    static = {
      mode_names = {
        n = " NORMAL ",
        no = "PENDING ",
        nov = "   N?   ",
        noV = "   N?   ",
        ["no\22"] = "   N?   ",
        niI = "   Ni   ",
        niR = "   Nr   ",
        niV = "   Nv   ",
        nt = "TERMINAL",
        v = " VISUAL ",
        vs = "   Vs   ",
        V = " V·LINE ",
        ["\22"] = "V·BLOCK ",
        ["\22s"] = "V·BLOCK ",
        s = " SELECT ",
        S = " S·LINE ",
        ["\19"] = "S·BLOCK ",
        i = " INSERT ",
        ix = "insert x",
        ic = "insert c",
        R = "REPLACE ",
        Rc = "   Rc   ",
        Rx = "   Rx   ",
        Rv = "V·REPLACE ",
        Rvc = "   Rv   ",
        Rvx = "   Rv   ",
        c = "COMMAND ",
        cv = " VIM EX ",
        ce = "   EX   ",
        r = " PROMPT ",
        rm = "  MORE  ",
        ["r?"] = "CONFIRM ",
        ["!"] = " SHELL  ",
        t = "TERMINAL",
      },
    },
    provider = function(self)
      return " %2(" .. self.mode_names[self.mode] .. "%) "
    end,
    hl = function(self)
      return { fg = "colors.black", bg = self.mode_color, bold = true }
    end,
    update = {
      "ModeChanged",
      "VimEnter",
      "BufEnter",
      "WinEnter",
      "TabEnter",
      pattern = "*:*",
      callback = vim.schedule_wrap(function()
        vim.cmd("redrawstatus")
      end),
    },
  }

  -- LSP
  local LSPActive = {
    condition = function()
      local ok, _ = pcall(function()
        local buf = vim.api.nvim_get_current_buf()
        return #vim.lsp.get_clients({ bufnr = buf }) > 0
      end)
      return ok or false
    end,
    update = { "LspAttach", "LspDetach", "BufEnter" },
    provider = function()
      local ok, result = pcall(function()
        local buf = vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(buf) then return "" end

        local clients = vim.lsp.get_clients({ bufnr = buf })
        if not clients or #clients == 0 then return "" end

        local client_names = {}
        for _, client in ipairs(clients) do
          if client and client.name and client.name ~= "null-ls" then
            table.insert(client_names, client.name)
          end
        end

        if #client_names > 0 then
          return Icons.Signs.LSP .. " " .. table.concat(client_names, "/") .. " "
        end

        return ""
      end)

      if not ok then
        vim.schedule(function()
          vim.notify_once("Error in LSPActive provider: " .. tostring(result), vim.log.levels.DEBUG)
        end)
        return ""
      end

      return result or ""
    end,
    hl = { fg = "lightgray", bold = false },
  }

  local Navic = {
    condition = function()
      local ok, navic = pcall(require, "nvim-navic")
      return ok and navic.is_available()
    end,
    static = {
      type_hl = {
        File = "Directory",
        Module = "@include",
        Namespace = "@namespace",
        Package = "@include",
        Class = "@structure",
        Method = "@method",
        Property = "@property",
        Field = "@field",
        Constructor = "@constructor",
        Enum = "@field",
        Interface = "@type",
        Function = "@function",
        Variable = "@variable",
        Constant = "@constant",
        String = "@string",
        Number = "@number",
        Boolean = "@boolean",
        Array = "@field",
        Object = "@type",
        Key = "@keyword",
        Null = "@comment",
        EnumMember = "@field",
        Struct = "@structure",
        Event = "@keyword",
        Operator = "@operator",
        TypeParameter = "@type",
      },
      enc = function(line, col, winnr)
        return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
      end,
      dec = function(c)
        local line = bit.rshift(c, 16)
        local col = bit.band(bit.rshift(c, 6), 1023)
        local winnr = bit.band(c, 63)
        return line, col, winnr
      end,
    },
    init = function(self)
      local data = require("nvim-navic").get_data() or {}
      local children = {}
      for i, d in ipairs(data) do
        local pos = self.enc(d.scope.start.line, d.scope.start.character, self.winnr)
        local child = {
          {
            provider = d.icon,
            hl = self.type_hl[d.type],
          },
          {
            provider = d.name:gsub("%%", "%%%%"):gsub("%s*->%s*", ""),
            on_click = {
              minwid = pos,
              callback = function(_, minwid)
                local line, col, winnr = self.dec(minwid)
                vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), { line, col })
              end,
              name = "heirline_navic",
            },
          },
        }
        if #data > 1 and i < #data then
          table.insert(child, {
            provider = " > ",
            hl = { fg = "bright_fg" },
          })
        end
        table.insert(children, child)
      end
      self.child = self:new(children, 1)
    end,
    provider = function(self)
      return self.child:eval()
    end,
    hl = { fg = "gray" },
    update = "CursorMoved",
  }

  -- Diagnostics
  local Diagnostics = {
    condition = conditions.has_diagnostics,
    static = {
      error_icon = Icons.Error,
      warn_icon  = Icons.Warn,
      info_icon  = Icons.Info,
      hint_icon  = Icons.Hint,
    },
    init = function(self)
      self.errors   = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
      self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
      self.hints    = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
      self.info     = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,
    update = { "DiagnosticChanged", "BufEnter" },
    {
      provider = function(self)
        return self.errors > 0 and (self.error_icon .. " " .. self.errors .. " ")
      end,
      hl = { fg = colors.diag.error, bg = colors.bg },
    },
    {
      provider = function(self)
        return self.warnings > 0 and (self.warn_icon .. " " .. self.warnings .. " ")
      end,
      hl = { fg = colors.diag.warn, bg = colors.bg },
    },
    {
      provider = function(self)
        return self.info > 0 and (self.info_icon .. " " .. self.info .. " ")
      end,
      hl = { fg = colors.diag.info, bg = colors.bg },
    },
    {
      provider = function(self)
        return self.hints > 0 and (self.hint_icon .. " " .. self.hints .. " ")
      end,
      hl = { fg = colors.diag.hint, bg = colors.bg },
    },
    on_click = {
      callback = function()
        local ok, _ = pcall(require, "trouble")
        if ok then
          require("trouble").toggle({ mode = "document_diagnostics" })
        else
          vim.diagnostic.setqflist()
        end
      end,
      name = "heirline_diagnostics",
    },
  }

  -- Git
  local Git = {
    condition = conditions.is_git_repo,
    init = function(self)
      self.status_dict = vim.b.gitsigns_status_dict or {}
      self.has_changes = (self.status_dict.added or 0) ~= 0 or
                        (self.status_dict.removed or 0) ~= 0 or
                        (self.status_dict.changed or 0) ~= 0
    end,
    {
      provider = function()
        return " " .. Icons.Git.branch .. " "
      end,
      hl = { fg = colors.git.active, bg = colors.bg },
    },
    {
      provider = function(self)
        return self.status_dict.head or ""
      end,
      hl = { fg = colors.white, bg = colors.bg },
    },
    {
      condition = function(self)
        return self.has_changes
      end,
      provider = "",
    },
    {
      provider = function(self)
        local count = self.status_dict.added or 0
        return count > 0 and (" " .. Icons.Git.added .. count) or ""
      end,
      hl = { fg = colors.git.add, bg = colors.bg },
    },
    {
      provider = function(self)
        local count = self.status_dict.removed or 0
        return count > 0 and (" " .. Icons.Git.removed .. count) or ""
      end,
      hl = { fg = colors.git.del, bg = colors.bg },
    },
    {
      provider = function(self)
        local count = self.status_dict.changed or 0
        return count > 0 and (" " .. Icons.Git.modified .. count) or ""
      end,
      hl = { fg = colors.git.change, bg = colors.bg },
    },
    on_click = {
      callback = function()
        vim.defer_fn(function()
          vim.cmd("Lazygit")
        end, 100)
      end,
      name = "heirline_git",
    },
  }

  -- FileNameBlock: FileIcon, FileName and friends
  local FileNameBlock = {
    init = function(self)
      self.filename = vim.api.nvim_buf_get_name(0)
    end,
    hl = { bg = colors.bg },
  }

  local FileIcon = {
    init = function(self)
      local filename = self.filename or vim.api.nvim_buf_get_name(0)
      local extension = vim.fn.fnamemodify(filename, ":e")

      local has_nerd_fonts = vim.g.statusline_has_nerd_fonts
      if has_nerd_fonts == nil then
        if vim.fn.has('unix') == 1 and vim.fn.executable('fc-list') == 1 then
          local handle = io.popen('fc-list | grep -i nerd')
          local result = handle:read('*a')
          handle:close()
          has_nerd_fonts = result ~= ""
        else
          has_nerd_fonts = false
        end
        vim.g.statusline_has_nerd_fonts = has_nerd_fonts
      end

      local icon, icon_color
      if has_nerd_fonts then
        icon, icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
      end

      if vim.fn.isdirectory(filename) == 1 then
        self.icon = has_nerd_fonts and Icons.File.directory or "[DIR]"
        self.icon_color = colors.blue
      else
        if has_nerd_fonts and icon then
          self.icon = icon .. " "
          self.icon_color = icon_color or colors.blue
        else
          if extension == "" then
            self.icon = Icons.File.default
          else
            local file_icon = Icons.File[extension:lower()] or Icons.File.default
            if type(file_icon) == "table" then
              self.icon = file_icon[1] or Icons.File.default
            else
              self.icon = file_icon
            end
          end
          self.icon_color = colors.blue
        end
      end
    end,
    provider = function(self)
      return self.icon
    end,
    hl = function(self)
      return { fg = self.icon_color, bold = true }
    end,
  }

  local FileName = {
    provider = function(self)
      local filename = vim.fn.fnamemodify(self.filename, ":.")
      if filename == "" then
        return "No Name"
      end
      if not conditions.width_percent_below(#filename, 0.25) then
        filename = vim.fn.pathshorten(filename)
      end
      return filename
    end,
    hl = { fg = colors.white, bold = false, bg = colors.bg },
  }

  local FileFlags = {
    {
      provider = function()
        if vim.bo.modified then
          return " +"
        end
      end,
      hl = { fg = colors.green, bg = colors.bg },
    },
    {
      provider = function()
        if not vim.bo.modifiable or vim.bo.readonly then
          return " " .. Icons.UI.lock
        end
      end,
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
      local enc = (vim.bo.fenc ~= "" and vim.bo.fenc) or vim.o.enc
      return enc:lower()
    end,
    hl = { bg = colors.bg, bold = false },
  }

  local FileFormat = {
    provider = function()
      local fmt = vim.bo.fileformat
      return fmt ~= "unix" and fmt:lower() or ""
    end,
    hl = { fg = utils.get_highlight("Statusline").fg, bold = true, bg = colors.bg },
  }

  local FileSize = {
    provider = function()
      local suffix = { "b", "k", "M", "G", "T", "P", "E" }
      local filename = vim.api.nvim_buf_get_name(0)
      local fsize = vim.fn.getfsize(filename)
      fsize = (fsize < 0 and 0) or fsize
      if fsize < 1024 then
        return fsize .. suffix[1]
      end
      local i = math.floor((math.log(fsize) / math.log(1024)))
      return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i + 1])
    end,
    hl = { fg = utils.get_highlight("Statusline").fg, bold = true, bg = colors.bg },
  }

  local FileLastModified = {
    provider = function()
      local filename = vim.api.nvim_buf_get_name(0)
      local ftime = vim.fn.getftime(filename)
      return (ftime > 0) and os.date("%c", ftime) or ""
    end,
    hl = { fg = utils.get_highlight("Statusline").fg, bold = true, bg = colors.bg },
  }

  local Spell = {
    condition = function()
      return vim.wo.spell
    end,
    provider = function()
      return " " .. Icons.Indicator.spell .. " "
    end,
    hl = { bold = true, fg = colors.yellow },
  }

  local HelpFileName = {
    condition = function()
      return vim.bo.filetype == "help"
    end,
    provider = function()
      local filename = vim.api.nvim_buf_get_name(0)
      return vim.fn.fnamemodify(filename, ":t")
    end,
    hl = { fg = colors.blue },
  }

  local SearchCount = {
    condition = function()
      return vim.v.hlsearch ~= 0 and vim.o.cmdheight == 0
    end,
    init = function(self)
      local ok, search = pcall(vim.fn.searchcount, { recompute = 1, maxcount = -1 })
      if ok and search.total then
        self.search = search
      end
    end,
    provider = function(self)
      local search = self.search or { current = 0, total = 0, maxcount = 0 }
      return string.format("[%d/%d]", search.current, math.min(search.total, search.maxcount))
    end,
    update = { "CursorMoved", "CursorMovedI", "SearchWrapped" },
  }

  local MacroRec = {
    condition = function()
      return vim.fn.reg_recording() ~= "" and vim.o.cmdheight == 0
    end,
    provider = function()
      return Icons.Indicator.recording .. " "
    end,
    hl = { fg = "orange", bold = true },
    utils.surround({ "[", "]" }, nil, {
      provider = function()
        return vim.fn.reg_recording()
      end,
      hl = { fg = "green", bold = true },
    }),
    update = {
      "RecordingEnter",
      "RecordingLeave",
      callback = vim.schedule_wrap(function()
        vim.cmd("redrawstatus")
      end),
    },
  }

  local ShowCmd = {
    condition = function()
      return vim.o.cmdheight == 0
    end,
    provider = ":%3.5(%S%)",
    update = { "CmdlineChanged" },
  }

  local cursor_location = {
    { provider = "%1(%4l:%-3(%c%)%) %*", hl = { fg = colors.black, bold = true } },
  }

  local Ruler = { cursor_location }

  local WordCount = {
    condition = function()
      return conditions.buffer_matches({
        filetype = {
          "markdown",
          "txt",
          "vimwiki",
        },
      })
    end,
    Space,
    {
      provider = function()
        local ok, wordcount = pcall(vim.fn.wordcount)
        return ok and wordcount.words and ("W:%d"):format(wordcount.words) or ""
      end,
      update = { "CursorMoved", "CursorMovedI", "InsertEnter", "TextChanged", "TextChangedI" },
    },
  }

  local WorkDir = {
    init = function(self)
      local is_local = vim.fn.haslocaldir(0) == 1
      self.icon = (is_local and "l" or "g") .. " " .. Icons.File.directory
      local cwd = vim.fn.getcwd(0)
      self.cwd = vim.fn.fnamemodify(cwd, ":~")
    end,
    hl = { fg = colors.blue, bold = true },
    on_click = {
      callback = function()
        vim.cmd("Telescope find_files cwd=" .. vim.fn.getcwd(0))
      end,
      name = "heirline_workdir",
    },
    flexible = 1,
    {
      provider = function(self)
        local trail = self.cwd:sub(-1) == "/" and "" or "/"
        return self.icon .. " " .. self.cwd .. trail .. " "
      end,
    },
    {
      provider = function(self)
        local cwd = vim.fn.pathshorten(self.cwd)
        local trail = self.cwd:sub(-1) == "/" and "" or "/"
        return self.icon .. " " .. cwd .. trail .. " "
      end,
    },
    {
      provider = function(self)
        return self.icon .. " "
      end,
    },
  }

  -- Build FileNameBlock
  FileNameBlock = utils.insert(
    FileNameBlock,
    FileIcon,
    utils.insert(FileNameModifier, FileName),
    unpack(FileFlags),
    { provider = "%<" }
  )

  local FileInfoBlock = {
    init = function(self)
      self.filename = vim.api.nvim_buf_get_name(0)
    end,
  }

  FileInfoBlock = utils.insert(
    FileInfoBlock,
    Space,
    FileIcon,
    FileType,
    { provider = "%<" }
  )

  -- Create surrounded components with proper mode color functions
  LeftSpace = utils.surround({ "", Icons.UI.right_separator }, function(self)
    return self:mode_color()
  end, { LeftSpace, hl = { fg = utils.get_highlight("statusline").bg, force = true } })

  RightSpace = utils.surround({ Icons.UI.left_separator, "" }, function(self)
    return self:mode_color()
  end, { RightSpace, hl = { fg = utils.get_highlight("statusline").bg, force = true } })

  LSPActive = utils.surround({ "", "" }, function(self)
    return self:mode_color()
  end, { Space, LSPActive, hl = { bg = colors.darkgray, force = true } })

  FileInfoBlock = utils.surround({ "", "" }, function(self)
    return self:mode_color()
  end, { FileInfoBlock, Space, hl = { bg = colors.black, force = true } })

  ViMode = utils.surround({ "", "" }, function(self)
    return self:mode_color()
  end, { ViMode, hl = { fg = colors.black, force = true } })

  Ruler = utils.surround({ "", "" }, function(self)
    return self:mode_color()
  end, { Ruler, hl = { fg = colors.black, force = true } })

  -- Statusline sections - FIXED: Removed duplicate LeftSpace from right section
  local left = {
    { RightSpace,    hl = { bg = colors.nobg, force = true } },
    { ViMode,        hl = { bg = utils.get_highlight("statusline").bg, bold = false } },
    { LeftSpace,     hl = { bg = colors.nobg, force = true } },
    { Space,         hl = { bg = colors.nobg, force = true } },
    { FileNameBlock, hl = { bg = colors.nobg, force = true } },
    { Space,         hl = { bg = colors.nobg, force = true } },
    { Git,           hl = { bg = colors.nobg, force = true } },
  }

  local middle = {
    { Align, hl = { bg = colors.nobg, force = true } },
    { Align, hl = { bg = colors.nobg, force = true } },
  }

  -- FIXED: Right section now has proper sequence without duplicate LeftSpace
  local right = {
    { Diagnostics,   hl = { bg = colors.nobg, force = true } },
    { Space,         hl = { bg = colors.nobg, force = true } },
    { LSPActive,     hl = { bg = colors.nobg, force = true } },
    { Space,         hl = { bg = colors.nobg, force = true } },
    { FileInfoBlock, hl = { bg = colors.nobg, force = true } },
    { RightSpace,    hl = { bg = colors.nobg, force = true } },
    { Ruler,         hl = { fg = utils.get_highlight("statusline").bg, bold = false } },
    { LeftSpace,     hl = { bg = colors.nobg, force = true } },
  }

  local sections = { left, middle, right }
  local DefaultStatusline = { sections }

  -- Special statuslines for inactive/special buffers
  local specialleft = {
    { RightSpace, hl = { bg = colors.nobg, force = true } },
    { ViMode,     hl = { bg = utils.get_highlight("statusline").bg, bold = false } },
    { LeftSpace,  hl = { bg = colors.nobg, force = true } },
  }

  local specialmiddle = {
    { Align, hl = { bg = colors.nobg, force = true } },
    { Align, hl = { bg = colors.nobg, force = true } },
  }

  local specialright = {
    { RightSpace, hl = { bg = colors.nobg, force = true } },
    { Ruler,      hl = { fg = utils.get_highlight("statusline").bg, bold = false } },
    { LeftSpace,  hl = { bg = colors.nobg, force = true } },
  }

  local specialsections = { specialleft, specialmiddle, specialright }

  local InactiveStatusline = {
    condition = conditions.is_not_active,
    specialsections,
  }

  local SpecialStatusline = {
    condition = function()
      return conditions.buffer_matches({
        buftype = { "nofile", "prompt", "help", "quickfix" },
        filetype = { "^git.*", "fugitive", "dashboard" },
      })
    end,
    specialsections,
  }

  local TerminalStatusline = {
    condition = function()
      return conditions.buffer_matches({ buftype = { "terminal" } })
    end,
    specialsections,
  }

  -- FIXED: Main StatusLine with better mode handling
  local StatusLine = {
    static = {
      mode_colors = {
        n = colors.blue,
        no = colors.blue,
        nov = colors.blue,
        noV = colors.blue,
        ["no\22"] = colors.blue,
        niI = colors.blue,
        niR = colors.blue,
        niV = colors.blue,
        nt = colors.blue,
        v = colors.purple,
        vs = colors.purple,
        V = colors.purple,
        ["\22"] = colors.purple,
        ["\22s"] = colors.purple,
        s = colors.purple,
        S = colors.purple,
        ["\19"] = colors.purple,
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
        ["r?"] = colors.red,
        ["!"] = colors.orange,
        t = colors.orange,
      },
      mode_color = function(self)
        -- FIXED: Always get current mode to ensure updates
        local mode = vim.fn.mode()
        return self.mode_colors[mode] or colors.blue
      end,
    },
    -- FIXED: Add update triggers to ensure statusline refreshes properly
    update = {
      "ModeChanged",
      "BufEnter",
      "WinEnter",
      "WinLeave",
      "BufWinEnter",
      "CmdlineLeave",
      callback = vim.schedule_wrap(function()
        vim.cmd("redrawstatus")
      end),
    },
    fallthrough = false,
    SpecialStatusline,
    TerminalStatusline,
    InactiveStatusline,
    DefaultStatusline,
  }

  -- WinBar components
  local WinbarFileNameBlock = {
    init = function(self)
      self.filename = vim.api.nvim_buf_get_name(0)
    end,
    hl = { bg = colors.bg },
  }

  local WinbarFileName = {
    provider = function(self)
      local filename = vim.fn.fnamemodify(self.filename, ":.")
      if filename == "" then
        return "No Name"
      end
      if not conditions.width_percent_below(#filename, 0.25) then
        filename = vim.fn.pathshorten(filename)
      end
      return filename
    end,
    hl = { fg = colors.gray, bold = false, bg = colors.bg },
  }

  WinbarFileNameBlock = utils.insert(
    WinbarFileNameBlock,
    FileIcon,
    utils.insert(WinbarFileName),
    unpack(FileFlags),
    { provider = "%<" }
  )

  vim.api.nvim_create_autocmd("User", {
    pattern = "HeirlineInitWinbar",
    callback = function(args)
      local buf = args.buf
      local buftype = vim.tbl_contains({ "prompt", "nofile", "help", "quickfix" }, vim.bo[buf].buftype)
      local filetype = vim.tbl_contains({ "gitcommit", "fugitive" }, vim.bo[buf].filetype)
      if buftype or filetype then
        vim.opt_local.winbar = nil
      end
    end,
  })

  local On_click = {
    minwid = function()
      return vim.api.nvim_get_current_win()
    end,
    callback = function(_, minwid)
      local winid = minwid
      local buf = vim.api.nvim_win_get_buf(winid)
    end,
  }

  local CloseButton = {
    condition = function(self)
      return not vim.bo.modified
    end,
    update = { "WinNew", "WinClosed", "BufEnter" },
    { provider = " " },
    {
      provider = Icons.UI.close,
      hl = { fg = "gray" },
      On_click = {
        minwid = function()
          return vim.api.nvim_get_current_win()
        end,
        callback = function(_, minwid)
          vim.api.nvim_win_close(minwid, true)
        end,
        name = "heirline_winbar_close_button",
      },
    },
  }

  local Center = {
    fallthrough = false,
    {
      condition = function()
        return conditions.buffer_matches({
          buftype = { "terminal", "nofile", "prompt", "help", "quickfix" },
          filetype = { "dap-ui", "NvimTree", "^git.*", "fugitive", "dashboard" },
        })
      end,
      init = function()
        vim.opt_local.winbar = nil
      end,
    },
    {
      condition = function()
        return conditions.buffer_matches({ buftype = { "terminal" } })
      end,
      FileType,
      Space,
    },
    {
      condition = function()
        return not conditions.is_active()
      end,
      utils.surround({ "", "" }, colors.nobg, { WinbarFileNameBlock }),
    },
    utils.surround({ "", "" }, colors.nobg, { FileNameBlock }),
  }

  local WinBar = { Space, Center }

  -- Tabline components
  local TablineFileIcon = {
    init = function(self)
      local filename = self.filename
      local extension = vim.fn.fnamemodify(filename, ":e")

      local has_nerd_fonts = vim.g.statusline_has_nerd_fonts
      if has_nerd_fonts == nil then
        if vim.fn.has('unix') == 1 and vim.fn.executable('fc-list') == 1 then
          local handle = io.popen('fc-list | grep -i nerd')
          local result = handle:read('*a')
          handle:close()
          has_nerd_fonts = result ~= ""
        else
          has_nerd_fonts = false
        end
        vim.g.statusline_has_nerd_fonts = has_nerd_fonts
      end

      if has_nerd_fonts then
        self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
      else
        self.icon = ""
        self.icon_color = colors.blue

        if vim.fn.isdirectory(filename) == 1 then
          self.icon = "[DIR]"
        else
          local file_icon = Icons.File[extension:lower()] or Icons.File.default
          if type(file_icon) == "table" then
            self.icon = file_icon[1] or Icons.File.default
          else
            self.icon = file_icon
          end
        end
      end

      if self.icon ~= "" then
        self.icon = self.icon .. " "
      end
    end,
    provider = function(self)
      return self.icon or ""
    end,
    hl = function(self)
      return { fg = self.icon_color or colors.blue }
    end,
  }

  local TablineFileName = {
    provider = function(self)
      local filename = vim.fn.fnamemodify(self.filename, ":t")
      if filename == "" then
        return "[No Name]"
      end
      return filename
    end,
  }

  local TablineFileFlags = {
    {
      condition = function(self)
        return vim.api.nvim_buf_get_option(self.bufnr, "modified")
      end,
      provider = "%X " .. Icons.Indicator.plus .. " %X",
      hl = { fg = "green" },
    },
    {
      condition = function(self)
        return not vim.api.nvim_buf_get_option(self.bufnr, "modifiable") or vim.api.nvim_buf_get_option(self.bufnr, "readonly")
      end,
      provider = function()
        if vim.bo.readonly then
          return " " .. Icons.UI.lock
        end
        return ""
      end,
      hl = { fg = "orange" },
    },
  }

  local TablineFileNameBlock = {
    init = function(self)
      self.filename = vim.api.nvim_buf_get_name(self.bufnr)
    end,
    hl = function(self)
      if self.is_active then
        return "TabLineSel"
      else
        return "TabLineFill"
      end
    end,
    on_click = {
      callback = function(_, minwid, _, button)
        if button == "m" then
          vim.api.nvim_buf_delete(minwid, { force = false })
        else
          vim.api.nvim_win_set_buf(0, minwid)
        end
      end,
      minwid = function(self)
        return self.bufnr
      end,
      name = "heirline_tabline_buffer_callback",
    },
    TablineFileIcon,
    TablineFileName,
    TablineFileFlags,
  }

  local TablineCloseButton = {
    condition = function(self)
      return not vim.api.nvim_buf_get_option(self.bufnr, "modified")
    end,
    { provider = " " },
    {
      provider = "" .. Icons.UI.close .. " %X",
      hl = { fg = colors.red },
      on_click = {
        callback = function(_, minwid)
          vim.api.nvim_buf_delete(minwid, { force = false })
        end,
        minwid = function(self)
          return self.bufnr
        end,
        name = "heirline_tabline_close_buffer_callback",
      },
    },
  }

  local TablineBufferBlock = utils.surround({ "", "" }, function(self)
    if self.is_active then
      return utils.get_highlight("TabLineSel").bg
    else
      return utils.get_highlight("TabLineFill").bg
    end
  end, { Tab, TablineFileNameBlock, TablineCloseButton })

  local BufferLine = utils.make_buflist(
    TablineBufferBlock,
    { provider = Icons.Symbol.arrow_left, hl = { fg = colors.gray } },
    { provider = Icons.Symbol.arrow_right, hl = { fg = colors.gray } }
  )

  local Tabpage = {
    provider = function(self)
      return "%" .. self.tabnr .. "T " .. self.tabnr .. " %T"
    end,
    hl = function(self)
      return self.is_active and "TabLineSel" or "TabLineFill"
    end,
  }

  local TabpageClose = {
    provider = "%999X " .. Icons.UI.close .. " %X",
    hl = { fg = colors.red, bg = colors.bg },
  }

  local TabPages = {
    condition = function()
      return #vim.api.nvim_list_tabpages() >= 2
    end,
    { provider = "%=" },
    utils.make_tablist(Tabpage),
    TabpageClose,
  }

  local TabLineOffset = {
    condition = function(self)
      local win = vim.api.nvim_tabpage_list_wins(0)[1]
      local bufnr = vim.api.nvim_win_get_buf(win)
      self.winid = win

      if vim.api.nvim_buf_get_option(bufnr, "filetype") == "NvimTree" then
        self.title = "NvimTree"
        return true
      end
    end,
    provider = function(self)
      local title = self.title
      local width = vim.api.nvim_win_get_width(self.winid)
      local pad = math.ceil((width - #title) / 2)
      return string.rep(" ", pad) .. title .. string.rep(" ", pad)
    end,
    hl = { fg = colors.white, bg = "#333842", bold = true },
  }

  local TabLine = {
    TabLineOffset,
    BufferLine,
    TabPages,
  }

  -- Buffer navigation functions
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

  local function add_key(key, index)
    vim.keymap.set("n", "<A-" .. key .. ">", function()
      goto_buf(index)
    end, { noremap = true, silent = true })
  end

  for i = 1, 9 do
    add_key(i, i)
  end
  add_key("0", 10)

  vim.o.showtabline = 2
  vim.cmd([[au FileType * if index(['wipe', 'delete', 'unload'], &bufhidden) >= 0 | set nobuflisted | endif]])

  -- FIXED: Add proper autocmds for better statusline updates
  local augroup = vim.api.nvim_create_augroup("HeirlineStatusline", { clear = true })

  -- Force statusline refresh on mode changes and buffer events
  vim.api.nvim_create_autocmd({
    "ModeChanged",
    "BufEnter",
    "BufWinEnter",
    "WinEnter",
    "WinLeave",
    "CmdlineLeave",
    "TermEnter",
    "TermLeave"
  }, {
    group = augroup,
    callback = function()
      vim.schedule(function()
        if vim.o.laststatus > 0 then
          vim.cmd("redrawstatus!")
        end
      end)
    end,
  })

  -- Final heirline setup
  heirline.setup({
    statusline = StatusLine,
    winbar = WinBar,
    tabline = TabLine,
    opts = {
      disable_winbar_cb = function(args)
        local buf = args.buf
        if not vim.api.nvim_buf_is_valid(buf) then
          return true
        end

        local buftype = vim.tbl_contains(
          { "prompt", "nofile", "help", "quickfix" },
          vim.bo[buf].buftype
        )
        local filetype = vim.tbl_contains(
          { "gitcommit", "fugitive" },
          vim.bo[buf].filetype
        )
        return buftype or filetype
      end,
    }
  })

end

return M
