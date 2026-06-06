if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
eval "$(starship init zsh)"

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
