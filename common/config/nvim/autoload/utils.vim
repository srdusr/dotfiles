" Toggle Zoom
function! utils#ZoomToggle()
    if exists('t:zoomed') && t:zoomed
        execute t:zoom_winrestcmd
        let t:zoomed = 0
    else
        let t:zoom_winrestcmd = winrestcmd()
        resize
        vertical resize
        let t:zoomed = 1
    endif
endfunction
"command! ZoomToggle call ZoomToggle()


"-------------------------------------------------

" Toggle DiagnosticsOpenFloat
function! utils#ToggleDiagnosticsOpenFloat()
    " Switch the toggle variable
    let g:DiagnosticsOpenFloat = !get(g:, 'DiagnosticsOpenFloat', 1)

    " Reset group
    augroup OpenFloat
            autocmd!
    augroup END

    " Enable if toggled on
    if g:DiagnosticsOpenFloat
        augroup OpenFloat
            autocmd! CursorHold * lua vim.diagnostic.open_float(nil, {focusable = false,})
            "autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focusable = false,})
            "autocmd! CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focusable = false,}) print ("vim.diagnostic.open_float enabled...")
        augroup END
    endif
endfunction
"command! ToggleDiagonsticsOpenFloat call ToggleDiagnosticsOpenFloat()


"-------------------------------------------------

" Toggle transparency
let t:is_transparent = 0
function! utils#Toggle_transparent_background()
  if t:is_transparent == 0
    hi Normal guibg=#111111 ctermbg=black
    let t:is_transparent = 1
  else
    hi Normal guibg=NONE ctermbg=NONE
    let t:is_transparent = 0
  endif
endfunction
"nnoremap <leader>tb :call Toggle_transparent_background()<CR>


"-------------------------------------------------

" Toggle statusline
let s:hidden_all = 0
function! utils#ToggleHiddenAll()
    if s:hidden_all  == 0
        let s:hidden_all = 1
        set noshowmode
        set noruler
        set laststatus=0
        set noshowcmd
    else
        let s:hidden_all = 0
        set showmode
        set ruler
        set laststatus=2
        set showcmd
    endif
endfunction
"nnoremap <S-h> :call ToggleHiddenAll()<CR>


"-------------------------------------------------

" Open last closed buffer
function! OpenLastClosed()
    let last_buf = bufname('#')
    if empty(last_buf)
        echo "No recently closed buffer found"
        return
    endif
    let result = input("Open ". last_buf . " in (n)ormal (v)split, (t)ab or (s)plit ? (n/v/t/s) : ")
    if empty(result) || (result !=# 'v' && result !=# 't' && result !=# 's' && result !=# 'n')
        return
    endif
    if result ==# 't'
        execute 'tabnew'
    elseif result ==# 'v'
        execute "vsplit"
    elseif result ==# 's'
        execute "split"
    endif
    execute 'b ' . last_buf
endfunction


"-------------------------------------------------

" Toggle Diff
let g:diff_is_open = 0

function! utils#ToggleDiff()
  if g:diff_is_open
    windo diffoff
    let g:diff_is_open = 0
  else
    windo diffthis
    let g:diff_is_open = 1
  endif
endfunction


"-------------------------------------------------

" Verbose Toggle
function! utils#VerboseToggle()
    if !&verbose
        set verbosefile=~/.config/nvim/verbose.log
        set verbose=15
    else
        set verbose=0
        set verbosefile=
    endif
endfunction


"-------------------------------------------------

" Jump List
function! utils#GotoJump()
  jumps
  let j = input("Please select your jump: ")
  if j != ''
    let pattern = '\v\c^\+'
    if j =~ pattern
      let j = substitute(j, pattern, '', 'g')
      execute "normal " . j . "\<c-i>"
    else
      execute "normal " . j . "\<c-o>"
    endif
  endif
endfunction


"-------------------------------------------------

" Disable annoying auto line break
fu! utils#DisableBr()
    set wrap
    set linebreak
    set nolist  " list disables linebreak
    set textwidth=0
    set wrapmargin=0
    set formatoptions-=t
endfu

" Disable line breaks for all file types
autocmd! BufNewFile,BufRead *.* call utils#DisableBr()


"-------------------------------------------------

" Annoying timestamp issue on write (The file has been changed since reading it...)
"function! utils#ProcessFileChangedShell()
"  if v:fcs_reason == 'mode' || v:fcs_reason == 'time'
"    let v:fcs_choice = ''
"  else
"    let v:fcs_choice = 'ask'
"  endif
"endfunction
"autocmd FileChangedShell <buffer> call utils#ProcessFileChangedShell()
"
"let lastline = line('$')
"let bufcontents = getline(1, lastline)
"edit!
"call setline(1, bufcontents)
"if line('$') > lastline
"  execute lastline+1.',$:d _'
"endif

" Annoying timestamp issue on write (The file has been changed since reading it...)
function! utils#ProcessFileChangedShell()
  if v:fcs_reason == 'mode' || v:fcs_reason == 'time'
    let v:fcs_choice = ''
  else
    let v:fcs_choice = 'ask'
  endif
endfunction

" Triggered when the file is changed externally
autocmd FileChangedShell <buffer> call utils#ProcessFileChangedShell()

" Triggered before writing the buffer to the file
autocmd BufWritePre <buffer> call utils#BeforeWrite()

function! utils#BeforeWrite()
  let lastline = line('$')
  let bufcontents = getline(1, lastline)
  edit!
  call setline(1, bufcontents)
  if line('$') > lastline
    execute lastline+1.',$:d _'
  endif
endfunction


"-------------------------------------------------

" On The Fly Table mode
function! s:isAtStartOfLine(mapping)
  let text_before_cursor = getline('.')[0 : col('.')-1]
  let mapping_pattern = '\V' . escape(a:mapping, '\')
  let comment_pattern = '\V' . escape(substitute(&l:commentstring, '%s.*$', '', ''), '\')
  return (text_before_cursor =~? '^' . ('\v(' . comment_pattern . '\v)?') . '\s*\v' . mapping_pattern . '\v$')
endfunction


"-------------------------------------------------

" :Rename {newname}
function! utils#RenameFile()
    let old_name = expand('%')
    let new_name = input('New file name: ', expand('%'), 'file')
    if new_name != '' && new_name != old_name
        exec ':saveas ' . new_name
        exec ':silent !rm ' . old_name
        redraw!
    endif
endfunction


"-------------------------------------------------
