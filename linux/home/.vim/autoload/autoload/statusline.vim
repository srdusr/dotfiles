" statusline.vim

if exists('g:loaded_statusline') | finish | endif
let g:loaded_statusline = 1

" --- Detect Nerd Fonts ---
function! s:HasNerdFonts()
    if exists('g:statusline_nerd_fonts')
        return g:statusline_nerd_fonts
    endif

    if executable('fc-list')
        let l:output = system('fc-list | grep -i nerd')
        if len(split(l:output, '\n')) > 0
            return 1
        endif
    endif

    return 0
endfunction

let g:statusline_has_nerd_fonts = s:HasNerdFonts()

" --- Color Palette ---
let g:StslineColorGreen  = '#2BBB4F'
let g:StslineColorBlue   = '#4799EB'
let g:StslineColorViolet = '#986FEC'
let g:StslineColorYellow = '#D7A542'
let g:StslineColorOrange = '#EB754D'
let g:StslineColorLight  = '#C0C0C0'
let g:StslineColorDark   = '#080808'
let g:StslineColorDark1  = '#181818'
let g:StslineColorDark2  = 'NONE'
let g:StslineColorDark3  = '#303030'

let g:StslineBackColor   = g:StslineColorDark2
let g:StslineOnBackColor = g:StslineColorLight
let g:StslinePriColor    = g:StslineColorGreen
let g:StslineOnPriColor  = g:StslineColorDark
let g:StslineSecColor    = g:StslineColorDark3
let g:StslineOnSecColor  = g:StslineColorLight

" --- Highlight Groups ---
" Initial setup of highlight groups (will be updated by UpdateStslineColors)
execute 'highlight StslinePriColorBG guifg=' . g:StslineOnPriColor . ' guibg=' . g:StslinePriColor
execute 'highlight StslineSecColorFG guifg=' . g:StslineSecColor . ' guibg=' . g:StslineBackColor
execute 'highlight StslineSecColorBG guifg=' . g:StslineColorLight . ' guibg=' . g:StslineSecColor
execute 'highlight StslineBackColorBG guifg=' . g:StslineColorLight . ' guibg=' . g:StslineBackColor
execute 'highlight StslineBackColorFGSecColorBG guifg=' . g:StslineBackColor . ' guibg=' . g:StslineSecColor
execute 'highlight StslineSecColorFGBackColorBG guifg=' . g:StslineSecColor . ' guibg=' . g:StslineBackColor
execute 'highlight StslineModColorFG guifg=' . g:StslineColorYellow . ' guibg=' . g:StslineBackColor
execute 'highlight StslinePriColorBG_SecColorBG guifg=' . g:StslinePriColor . ' guibg=' . g:StslineSecColor
execute 'highlight StslineModeSep guifg=' . g:StslinePriColor . ' guibg=' . g:StslineSecColor
execute 'highlight StslineGitSep guifg=' . g:StslineSecColor . ' guibg=' . g:StslineColorDark2

" --- Statusline Settings ---
if has('nvim')
    set laststatus=3
else
    set laststatus=2
endif

"set noshowmode
"set termguicolors

let space = ''

" Get Statusline mode & also set primary color for that mode
function! autoload#statusline#StslineMode() abort
    let l:CurrentMode = mode()

    if l:CurrentMode ==# 'n'
        let g:StslinePriColor = g:StslineColorGreen
        let b:CurrentMode = 'NORMAL '
    elseif l:CurrentMode ==# 'i'
        let g:StslinePriColor = g:StslineColorViolet
        let b:CurrentMode = 'INSERT '
    elseif l:CurrentMode ==# 'c'
        let g:StslinePriColor = g:StslineColorYellow
        let b:CurrentMode = 'COMMAND'
    elseif l:CurrentMode ==# 'v'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'VISUAL '
    elseif l:CurrentMode ==# '\<C-v>'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'V-BLOCK'
    elseif l:CurrentMode ==# 'V'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'V-LINE '
    elseif l:CurrentMode ==# 'R'
        let g:StslinePriColor = g:StslineColorViolet
        let b:CurrentMode = 'REPLACE'
    elseif l:CurrentMode ==# 's'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'SELECT '
    elseif l:CurrentMode ==# 't'
        let g:StslinePriColor = g:StslineColorYellow
        let b:CurrentMode = 'TERM   '
    elseif l:CurrentMode ==# '!'
        let g:StslinePriColor = g:StslineColorYellow
        let b:CurrentMode = 'SHELL  '
    else
        let g:StslinePriColor = g:StslineColorGreen
    endif

    call autoload#statusline#UpdateStslineColors()

    return b:CurrentMode
