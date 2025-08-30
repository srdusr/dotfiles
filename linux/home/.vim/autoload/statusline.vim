"" This was made by Reddit user u/SamLovesNotion. Also with the help of - https://tdaly.co.uk/projects/vim-statusline-generator/ for learning the syntax. Sorry for English & grammar, this post was made in hurry.

" Images - https://www.reddit.com/r/vim/comments/ld8h2j/i_made_a_status_line_from_scratch_no_plugins_used/
" I have used Nerd icon fonts. Icons won't work without them. https://github.com/ryanoasis/nerd-fonts/

" This statusline looks exactly like Vim Airline (even more customizable & powerful) & loads faster than Vim airline. Only take few ms to load.

" STARTUP TIME - With Vim Airline - ~250ms. With this statusline - ~100ms. Without any statusline - ~98ms.

" Add all of this at the end of your vimrc OR Create separate file like 'statusline.vim' & 'colorsgroup.vim' & source those files in your main vimrc.
" e.g. source "~/.config/vim/statusline.vim"




" statusline.vim

" NOTE: This has been edited to fit my needs and is intended to be autoloaded in the autoload directory: "~/.vim/autoload/statusline.vim"

if exists('g:loaded_statusline') | finish | endif
let g:loaded_statusline = 1

" Color highlighting groups
" Add this AFTER `colorscheme` option in your vimrc. Otherwise your colorscheme will clear these highlightings.
" OR use ColorScheme autocommand. VERY IMPORTANT.

" Color pallet
" Green  - #2BBB4F (BG) - #080808 (FG)
" Blue   - #4799EB
" Violet - #986FEC
" Yellow - #D7A542
" Orange - #EB754D
" Grey1  - #202020
" Grey   - #303030

" Define color variables
let g:StslineColorGreen  = '#2BBB4F'
let g:StslineColorBlue   = '#4799EB'
let g:StslineColorViolet = '#986FEC'
let g:StslineColorYellow = '#D7A542'
let g:StslineColorOrange = '#EB754D'

let g:StslineColorLight  = '#C0C0C0'
let g:StslineColorDark   = '#080808'
let g:StslineColorDark1  = '#181818'
let g:StslineColorDark2  = '#202020'
let g:StslineColorDark3  = '#303030'

" Define colors
let g:StslineBackColor   = g:StslineColorDark2
let g:StslineOnBackColor = g:StslineColorLight
"let g:StslinePriColor    = g:StslineColorGreen
let g:StslineOnPriColor  = g:StslineColorDark
let g:StslineSecColor    = g:StslineColorDark3
let g:StslineOnSecColor  = g:StslineColorLight

" Create highlight groups
execute 'highlight StslineSecColorFG guifg=' . g:StslineSecColor   ' guibg=' . g:StslineBackColor
execute 'highlight StslineSecColorBG guifg=' . g:StslineColorLight ' guibg=' . g:StslineSecColor
execute 'highlight StslineBackColorBG guifg=' . g:StslineColorLight ' guibg=' . g:StslineBackColor
execute 'highlight StslineBackColorFGSecColorBG guifg=' . g:StslineBackColor ' guibg=' . g:StslineSecColor
execute 'highlight StslineSecColorFGBackColorBG guifg=' . g:StslineSecColor ' guibg=' . g:StslineBackColor
execute 'highlight StslineModColorFG guifg=' . g:StslineColorYellow ' guibg=' . g:StslineBackColor

" Statusline
" Enable statusline
set laststatus=2
" Disable showmode - i.e. Don't show mode like --INSERT-- in current statusline.
set noshowmode

" Enable GUI colors for terminals (Some terminals may not support this, so you'll have to *manually* set color pallet for tui colors.)
set termguicolors



" Understand statusline elements

" %{StslineMode()}  = Output of a function
" %#StslinePriColorBG# = Highlight group
" %F, %c, etc. are variables which contain value like - current file path, current colums, etc.
" %{&readonly?\"\ \":\"\"} = If file is readonly ? Then "Lock icon" Else : "Nothing"
" %{get(b:,'coc_git_status',b:GitBranch)}    = If b:coc_git_status efists, then it's value, else value of b:GitBranch
" &filetype, things starting with & are also like variables with info.
" \  - Is for escaping a space. \" is for escaping a double quote.
" %{&fenc!='utf-8'?\"\ \":''}   = If file encoding is NOT!= 'utf-8' ? THEN output a "Space" else : no character

let space = ' '

" Define active statusline
function! autoload#statusline#ActivateStatusline() abort
    call autoload#statusline#GetFileType()
    setlocal statusline=%#StslinePriColorBG#\ \ %{autoload#statusline#StslineMode()}\ %#StslineSecColorBG#%{get(b:,'coc_git_status',b:GitBranch)}%{get(b:,'coc_git_blame','')}%#StslineBackColorFGPriColorBG#%#StslinePriColorFG#\ %{&readonly?\"\ \":\"\"}%F\ %#StslineModColorFG#%{&modified?\"\ \":\"\"}%=%#StslinePriColorFG#\ %{b:FiletypeIcon}%{&filetype}\ %#StslineSecColorFG#%#StslineSecColorBG#%{&fenc!='utf-8'?\"\ \":''}%{&fenc!='utf-8'?&fenc:''}%{&fenc!='utf-8'?\"\ \":''}%#StslinePriColorFGSecColorBG#%#StslinePriColorBG#\ %p\%%\ %#StslinePriColorBGBold#%l%#StslinePriColorBG#/%L\ :%c\ \ %#{space}
