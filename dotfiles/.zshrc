# Managed by chezmoi. Edit the source in dotfiles-mac, not ~/.zshrc.

# mise activation
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# opencode
export PATH=/Users/john.memmott/.opencode/bin:$PATH

for f in "$HOME/.config/shell/env.sh" \
         "$HOME/.config/shell/aliases.sh" \
         "$HOME/.config/shell/sources.sh"; do
  [ -r "$f" ] && . "$f"
done
