# Shared shell aliases. Sourced from your shell rc.

# alias ll='ls -lah'
# alias g='git'

alias gcm='git commit -m'
alias gaa='git add -A'
alias gco='git checkout'
alias gpl='git pull origin'
alias gps='git push'
alias gst='git status'
alias gsh='git stash'
alias gsa='git stash apply'
alias gbr='git branch'
alias gpo='git push origin'
alias gdf='git diff'
alias gfe='git fetch --prune'
alias grs='git reset --soft HEAD~1' # undo the last commit
alias grs!='git reset --hard HEAD~1' # remove the last commit
alias gcn='git clone'

# Find commits by source code.
gfcs() {
  git log --pretty=custom --decorate --date=short -S"$1"
}

# Find commits by commit message.
gfcm() {
  git log --pretty=custom --decorate --date=short --grep="$1"
}

# List remote branches.
glrb() {
  remote="${1:-origin}"
  git ls-remote --heads "$remote"
}

# Directory aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dev='cd ~/Developer'
alias doc='cd ~/Documents'
alias des='cd ~/Desktop'
alias dow='cd ~/Downloads'
alias home='cd ~'

# Tool aliases
# alias ls='eza'
alias ls='ls'
alias find='fd'
if [[ -o interactive ]]; then
  alias cd='z'
fi
alias cat='bat --paging=never'
alias lst='eza --tree'
alias fzf='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'
alias fzb='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'
alias neofetch='macchina'
alias fetch='macchina'
alias helix='hx'
