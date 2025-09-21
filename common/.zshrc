# ~/.zshrc
[[ -f ~/.config/zsh/.zshrc ]] && source ~/.config/zsh/.zshrc

# Point all zsh startup files to ~/.config/zsh
export ZDOTDIR="$HOME/.config/zsh"

# If you want, you can still source your real zshenv from there:
if [[ -f "$ZDOTDIR/.zshenv" ]]; then
  source "$ZDOTDIR/.zshenv"
fi