endfunction

" Define Inactive statusline
function! autoload#statusline#DeactivateStatusline() abort
    if !exists("b:GitBranch") || b:GitBranch == ''
    setlocal statusline=%#StslineSecColorBG#\ INACTIVE\ %#StslineSecColorBG#%{get(b:,'coc_git_statusline',b:GitBranch)}%{get(b:,'coc_git_blame','')}%#StslineBackColorFGSecColorBG#%#StslineBackColorBG#\ %{&readonly?\"\ \":\"\"}%F\ %#StslineModColorFG#%{&modified?\"\ \":\"\"}%=%#StslineBackColorBG#\ %{b:FiletypeIcon}%{&filetype}\ %#StslineSecColorFGBackColorBG#%#StslineSecColorBG#\ %p\%%\ %l/%L\ :%c\
    else
    setlocal statusline=%#StslineSecColorBG#%{get(b:,'coc_git_statusline',b:GitBranch)}%{get(b:,'coc_git_blame','')}%#StslineBackColorFGSecColorBG#%#StslineBackColorBG#\ %{&readonly?\"\ \":\"\"}%F\ %#StslineModColorFG#%{&modified?\"\ \":\"\"}%=%#StslineBackColorBG#\ %{b:FiletypeIcon}%{&filetype}\ %#StslineSecColorFGBackColorBG#%#StslineSecColorBG#\ %p\%%\ %l/%L\ :%c\
    endif
endfunction

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
        let b:CurrentMode = 'COMMAND '
    elseif l:CurrentMode ==# 'v'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'VISUAL '
    elseif l:CurrentMode ==# '\<C-v>'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'V-BLOCK '
    elseif l:CurrentMode ==# 'V'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'V-LINE '
    elseif l:CurrentMode ==# 'R'
        let g:StslinePriColor = g:StslineColorViolet
        let b:CurrentMode = 'REPLACE '
    elseif l:CurrentMode ==# 's'
        let g:StslinePriColor = g:StslineColorBlue
        let b:CurrentMode = 'SELECT '
    elseif l:CurrentMode ==# 't'
        let g:StslinePriColor = g:StslineColorYellow
        let b:CurrentMode = 'TERM '
    elseif l:CurrentMode ==# '!'
        let g:StslinePriColor = g:StslineColorYellow
        let b:CurrentMode = 'SHELL '
    endif

    call autoload#statusline#UpdateStslineColors()

    return b:CurrentMode
endfunction

" Update colors. Recreate highlight groups with new Primary color value.
function! autoload#statusline#UpdateStslineColors() abort
    execute 'highlight StslinePriColorBG guifg=' . g:StslineOnPriColor . ' guibg=' . g:StslinePriColor
    execute 'highlight StslinePriColorBGBold guifg=' . g:StslineOnPriColor . ' guibg=' . g:StslinePriColor . ' gui=bold'
    execute 'highlight StslinePriColorFG guifg=' . g:StslinePriColor . ' guibg=' . g:StslineBackColor
    execute 'highlight StslinePriColorFGSecColorBG guifg=' . g:StslinePriColor . ' guibg=' . g:StslineSecColor
    execute 'highlight StslineSecColorFGPriColorBG guifg=' . g:StslineSecColor . ' guibg=' . g:StslinePriColor

    if !exists("b:GitBranch") || b:GitBranch == ''
        execute 'highlight StslineBackColorFGPriColorBG guifg=' . g:StslineBackColor . ' guibg=' . g:StslinePriColor
    endif
endfunction

" Get git branch name
function! autoload#statusline#GetGitBranch() abort
    let b:GitBranch = ""
    try
        let l:dir = expand('%:p:h')
        let l:gitrevparse = system("git -C ".l:dir." rev-parse --abbrev-ref HEAD")
        if !v:shell_error
            let b:GitBranch = "  " . substitute(l:gitrevparse, '\n', '', 'g') . " "
            execute 'highlight StslineBackColorFGPriColorBG guifg=' . g:StslineBackColor . ' guibg=' . g:StslineSecColor
        endif
    catch
    endtry
endfunction

" Get filetype & custom icon. Put your most used file types first for optimized performance.
function! autoload#statusline#GetFileType() abort
    if &filetype ==# 'typescript'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'html'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'scss'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'css'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'javascript'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'javascriptreact'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'markdown'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'sh' || &filetype ==# 'zsh'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'vim'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# ''
        let b:FiletypeIcon = ''
    elseif &filetype ==# 'rust'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'ruby'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'cpp'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'c'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'go'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'lua'
        let b:FiletypeIcon = ' '
    elseif &filetype ==# 'haskel'
        let b:FiletypeIcon = ' '
    else
        let b:FiletypeIcon = ' '
    endif
endfunction

" Automatically update git branch name when entering a buffer
augroup GetGitBranch
    autocmd!
    autocmd BufEnter * call autoload#statusline#GetGitBranch()
augroup END

" Set active / inactive statusline when entering or leaving a buffer
augroup SetStsline
    autocmd!
    autocmd BufEnter,WinEnter * call autoload#statusline#ActivateStatusline()
    autocmd BufLeave,WinLeave * call autoload#statusline#DeactivateStatusline()
augroup END

call autoload#statusline#ActivateStatusline()

