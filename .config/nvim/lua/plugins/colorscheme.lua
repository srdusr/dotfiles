--local function MyHighlights()
--    vim.cmd('highlight Visual     cterm=NONE ctermbg=76  ctermfg=16  gui=NONE guibg=#5fd700 guifg=#000000')
--    vim.cmd('highlight StatusLine cterm=NONE ctermbg=231 ctermfg=160 gui=NONE guibg=#ffffff guifg=#d70000')
--    vim.cmd('highlight Normal     cterm=NONE ctermbg=17              gui=NONE guibg=#00005f')
--    vim.cmd('highlight NonText    cterm=NONE ctermbg=17              gui=NONE guibg=#00005f')
--end
--
--local function setupMyColors()
--    vim.cmd('augroup MyColors')
--    vim.cmd('autocmd!')
--    vim.cmd('autocmd ColorScheme * call v:lua.MyHighlights()')
--    vim.cmd('augroup END')
--end
--
--setupMyColors()

--vim.api.nvim_command("highlight FoldColumn guibg=none")

--vim.api.nvim_command("highlight SignColumn guifg=none guibg=none cterm=NONE ctermfg=none ctermbg=NONE gui=NONE")
--vim.api.nvim_command("highlight ColorColumn guifg=none guibg=none cterm=NONE ctermfg=none ctermbg=NONE gui=NONE")
--vim.api.nvim_command("highlight TabLineSel guibg=none guifg=none gui=bold")
--vim.api.nvim_command("highlight TabLineNC guibg=none gui=bold")
--vim.api.nvim_command("highlight StatusLine guibg=#333842 gui=bold")
--vim.api.nvim_command("highlight StatusLineNC guibg=none ctermfg=Cyan guifg=#80a0ff gui=bold")

