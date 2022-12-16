--vim.cmd([[
--  function RandomColorScheme()
--    let mycolors = split(globpath(&rtp,"**/colors/*.vim"),"\n") 
--    exe 'so ' . mycolors[localtime() % len(mycolors)]
--    unlet mycolors
--  endfunction
--  
--  call RandomColorScheme()
--  
--  :command NewColor call RandomColorScheme()
--]])

--vim.cmd([[
--  function RandomColorSchemeMyPicks()
--      let mypicks = ["pyte", "fokus", "github", "peachpuff", "morning", "simple256", "xcode", "gruvbox"]
--      let mypick = mypicks[localtime() % len(mypicks)]
--      echom mypick
--      execute 'colo' mypick
--  endfunction
--
--  command NewColor call RandomColorSchemeMyPicks()
--
--  let s:use_gui = exists('g:neovide') || has('gui_running') || (has('termguicolors') && &termguicolors)
--  if (s:use_gui)
--      call RandomColorSchemeMyPicks()
--  endif
--]])

vim.cmd([[
    let g:fzf_history_dir = '~/.local/share/fzf-history'
    map <leader>z :FZF<CR>
    map <leader>a :Files<CR>
    map <leader>l :Lines<CR>
    map <leader>L :BLines<CR>
    map <leader>B :Buffers<CR>
    map <leader>h :History:<CR>
    nnoremap <leader>g :Rg<CR>
    "nnoremap <leader>t :Tags<CR>
    nnoremap <leader>m :Marks<CR>
    " This is the default extra key bindings
    let g:fzf_action = {
                \ 'ctrl-t': 'tab split',
                \ 'ctrl-x': 'split',
                \ 'ctrl-y': 'vsplit' }
    let g:fzf_tags_command = 'ctags -R'
    " Border color
    let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8,'yoffset':0.5,'xoffset': 0.5, 'highlight': 'Todo', 'border': 'sharp' } }
    let $FZF_DEFAULT_OPTS = '--layout=reverse --info=inline'
    let $FZF_DEFAULT_COMMAND="rg --files --hidden"
    " Customize fzf colors to match your color scheme
    let g:fzf_colors =
                \ { 'fg':      ['fg', 'Normal'],
                \ 'bg':      ['bg', 'Normal'],
                \ 'hl':      ['fg', 'Comment'],
                \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
                \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
                \ 'hl+':     ['fg', 'Statement'],
                \ 'info':    ['fg', 'PreProc'],
                \ 'border':  ['fg', 'Ignore'],
                \ 'prompt':  ['fg', 'Conditional'],
                \ 'pointer': ['fg', 'Exception'],
                \ 'marker':  ['fg', 'Keyword'],
                \ 'spinner': ['fg', 'Label'],
                \ 'header':  ['fg', 'Comment'] }
    " Get Files
    command! -bang -nargs=? -complete=dir Files
                \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)
    " Get text in files with Rg
    command! -bang -nargs=* Rg
                \ call fzf#vim#grep(
                \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
                \   fzf#vim#with_preview(), <bang>0)
    " Ripgrep advanced
    function! RipgrepFzf(query, fullscreen)
        let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
        let initial_command = printf(command_fmt, shellescape(a:query))
        let reload_command = printf(command_fmt, '{q}')
        let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
        call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
    endfunction
    command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
    " Git grep
    command! -bang -nargs=* GGrep
                \ call fzf#vim#grep(
                \   'git grep --line-number '.shellescape(<q-args>), 0,
                \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)
    command! -bang FM call fzf#run(fzf#wrap({'source': 'cat ~/.fzf-marks | sed "s/.*: \(.*\)$/\1/" | sed "s#~#${HOME}#"', 'sink': 'lcd'}, <bang>0))
]])

vim.cmd([[
    " Enable mouse scrollback
    set mouse=a
    tnoremap <Esc> <C-\><C-n>
    tnoremap <c-b> <c-\><c-n>
    function! ClearTerminal()
        set scrollback=1
        let &g:scrollback=1
        echo &scrollback
        call feedkeys("\i")
        call feedkeys("clear\<CR>")
        call feedkeys("\<C-\>\<C-n>")
        call feedkeys("\i")
        sleep 100m
        let &scrollback=s:scroll_value
    endfunction
]])

vim.cmd([[
    " :Rename {newname}
    function! RenameFile()
        let old_name = expand('%')
        let new_name = input('New file name: ', expand('%'), 'file')
        if new_name != '' && new_name != old_name
            exec ':saveas ' . new_name
            exec ':silent !rm ' . old_name
            redraw!
        endif
    endfunction
    map <leader>re :call RenameFile()<cr>
]])

--vim.cmd([[
--  " Markdown Settings
--  autocmd BufNewFile,BufReadPost *.md set filetype=markdown
--  let g:markdown_fenced_languages = ['html', 'python', 'bash=sh', 'sql', 'pug']
--  let g:markdown_minlines = 100
--  let g:instant_markdown_autostart = 0
--]])
--
--vim.cmd([[
--  " On The Fly Table mode
--  function! s:isAtStartOfLine(mapping)
--    let text_before_cursor = getline('.')[0 : col('.')-1]
--    let mapping_pattern = '\V' . escape(a:mapping, '\')
--    let comment_pattern = '\V' . escape(substitute(&l:commentstring, '%s.*$', '', ''), '\')
--    return (text_before_cursor =~? '^' . ('\v(' . comment_pattern . '\v)?') . '\s*\v' . mapping_pattern . '\v$')
--  endfunction
--]])
