local M = {}

-- Cache the nerd fonts check with better error handling
local function get_nerd_fonts_available()
  if vim.g.nerd_fonts_available ~= nil then
    return vim.g.nerd_fonts_available
  end

  local has_nerd_fonts = false
  local ok, result = pcall(function()
    if vim.fn.has('unix') == 1 and vim.fn.executable('fc-list') == 1 then
      local handle = io.popen('fc-list | grep -i nerd 2>/dev/null')
      if handle then
        local result = handle:read('*a')
        handle:close()
        return result ~= ""
      end
    end
    return false
  end)

  has_nerd_fonts = ok and result or false
  vim.g.nerd_fonts_available = has_nerd_fonts
  return has_nerd_fonts
end

-- Helper function to get icon with fallback and validation
local function get_icon(nerd_icon, fallback, color, cterm_color, name)
  local has_nerd = get_nerd_fonts_available()

  -- Validate colors
  if not color or color == '' then
    color = '#6d8086' -- Default gray color
  end
  if not cterm_color or cterm_color == '' then
    cterm_color = '102' -- Default gray for terminal
  end

  -- Pick icon
  local icon = has_nerd and nerd_icon or fallback
  if not icon or icon == '' then
    icon = has_nerd and '󰈔' or '[F]'
  end

  return {
    icon = icon,
    color = color,
    cterm_color = cterm_color,
    name = name or 'File',
  }
end

function M.setup()
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if not ok or not devicons then
    return false
  end

  devicons.setup({
    color_icons = true,
    override = {
      -- Languages
      js   = get_icon('󰌞', '[JS]', '#f5c06f', '179', 'Js'),
      jsx  = get_icon('', '[JSX]', '#689fb6', '67', 'Jsx'),
      ts   = get_icon('󰛦', '[TS]', '#4377c1', '67', 'Ts'),
      tsx  = get_icon('', '[TSX]', '#4377c1', '67', 'Tsx'),
      lua  = get_icon('', '[LUA]', '#51a0cf', '74', 'Lua'),
      py   = get_icon('', '[PY]', '#3572A5', '67', 'Python'),
      rb   = get_icon('', '[RB]', '#701516', '124', 'Ruby'),
      go   = get_icon('', '[GO]', '#519aba', '74', 'Go'),
      rs   = get_icon('', '[RS]', '#dea584', '173', 'Rust'),

      -- Images
      png  = get_icon('󰋩', '[PNG]', '#d4843e', '173', 'Png'),
      jpg  = get_icon('󰋩', '[JPG]', '#16a085', '36', 'Jpg'),
      jpeg = get_icon('󰋩', '[JPG]', '#16a085', '36', 'Jpeg'),
      webp = get_icon('󰋩', '[WEBP]', '#3498db', '32', 'Webp'),
      svg  = get_icon('󰋩', '[SVG]', '#3affdb', '80', 'Svg'),

      -- Archives
      zip  = get_icon('', '[ZIP]', '#e6b422', '178', 'Zip'),
      rar  = get_icon('', '[RAR]', '#e6b422', '178', 'Rar'),
      ['7z'] = get_icon('', '[7Z]', '#e6b422', '178', '7z'),
      tar  = get_icon('', '[TAR]', '#e6b422', '178', 'Tar'),
      gz   = get_icon('', '[GZ]', '#e6b422', '178', 'GZip'),
      bz2  = get_icon('', '[BZ2]', '#e6b422', '178', 'BZip2'),

      -- Docs
      md   = get_icon('', '[MD]', '#519aba', '67', 'Markdown'),
      txt  = get_icon('', '[TXT]', '#6d8086', '102', 'Text'),
      pdf  = get_icon('', '[PDF]', '#e74c3c', '160', 'PDF'),
      doc  = get_icon('', '[DOC]', '#2c6ecb', '27', 'Word'),
      docx = get_icon('', '[DOC]', '#2c6ecb', '27', 'Word'),
      xls  = get_icon('', '[XLS]', '#1d6f42', '29', 'Excel'),
      xlsx = get_icon('', '[XLS]', '#1d6f42', '29', 'Excel'),

      -- Config
      json = get_icon('', '[JSON]', '#f5c06f', '179', 'Json'),
      yaml = get_icon('', '[YAML]', '#6d8086', '102', 'Yaml'),
      toml = get_icon('', '[TOML]', '#6d8086', '102', 'Toml'),
      conf = get_icon('', '[CFG]', '#6d8086', '102', 'Config'),
      ini  = get_icon('', '[INI]', '#6d8086', '102', 'Ini'),

      -- Shell
      sh   = get_icon('', '[SH]', '#4d5a5e', '59', 'Shell'),
      zsh  = get_icon('', '[ZSH]', '#89e051', '113', 'Zsh'),
      bash = get_icon('', '[BASH]', '#89e051', '113', 'Bash'),

      -- Git
      ['.gitignore']    = get_icon('', '[GIT]', '#e24329', '166', 'GitIgnore'),
      ['.gitattributes'] = get_icon('', '[GIT]', '#e24329', '166', 'GitAttributes'),
      ['.gitconfig']    = get_icon('', '[GIT]', '#e24329', '166', 'GitConfig'),
    },
    default = {
      icon = get_nerd_fonts_available() and '󰈔' or '[F]',
      name = 'File',
      color = '#6d8086',
      cterm_color = '102',
    },
  })

  return true
end

return M