-- Custom colorscheme
--vim.cmd([[
-- let g:terminal_color_0  = '#2e3436'
-- let g:terminal_color_1  = '#cc0000'
-- let g:terminal_color_2  = '#4e9a06'
-- let g:terminal_color_3  = '#c4a000'
-- let g:terminal_color_4  = '#3465a4'
-- let g:terminal_color_5  = '#75507b'
-- let g:terminal_color_6  = '#0b939b'
-- let g:terminal_color_7  = '#d3d7cf'
-- let g:terminal_color_8  = '#555753'
-- let g:terminal_color_9  = '#ef2929'
-- let g:terminal_color_10 = '#8ae234'
-- let g:terminal_color_11 = '#fce94f'
-- let g:terminal_color_12 = '#729fcf'
-- let g:terminal_color_13 = '#ad7fa8'
-- let g:terminal_color_14 = '#00f5e9'
-- let g:terminal_color_15 = '#eeeeec'
--
-- set background=dark
-- execute "silent! colorscheme base16-eighties"
-- highlight Comment guifg=#585858
-- highlight Normal guifg=#999999
-- "highlight TabLine guifg=#333333 guibg=#777777
-- "highlight TabLineSel guifg=#FA7F7F
-- highlight MatchParen gui=bold guibg=black guifg=limegreen
--]])
--local colors = {
--  background = '#1c1c1c',
--  foreground = '#cacaca',
--  accent = '#fe5186',
--  blue = '#61afef',
--  cyan = '#3e8fb0',
--  dark_green = '#5faf5f',
--  dark_grey = '#222222',
--  dark_orange = '#ff5d62',
--  dark_red = '#bf1131',
--  dark_yellow = '#ffaf00',
--  green = '#98c379',
--  grey = '#2a2a2a',
--  light_grey = '#727169',
--  light_orange = '#ffa066',
--  light_pink = '#e46876',
--  light_yellow = '#e6db74',
--  magenta = '#c678dd',
--  orange = '#ff8700',
--  purple = '#af87d7',
--  red = '#c4384b',
--  violet = '#a9a1e1',
--  white = '#e3e3e3',
--  yellow = '#d7af5f',
--}
---- Base highlights to override themes to my preferences
--local base = {
--  CursorLine             = { bg = 'none', fg = 'none' },
--  -- Avoid changing the foreground color from the main theme
--  MatchParen             = { fg = colors.accent, bg = 'none', bold = true },
--  Visual                 = { bg = colors.grey, fg = 'none' },
--  ActionPreviewBorder    = { link = 'XMenuBorder' },
--  ActionPreviewNormal    = { link = 'XMenu' },
--  CallHierarchyBorder    = { link = 'XMenuBorder' },
--  CallHierarchyNormal    = { link = 'XMenu' },
--  CodeActionBorder       = { link = 'XMenuBorder' },
--  CodeActionNormal       = { link = 'XMenu' },
--  DefinitionBorder       = { link = 'XMenuBorder' },
--  DefinitionNormal       = { link = 'XMenu' },
--  EndOfBuffer            = { fg = colors.background },
--  FinderBorder           = { link = 'XMenuBorder' },
--  FinderNormal           = { link = 'XMenu' },
--  FloatBorder            = { link = 'XMenuBorder' },
--  FloatNormal            = { link = 'XMenu' },
--  HoverBorder            = { link = 'XMenuBorder' },
--  HoverNormal            = { link = 'XMenu' },
--  NormalFloat            = { link = 'XMenu' },
--  OutlinePreviewBorder   = { link = 'XMenuBorder' },
--  OutlinePreviewNormal   = { link = 'XMenu' },
--  Pmenu                  = { link = 'XMenu' },
--  RenameBorder           = { link = 'XMenuBorder' },
--  RenameNormal           = { link = 'XMenu' },
--  TerminalBorder         = { link = 'XMenuBorder' },
--  TerminalNormal         = { link = 'XMenu' },
--  Todo                   = { fg = colors.orange, bold = true },
--  SagaNormal             = { link = 'XMenu' },
--  SagaBorder             = { link = 'XMenuBorder' },
--  StatusLine             = { bg = colors.background, fg = colors.foreground },
--  TitleString            = { link = 'XMenu' },
--  TitleIcon              = { link = 'XMenu' },
--  ActionPreviewTitle     = { link = 'XMenu' },
--  -- Mason
--  MasonHeader            = { link = 'XMenu' },
--  MasonNormal            = { link = 'XMenu' },
--  NvimTreeCursorColumn   = { bg = 'none', fg = 'none' },
--  --NvimTreeCursorLine     = { bg = colors.dark_grey, fg = colors.accent },
--  -- Telescope
--  TelescopeBorder        = { link = 'XMenuBorder' },
--  TelescopePromptBorder  = { link = 'XMenuBorder' },
--  TelescopePromptNormal  = { link = 'XMenu', fg = colors.foreground },
--  TelescopePromptPrefix  = { link = 'XMenu', fg = colors.foreground },
--  TelescopeNormal        = { bg = colors.background },
--  TelescopePreviewBorder = { link = 'XMenuBorder' },
--  TelescopePreviewNormal = { link = 'XMenu', fg = colors.foreground },
--  TelescopePreviewTitle  = { fg = colors.background, bg = colors.light_orange },
--  TelescopePreviewLine   = { fg = colors.background, bg = colors.orange },
--  TelescopePromptTitle   = { fg = colors.background, bg = colors.light_orange },
--  TelescopeResultsTitle  = { fg = colors.background, bg = colors.light_orange },
--  TelescopeResultsBorder = { link = 'XMenuBorder' },
--  TelescopeResultsNormal = { link = 'XMenu' },
--}
--
--local theme = {
--  -- Transparent background
--  Conceal                    = { bg = 'none', fg = colors.foreground },
--  FoldCoumn                  = { bg = 'none' },
--  LineNr                     = { bg = 'none', fg = colors.grey },
--  MsgArea                    = { bg = 'none', fg = colors.foreground },
--  NonText                    = { bg = 'none', fg = colors.light_grey },
--  Normal                     = { bg = 'none', fg = colors.foreground },
--  NormalNC                   = { bg = 'none', fg = colors.foreground },
--  SignColumn                 = { bg = 'none' },
--  WinSeparator               = { bg = 'none', fg = colors.grey },
--  -- Language Syntax
--  Boolean                    = { fg = colors.grey },
--  Character                  = { fg = colors.yellow },
--  Comment                    = { fg = colors.light_grey },
--  Conditional                = { fg = colors.blue },
--  Constant                   = { fg = colors.grey },
--  Debug                      = { fg = colors.green },
--  Define                     = { fg = colors.green },
--  Delimiter                  = { fg = colors.grey },
--  Error                      = { fg = colors.red },
--  Exception                  = { fg = colors.dark_orange },
--  Float                      = { fg = colors.light_pink },
--  Function                   = { fg = colors.foreground },
--  Identifier                 = { fg = colors.foreground },
--  Ignore                     = { fg = colors.light_grey },
--  Include                    = { fg = colors.dark_orange },
--  Keyword                    = { fg = colors.blue },
--  Label                      = { fg = colors.grey },
--  Macro                      = { fg = colors.dark_orange },
--  Number                     = { fg = colors.light_pink },
--  Operator                   = { fg = colors.purple },
--  PreCondit                  = { fg = colors.dark_orange },
--  PreProc                    = { fg = colors.dark_orange },
--  Repeat                     = { fg = colors.blue },
--  Special                    = { fg = colors.dark_orange },
--  SpecialChar                = { fg = colors.dark_orange },
--  SpecialComment             = { fg = colors.orange },
--  Statement                  = { fg = colors.blue },
--  StorageClass               = { fg = colors.light_orange },
--  String                     = { fg = colors.yellow },
--  Structure                  = { fg = colors.light_orange },
--  Tag                        = { fg = colors.orange },
--  Todo                       = { fg = colors.orange, bold = true },
--  Type                       = { fg = colors.light_orange },
--  Typedef                    = { fg = colors.foreground },
--  Underlined                 = { fg = colors.foreground },
--  -- Rest
--  ColorColumn                = { bg = colors.dark_grey },
--  Cursor                     = { bg = colors.accent },
--  CursorColumn               = { bg = 'none', fg = colors.accent },
--  CursorLine                 = { bg = 'none', fg = 'none' },
--  CursorLineNr               = { bg = 'none', fg = colors.light_pink },
--  Directory                  = { fg = colors.cyan, bold = true },
--  ErrorMsg                   = { bg = 'none', fg = colors.red },
--  IncSearch                  = { bg = colors.accent, fg = colors.foreground },
--  MatchParen                 = { fg = colors.accent, bg = 'none', bold = true },
--  Search                     = { bg = colors.accent },
--  SpellBad                   = { bg = 'none', fg = 'none', undercurl = true, ctermbg = 'none', ctermfg = 'none' },
--  SpellLocal                 = { bg = 'none', fg = 'none', undercurl = true, ctermbg = 'none', ctermfg = 'none' },
--  SpellRare                  = { bg = 'none', fg = 'none', undercurl = true, ctermbg = 'none', ctermfg = 'none' },
--  StatusLine                 = { fg = colors.foreground, bg = 'none' },
--  StatusLineNC               = { fg = 'none', bg = 'none' },
--  Title                      = { fg = colors.blue, bg = '', bold = true },
--  VertSplit                  = { bg = 'none', fg = colors.grey },
--  Visual                     = { bg = colors.grey, fg = 'none' },
--  -- Diagnostic
--  DiagnosticBorder           = { link = 'XMenuBorder' },
--  DiagnosticNormal           = { link = 'XMenu' },
--  DiagnosticError            = { fg = colors.red },
--  DiagnosticFloatingError    = { link = 'XMenu' },
--  DiagnosticFloatingHint     = { link = 'XMenu' },
--  DiagnosticFloatingInfo     = { link = 'XMenu' },
--  DiagnosticFloatingWarn     = { link = 'XMenu' },
--  DiagnosticSignHint         = { fg = colors.grey, bold = true, bg = 'none' },
--  DiagnosticUnderlineError   = { undercurl = true },
--  DiagnosticVirtualTextHint  = { bg = 'none' },
--  DiagnosticWarn             = { fg = colors.yellow },
--  -- nvim cmp
--  CmpItemAbbr                = { fg = colors.foreground },
--  CmpItemAbbrMatch           = { fg = colors.dark_orange },
--  CmpItemAbbrMatchFuzzy      = { fg = colors.dark_orange },
--  CmpBorder                  = { link = 'FloatBorder' },
--  CmpDocBorder               = { link = 'FloatBorder' },
--  CmpItemMenuDefault         = { link = 'NormalFloat' },
--  CmpMenu                    = { link = 'NormalFloat' },
--  -- cmp item kinds
--  CmpItemKindConstant        = { fg = colors.light_pink },
--  CmpItemKindFunction        = { fg = colors.blue },
--  CmpItemKindIdentifier      = { fg = colors.purple },
--  CmpItemKindField           = { fg = colors.dark_orange },
--  CmpItemKindVariable        = { fg = colors.purple },
--  CmpItemKindSnippet         = { fg = colors.light_pink },
--  CmpItemKindText            = { fg = colors.foreground },
--  CmpItemKindStructure       = { fg = colors.blue },
--  CmpItemKindType            = { fg = colors.orange },
--  CmpItemKindKeyword         = { fg = colors.blue },
--  CmpItemKindMethod          = { fg = colors.purple },
--  CmpItemKindConstructor     = { fg = colors.blue },
--  CmpItemKindFolder          = { fg = colors.blue },
--  CmpItemKindModule          = { fg = colors.dark_orange },
--  CmpItemKindProperty        = { fg = colors.dark_orange },
--  CmpItemKindEnum            = { fg = colors.blue },
--  CmpItemKindUnit            = { fg = colors.green },
--  CmpItemKindClass           = { fg = colors.blue },
--  CmpItemKindFile            = { fg = colors.blue },
--  CmpItemKindInterface       = { fg = colors.blue },
--  CmpItemKindColor           = { fg = colors.yellow },
--  CmpItemKindReference       = { fg = colors.blue },
--  CmpItemKindEnumMember      = { fg = colors.green },
--  CmpItemKindStruct          = { fg = colors.blue },
--  -- CmpItemKindValue = { fg = "" },
--  -- CmpItemKindEvent = { fg = "" },
--  CmpItemKindOperator        = { fg = colors.purple },
--  CmpItemKindTypeParameter   = { fg = colors.light_pink },
--  CmpItemKindCopilot         = { fg = colors.green },
--  -- LSPSaga
--  OutlinePreviewBorder       = { link = 'NormalFloat' },
--  OutlinePreviewNormal       = { link = 'FloatBorder' },
--  -- Diffview
--  DiffViewSignColumn         = { bg = 'none' },
--  -- Treesitter
--  -- ['@string'] = { fg = colors.yellow, bg = '' },
--  ['@boolean']               = { fg = colors.dark_yellow },
--  ['@character']             = { fg = colors.foreground },
--  ['@character.special']     = { fg = colors.dark_orange },
--  ['@comment']               = { link = 'Comment' },
--  ['@conditional']           = { fg = colors.blue },
--  ['@constant']              = { fg = colors.foreground },
--  ['@constant.builtin']      = { fg = colors.dark_yellow },
--  ['@constant.macro']        = { fg = colors.dark_orange },
--  ['@constructor']           = { fg = colors.blue },
--  ['@debug']                 = { link = 'Debug' },
--  ['@define']                = { link = "Define" },
--  ['@exception']             = { fg = colors.dark_orange },
--  ['@field']                 = { link = 'Identifier' },
--  ['@field.yaml']            = { fg = colors.light_orange },
--  ['@float']                 = { fg = colors.light_pink },
--  ['@function']              = { link = 'Function' },
--  ['@function.builtin']      = { fg = colors.dark_green },
--  ['@function.macro']        = { fg = colors.dark_orange },
--  ['@include']               = { fg = colors.dark_orange },
--  ['@keyword']               = { link = 'Keyword' },
--  ['@keyword.operator']      = { fg = colors.purple },
--  ['@keyword.return']        = { fg = colors.dark_orange },
--  ['@label']                 = { fg = colors.blue },
--  ['@macro']                 = { fg = colors.dark_orange },
--  ['@method']                = { fg = colors.foreground },
--  ['@namespace']             = { fg = colors.foreground },
--  ['@number']                = { link = 'Number' },
--  ['@operator']              = { link = 'Operator' },
--  ['@parameter']             = { fg = colors.foreground },
--  ['@preproc']               = { link = 'PreProc' },
--  ['@property']              = { fg = colors.foreground },
--  ['@punctuation.Special']   = { fg = colors.purple },
--  ['@punctuation.bracket']   = { fg = colors.purple },
--  ['@punctuation.delimiter'] = { fg = colors.purple },
--  ['@repeat']                = { link = 'Repeat' },
--  ['@storageclass']          = { link = 'StorageClass' },
--  ['@string.escape']         = { fg = colors.dark_orange },
--  ['@string.regex']          = { fg = colors.green },
--  ['@string.special']        = { fg = colors.dark_orange },
--  ['@structure']             = { link = 'Structure' },
--  ['@tag']                   = { link = 'Tag' },
--  ['@tag.attribute']         = { fg = colors.foreground },
--  ['@tag.delimiter']         = { fg = colors.purple },
--  ['@text.danger']           = { fg = colors.dark_orange },
--  ['@text.literal']          = { link = 'String' },
--  ['@text.reference']        = { fg = colors.green },
--  ['@text.strong']           = { bold = true },
--  ['@text.title']            = { link = 'Title' },
--  ['@text.todo']             = { link = 'Todo' },
--  ['@text.underline']        = { link = 'Underlined' },
--  ['@text.uri']              = { fg = colors.blue },
--  ['@text.warning']          = { link = 'Todo' },
--  ['@type']                  = { link = 'Type' },
--  ['@type.definition']       = { link = 'Typedef' },
--  ['@variable']              = { fg = colors.foreground },
--  ['@variable.builtin']      = { fg = colors.light_orange },
--}
--
--local M = {}
--
--local function _load(config)
--  for group, hl in pairs(config) do
--    if not vim.tbl_isempty(hl) then
--      vim.api.nvim_set_hl(0, group, hl)
--    end
--  end
--end
--
--
--function M.setup()
--  vim.api.nvim_set_hl(0, 'XMenu', { bg = colors.dark_grey, default = true })
--  vim.api.nvim_set_hl(0, 'XMenuBorder', { bg = colors.dark_grey, fg = colors.dark_grey, default = true })
--  vim.g.terminal_color_0 = colors.dark_grey
--end
--
----function M.load(full)
----  _load(base)
----
----  if not full then
----    _load_diagnostics()
----    return
----  end
----
----  _load(theme)
----end
--
--return M
