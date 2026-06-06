for f in "$HOME/.config/shell/env.sh" \
         "$HOME/.config/shell/sources.sh" \
         "$HOME/.config/shell/aliases.sh" \
         "$HOME/.config/shell/paths.sh"; do
  [ -r "$f" ] && . "$f"
done