endfunction

function! autoload#statusline#UpdateStslineColors() abort
    execute 'highlight StslinePriColorBG guifg=' . g:StslineOnPriColor . ' guibg=' . g:StslinePriColor
    execute 'highlight StslinePriColorBGBold guifg=' . g:StslineOnPriColor . ' guibg=' . g:StslinePriColor . ' gui=bold'
    execute 'highlight StslinePriColorFG guifg=' . g:StslinePriColor . ' guibg=' . g:StslineBackColor
    execute 'highlight StslinePriColorFGSecColorBG guifg=' . g:StslinePriColor . ' guibg=' . g:StslineSecColor
    execute 'highlight StslineModeSep guifg=' . g:StslinePriColor . ' guibg=' . g:StslineSecColor
    execute 'highlight StslineGitSep guifg=' . g:StslineSecColor . ' guibg=' . g:StslineColorDark2
    execute 'highlight StslineSecColorBG guifg=' . g:StslineColorLight . ' guibg=' . g:StslineSecColor
    execute 'highlight StslineBackColorBG guifg=' . g:StslineColorLight . ' guibg=' . g:StslineBackColor
    execute 'highlight StslineBackColorFGSecColorBG guifg=' . g:StslineBackColor . ' guibg=' . g:StslineSecColor
    execute 'highlight StslineSecColorFGBackColorBG guifg=' . g:StslineSecColor . ' guibg=' . g:StslineBackColor
    execute 'highlight StslineModColorFG guifg=' . g:StslineColorYellow . ' guibg=' . g:StslineBackColor
    execute 'highlight StslinePriColorBG_SecColorBG guifg=' . g:StslinePriColor . ' guibg=' . g:StslineSecColor
    execute 'highlight StslineSecColorFG guifg=' . g:StslineSecColor . ' guibg=' . g:StslineBackColor
endfunction

function! autoload#statusline#GetGitBranch() abort
    let b:GitBranch = ''
    try
        let l:dir = expand('%:p:h')
        let l:gitrevparse = system("git -C ".l:dir." rev-parse --abbrev-ref HEAD")
        if !v:shell_error
            let icon = g:statusline_has_nerd_fonts ? '  ' : ' [git] '
            let b:GitBranch = icon . substitute(l:gitrevparse, '\n', '', 'g') . ' '
        endif
    catch
    endtry
endfunction

function! autoload#statusline#GetFileType() abort
    if !g:statusline_has_nerd_fonts
        let b:FiletypeIcon = ''
        return
    endif
    if &filetype ==# 'typescript'  | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'html'    | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'scss'    | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'css'     | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'javascript' | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'javascriptreact' | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'markdown' | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'sh' || &filetype ==# 'zsh' | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'vim'     | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'rust'    | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'ruby'    | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'cpp'     | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'c'       | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'go'      | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'lua'     | let b:FiletypeIcon = ' '
    elseif &filetype ==# 'haskell' | let b:FiletypeIcon = ' '
    else                             | let b:FiletypeIcon = ' '
    endif
endfunction

