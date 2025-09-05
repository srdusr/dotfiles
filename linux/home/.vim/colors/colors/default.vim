"{{{ Pre-setting
let g:colors_name = expand('<sfile>:t:r')

if ! exists("g:terminal_italics")
   let g:terminal_italics = 0
endif

if ! exists("g:spell_undercurl")
   let g:spell_undercurl = 0
endif
"}}}

"{{{ Color Palette (updated to match official Vim default colors)
" Note: Hex colors chosen to reflect official Vim default colorscheme

let s:black              = { "gui": "#171717", "cterm": "16" }
let s:white              = { "gui": "#EAE8E7", "cterm": "231" }
let s:gray               = { "gui": "#808080", "cterm": "244" }

" Reds
let s:red_fg             = { "gui": "#FFFFFF", "cterm": "231" }        " White fg on red bg for errors
let s:red_bg             = { "gui": "#A40000", "cterm": "52" }         " DarkRed bg (ErrorMsg bg)

" Blues and Cyan
let s:blue_fg            = { "gui": "#6A5ACD", "cterm": "60" }         " SlateBlue
let s:dark_cyan          = { "gui": "#008B8B", "cterm": "36" }         " DarkCyan
let s:cyan_bg            = { "gui": "#00CED1", "cterm": "38" }         " DarkTurquoise

" Greens
let s:green_fg           = { "gui": "#008000", "cterm": "22" }         " DarkGreen
let s:green_bg           = { "gui": "#90EE90", "cterm": "120" }        " LightGreen

" Yellows and Oranges
let s:yellow_fg          = { "gui": "#A52A2A", "cterm": "94" }         " Brown (used in Vim default)
let s:yellow_bg          = { "gui": "#FFFF00", "cterm": "226" }        " Yellow bg

let s:orange             = { "gui": "#FFA500", "cterm": "214" }        " Orange

" Purples
let s:purple             = { "gui": "#6A0DAD", "cterm": "90" }         " DarkMagenta

" Grays
let s:light_gray         = { "gui": "#D3D3D3", "cterm": "252" }
let s:dark_gray          = { "gui": "#4D4D4D", "cterm": "240" }

" No color
let s:NONE               = { "gui": "NONE", "cterm": "NONE" }

" Alias for Normal fg and background depending on background setting
if &background == "light"
   let s:norm      = s:black
   let s:bg        = s:NONE
   let s:bg_subtle = s:light_gray
   let s:gray_fg   = s:gray
   let s:green_fg  = s:green_fg
   let s:yellow_fg = s:yellow_fg
   let s:pink_fg   = s:purple
   let s:cyan_fg   = s:dark_cyan
   let s:blue_fg   = s:blue_fg
   let s:red_fg    = s:red_bg
   let s:gray_bg   = s:light_gray
   let s:green_bg  = s:green_bg
   let s:yellow_bg = s:yellow_bg
   let s:pink_bg   = s:orange
   let s:cyan_bg   = s:cyan_bg
   let s:blue_bg   = s:blue_fg
   let s:red_bg    = s:red_bg
else
   let s:norm      = s:white
   let s:bg        = s:NONE
   let s:bg_subtle = s:dark_gray
   let s:gray_fg   = s:gray
   let s:green_fg  = s:green_bg
   let s:yellow_fg = s:yellow_bg
   let s:pink_fg   = s:orange
   let s:cyan_fg   = s:cyan_bg
   let s:blue_fg   = s:blue_bg
   let s:red_fg    = s:red_bg
   let s:gray_bg   = s:dark_gray
   let s:green_bg  = s:green_fg
   let s:yellow_bg = s:yellow_fg
   let s:pink_bg   = s:purple
   let s:cyan_bg   = s:dark_cyan
   let s:blue_bg   = s:blue_fg
   let s:red_bg    = s:red_bg
endif
"}}}

"{{{ Highlight Function (keep your existing function)
function! s:hi(group, style)
   if g:terminal_italics == 0
      if has_key(a:style, "cterm") && a:style["cterm"] == "italic"
         unlet a:style.cterm
      endif
      if has_key(a:style, "term") && a:style["term"] == "italic"
         unlet a:style.term
      endif
   endif
   execute "highlight" a:group
      \ "guifg="   (has_key(a:style, "fg")   ? a:style.fg.gui   : "NONE")
      \ "guibg="   (has_key(a:style, "bg")   ? a:style.bg.gui   : "NONE")
      \ "guisp="   (has_key(a:style, "sp")   ? a:style.sp.gui   : "NONE")
      \ "gui="    (has_key(a:style, "gui")   ? a:style.gui     : "NONE")
      \ "ctermfg=" (has_key(a:style, "fg")   ? a:style.fg.cterm : "NONE")
      \ "ctermbg=" (has_key(a:style, "bg")   ? a:style.bg.cterm : "NONE")
      \ "cterm="   (has_key(a:style, "cterm") ? a:style.cterm   : "NONE")
      \ "term="   (has_key(a:style, "term")  ? a:style.term    : "NONE")
