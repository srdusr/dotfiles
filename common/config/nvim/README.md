## Neovim

#### Dependencies

nvm
nvm install --lts

#### TODOS:

- [ ] Markdown filetype plugin or autocommand to add two spaces each line
- [ ] Markdown filetype plugin or autocommand to make backtick auto-correct properly
- [x] Indent by filetype/fix global indent (2)
- [x] Check history or telescope history of last files edited or opened.
- [ ] - Windows native support configuration
- [ ] - Python debugger
- [ ] README file heirachcy
- [ ] Markdown snippet for code blocks with list, ie.- ``and -` `
- [ ] Snippet for filler text with variations, ie. common sentences: The quick brown fox... and more and placeholder words
- [ ] Configure snippets.lua
- [ ] Documentation shortcuts for different languages quote in quote "locally" (preffered) or opening web browser
- [ ] Dictionary, an actual dictionary
- [ ] Null-ls/lsp keymap to check current buffer servers must check both same time
  > NOTE: Different servers must be configured only to one or another, research null-ls being archived
- [ ] Don't highlight whitespaces in lazygit (maybe exclusively markdown)
- [ ] Configure prettier/prettierd servers to join a lot of different files (null-ls)
- [ ] Nvim-tree preview window similar to telescope
- [x] Nvim-tree behaviour when delete current buffer
  > NOTE: One idea is to create an autocmd to make a blank window (hidden) as a secondary window but when creating a opening a new file it does not ask which split to open in
- [ ] Nvim-tree conditionally when open going in the opposite direction will go back to nvim-tree ie. going right then goes to nvim-tree but is conditionally because of tmux etc...
- [x] Substitute keybinding
- [ ] Snippet/filetype plugin for markdown tick boxes
- [ ] Delete lua/user/func.lua
- [ ] Clean entire config by prioritizing single quotation marks over double