function! autoload#statusline#ActivateStatusline() abort
    call autoload#statusline#GetFileType()
    call autoload#statusline#GetGitBranch() " Ensure git branch is updated

    let current_mode_str = autoload#statusline#StslineMode()
    call autoload#statusline#UpdateStslineColors()

    let readonly_icon = g:statusline_has_nerd_fonts ? ' ' : '[RO] '
    let modified_icon = g:statusline_has_nerd_fonts ? ' ' : '[+] '
    let git_sep       = g:statusline_has_nerd_fonts ? ''  : ' '
    let file_sep1     = g:statusline_has_nerd_fonts ? ' '  : ' '
    let file_sep2     = g:statusline_has_nerd_fonts ? ''  : ''

    " Get dynamic parts as simple strings
    let git_status_str = get(b:, "coc_git_status", get(b:, "GitBranch", ""))
    let git_blame_str = get(b:, "coc_git_blame", "")
    let filetype_icon_str = get(b:, "FiletypeIcon", "")
    let file_encoding_str = ''
    if &fenc != "utf-8"
        let file_encoding_str = &fenc . ' '
    endif

    " Build the statusline as a static string
    let l:statusline = ''

    let l:statusline .= '%#StslinePriColorBG# ' . current_mode_str . ''
    let l:statusline .= '%#StslineModeSep#' . git_sep
    let l:statusline .= '%#StslineSecColorBG#' . git_status_str . git_blame_str
    let l:statusline .= '%#StslineGitSep#' . git_sep

    " File info (Readonly, Modified, Filename)
    let l:statusline .= '%#StslinePriColorFG#'
    if &readonly
        let l:statusline .= readonly_icon
    endif
    let l:statusline .= ' %F '
    if &modified
        let l:statusline .= modified_icon
    endif

    " Right align everything after this
    let l:statusline .= '%='

    " Right side (Filetype, Encoding, Position)
    let l:statusline .= '%#StslinePriColorFG# ' . filetype_icon_str . '%y'
    let l:statusline .= '%#StslineSecColorFG#' . file_sep1
    "let l:statusline .= '%#StslineSecColorBG# ' . file_encoding_str
    let l:statusline .= '%#StslinePriColorFGSecColorBG#' . file_sep2
    let l:statusline .= '%#StslinePriColorBG# %p%% %#StslinePriColorBGBold#%l%#StslinePriColorBG#/%L :%c '
    let l:statusline .= '%#StslineBackColorBG#'

    " Set the statusline for the current buffer
    let &l:statusline = l:statusline
endfunction

function! autoload#statusline#DeactivateStatusline() abort
    let git_sep = g:statusline_has_nerd_fonts ? '' : ''
    let readonly_icon = g:statusline_has_nerd_fonts ? ' ' : '[RO] '
    let modified_icon = g:statusline_has_nerd_fonts ? ' ' : '[+] '

    " NOTE: This DeactivateStatusline function still uses %{} for dynamic parts.
    " If you encounter general E518 or other issues related to %{} expressions,
    " you will need to refactor this function to build a static string
    " similar to how ActivateStatusline now does it.
    if !exists("b:GitBranch") || b:GitBranch == ''
        let statusline =
            \ '%#StslineSecColorBG# INACTIVE ' .
            \ '%{get(b:,"coc_git_statusline",b:GitBranch)}%{get(b:,"coc_git_blame","")}' .
            \ '%#StslineBackColorFGSecColorBG#' . git_sep .
            \ '%#StslineBackColorBG# %{&readonly?"' . readonly_icon . '":""}%F ' .
            \ '%#StslineModColorFG#%{&modified?"' . modified_icon . '":""}' .
            \ '%=%#StslineBackColorBG# %{b:FiletypeIcon}%{&filetype}' .
            \ '%#StslineSecColorFGBackColorBG# | %p%% %l/%L :%c'
    else
        let statusline =
            \ '%#StslineSecColorBG# %{get(b:,"coc_git_statusline",b:GitBranch)}%{get(b:,"coc_git_blame","")}' .
            \ '%#StslineBackColorFGSecColorBG#' . git_sep .
            \ '%#StslineBackColorBG# %{&readonly?"' . readonly_icon . '":""}%F ' .
            \ '%#StslineModColorFG#%{&modified?"' . modified_icon . '":""}' .
            \ '%=%#StslineBackColorBG# %{b:FiletypeIcon}%{&filetype}' .
            \ '%#StslineSecColorFGBackColorBG# | %p%% %l/%L :%c'
    endif

    execute 'setlocal statusline=' . substitute(statusline, '"', '\\"', 'g')
endfunction

augroup StatuslineGit
    autocmd!
    autocmd BufEnter * call autoload#statusline#GetGitBranch()
augroup END

augroup SetStsline
   autocmd!
   autocmd BufEnter,WinEnter * call autoload#statusline#ActivateStatusline()
   autocmd ModeChanged * call autoload#statusline#ActivateStatusline()
augroup END

augroup StatuslineAutoReload
  autocmd!
  autocmd BufWritePost statusline.vim source <afile> | call autoload#statusline#ActivateStatusline()
augroup END

"call autoload#statusline#ActivateStatusline()