endfunction

if g:spell_undercurl == 1
   let s:attr_un   = 'undercurl'
else
   let s:attr_un   = 'underline'
endif
"}}}

"{{{ Common Highlighting updated to match official Vim default colorscheme

call s:hi("Normal",       {"fg": s:norm, "bg": s:bg})
call s:hi("Cursor",       {})
call s:hi("Conceal",      {"fg": s:yellow_fg})
call s:hi("ErrorMsg",     {"fg": s:red_fg, "bg": s:red_bg, "gui": "bold", "cterm": "bold"})
call s:hi("IncSearch",    {"gui": "reverse", "cterm": "reverse"})
call s:hi("ModeMsg",      {"gui": "bold", "cterm": "bold"})
call s:hi("NonText",      {"fg": s:blue_fg, "gui": "bold", "cterm": "bold"})
call s:hi("PmenuSbar",    {"bg": s:gray_bg})
call s:hi("StatusLine",   {"gui": "reverse,bold", "cterm": "reverse,bold"})
call s:hi("StatusLineNC", {"gui": "reverse", "cterm": "reverse"})
call s:hi("TabLineFill",  {"gui": "reverse", "cterm": "reverse"})
call s:hi("TabLineSel",   {"gui": "bold", "cterm": "bold"})
call s:hi("TermCursor",   {"gui": "reverse", "cterm": "reverse"})
call s:hi("WinBar",       {"gui": "bold", "cterm": "bold"})
call s:hi("WildMenu",     {"fg": s:black, "bg": s:yellow_bg})

call s:hi("VertSplit",    {"link": "Normal"})
call s:hi("WinSeparator", {"link": "VertSplit"})
call s:hi("WinBarNC",     {"link": "WinBar"})
call s:hi("DiffTextAdd",  {"link": "DiffText"})
call s:hi("EndOfBuffer",  {"link": "NonText"})
call s:hi("LineNrAbove",  {"link": "LineNr"})
call s:hi("LineNrBelow",  {"link": "LineNr"})
call s:hi("QuickFixLine", {"link": "Search"})
call s:hi("CursorLineSign", {"link": "SignColumn"})
call s:hi("CursorLineFold", {"link": "FoldColumn"})
call s:hi("CurSearch",    {"link": "Search"})
call s:hi("PmenuKind",    {"link": "Pmenu"})
call s:hi("PmenuKindSel", {"link": "PmenuSel"})
call s:hi("PmenuMatch",   {"link": "Pmenu"})
call s:hi("PmenuMatchSel", {"link": "PmenuSel"})
call s:hi("PmenuExtra",   {"link": "Pmenu"})
call s:hi("PmenuExtraSel", {"link": "PmenuSel"})
call s:hi("ComplMatchIns", {})
call s:hi("Substitute",   {"link": "Search"})
call s:hi("Whitespace",   {"link": "NonText"})
call s:hi("MsgSeparator", {"link": "StatusLine"})
call s:hi("NormalFloat",  {"link": "Pmenu"})
call s:hi("FloatBorder",  {"link": "WinSeparator"})
call s:hi("FloatTitle",   {"link": "Title"})
call s:hi("FloatFooter",  {"link": "Title"})

call s:hi("Error",       {"fg": s:red_fg, "bg": s:red_bg, "gui": "bold", "cterm": "bold"})
call s:hi("Todo",        {"fg": s:black, "bg": s:yellow_bg, "gui": "bold", "cterm": "bold"})

call s:hi("String",      {"link": "Constant"})
call s:hi("Character",   {"link": "Constant"})
call s:hi("Number",      {"link": "Constant"})
call s:hi("Boolean",     {"link": "Constant"})
call s:hi("Float",       {"link": "Number"})
call s:hi("Function",    {"link": "Identifier"})
call s:hi("Conditional", {"link": "Statement"})
call s:hi("Repeat",      {"link": "Statement"})
call s:hi("Label",       {"link": "Statement"})
call s:hi("Operator",    {"link": "Statement"})
call s:hi("Keyword",     {"link": "Statement"})
call s:hi("Exception",
