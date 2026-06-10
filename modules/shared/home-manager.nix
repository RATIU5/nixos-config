{ config, pkgs, lib, user, fullName, email, ... }:

{

  direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

  zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Fuzzy finder + completion engine. enableZshIntegration wires CTRL-T (files),
  # CTRL-R (history), and ALT-C (cd), plus fuzzy tab-completion for cd/kill/ssh.
  fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      # Catppuccin Mocha. `bg:-1` keeps the terminal's (transparent) background;
      # only the selection line (bg+) gets a solid surface color for contrast.
      "--color=bg:-1,bg+:#313244,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
      "--color=selected-bg:#45475a"
      "--color=border:#6c7086,label:#cdd6f4"
    ];
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };

  # SQLite-backed shell history with full-text CTRL-R search, scoped by
  # directory/exit-code/duration. Local-only by default (no sync).
  atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ]; # keep up-arrow as plain prefix history
    settings = {
      style = "compact";
      inline_height = 25;
      show_preview = true;
      enter_accept = false;
    };
  };

  zsh = {
    enable = true;
    autocd = false;
    cdpath = [ "~/.local/share/src" ];
    # Migrated from dotfiles/config/shell/sources.sh (Homebrew zsh-autosuggestions).
    autosuggestion.enable = true;
    plugins = [
      {
          name = "zsh-autocomplete";
          src = pkgs.zsh-autocomplete;
          file = "share/zsh-autocomplete/zsh-autocomplete.plugin.zsh";
      }
    ];
    # Migrated from dotfiles/config/shell/aliases.sh. Simple 1:1 aliases live
    # here; functions and conditional aliases stay in initContent below.
    shellAliases = {
      # git
      gcm = "git commit -m";
      gaa = "git add -A";
      gco = "git checkout";
      gpl = "git pull origin";
      gps = "git push";
      gst = "git status";
      gsh = "git stash";
      gsa = "git stash apply";
      gbr = "git branch";
      gpo = "git push origin";
      gdf = "git diff";
      gfe = "git fetch --prune";
      grs = "git reset --soft HEAD~1";   # undo the last commit
      "grs!" = "git reset --hard HEAD~1"; # remove the last commit
      gcn = "git clone";
      # directories
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      dev = "cd ~/Developer";
      doc = "cd ~/Documents";
      des = "cd ~/Desktop";
      dow = "cd ~/Downloads";
      home = "cd ~";
      # tools
      find = "fd";
      cat = "bat --paging=never";
      lst = "eza --tree";
      fzf = ''fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'';
      fzb = ''fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'';
      neofetch = "macchina";
      fetch = "macchina";
      helix = "hx";
      # ripgrep + syntax-aware diff (kept from prior Nix config)
      search = ''rg -p --glob "!node_modules/*" --glob "!vendor/*" "$@"'';
      diff = "difft";
    };
    initContent = lib.mkBefore ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Save and restore last directory
      LAST_DIR_FILE="$HOME/.zsh_last_dir"

      # Save directory on every cd
      function chpwd() {
        echo "$PWD" > "$LAST_DIR_FILE"
      }

      # Restore last directory on startup
      if [[ -f "$LAST_DIR_FILE" ]] && [[ -r "$LAST_DIR_FILE" ]]; then
        last_dir="$(cat "$LAST_DIR_FILE")"
        if [[ -d "$last_dir" ]]; then
          cd "$last_dir"
        fi
      fi

      export TERM=xterm-256color

      # Environment (migrated from dotfiles/config/shell/env.sh)
      export EFFECT_REPO="$HOME/.local/share/effect-solutions/effect"
      export PAGER=less
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_BIN_HOME="$HOME/.local/bin"
      export XDG_CACHE_HOME="$HOME/.cache"
      export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
      export STARSHIP_CACHE="$XDG_CACHE_HOME/.starship/cache"

      # Helix is my editor
      export EDITOR="hx"
      export VISUAL="hx"

      # Odin LSP (ols) is built manually from source (nixpkgs build is broken
      # against our Odin). It needs its builtin/ folder pointed to explicitly
      # since the binary is symlinked onto PATH. See modules/shared/packages.nix.
      export OLS_BUILTIN_FOLDER="$HOME/.local/share/ols/builtin"

      # Define PATH variables
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.composer/vendor/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/.local/share/src/conductly/bin:$PATH
      export PATH=$HOME/.local/share/src/conductly/utils:$PATH
      export PYTHONPATH="$HOME/.local-pip/packages:$PYTHONPATH"

      # PATH (migrated from dotfiles/config/shell/paths.sh)
      export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:$PATH"
      export PATH="$HOME/.opencode/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"

      # eza as a modern ls: icons, git status column, directories first
      alias ls='eza --icons --group-directories-first'
      alias ll='eza --icons --group-directories-first --long --git --header'
      alias la='eza --icons --group-directories-first --long --git --header --all'
      alias lt='eza --icons --tree --level=2'

      # mise runtime manager (migrated from sources.sh; no-op if not installed)
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi

      # lazydocker against the podman machine. Resolve DOCKER_HOST on demand so
      # we don't pay `podman machine inspect` on every shell startup.
      lazydocker() {
        if [ -z "$DOCKER_HOST" ] && command -v podman >/dev/null 2>&1; then
          local sock
          sock="$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
          [ -n "$sock" ] && export DOCKER_HOST="unix://$sock"
        fi
        command lazydocker "$@"
      }

      # git helper functions (migrated from aliases.sh)
      gfcs() { git log --pretty=custom --decorate --date=short -S"$1"; }   # find commits by source
      gfcm() { git log --pretty=custom --decorate --date=short --grep="$1"; }  # find commits by message
      glrb() { git ls-remote --heads "''${1:-origin}"; }                   # list remote branches

      # Use zoxide's `z` for cd in interactive shells (migrated from aliases.sh)
      if [[ -o interactive ]]; then
        alias cd='z'
      fi

      # SSH wrapper functions with terminal color changes
      ssh-production() {
          # Change terminal background to dark red
          printf '\033]11;#3d1515\007'
          command ssh production "$@"
          # Reset terminal background
          printf '\033]11;#1f2528\007'
      }

      ssh-staging() {
          # Change terminal background to dark orange
          printf '\033]11;#3d2915\007'
          command ssh staging "$@"
          # Reset terminal background
          printf '\033]11;#1f2528\007'
      }

      ssh-droplet() {
          # Change terminal background to dark green
          printf '\033]11;#153d15\007'
          command ssh droplet "$@"
          # Reset terminal background
          printf '\033]11;#1f2528\007'
      }

      # Override ssh command to detect known hosts
      ssh() {
          case "$1" in
              production|209.97.152.81)
                  # Change terminal background to dark red
                  printf '\033]11;#3d1515\007'
                  command ssh "$@"
                  # Reset terminal background
                  printf '\033]11;#1f2528\007'
                  ;;
              staging|174.138.88.191)
                  # Change terminal background to dark orange
                  printf '\033]11;#3d2915\007'
                  command ssh "$@"
                  # Reset terminal background
                  printf '\033]11;#1f2528\007'
                  ;;
              droplet|165.227.66.119)
                  # Change terminal background to dark green
                  printf '\033]11;#153d15\007'
                  command ssh "$@"
                  # Reset terminal background
                  printf '\033]11;#1f2528\007'
                  ;;
              *)
                  command ssh "$@"
                  ;;
          esac
      }

      # Auto-start tmux on new interactive terminal if not already inside one
      if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
        exec tmux
      fi
    '';
  };

  git = {
    enable = true;
    ignores = [ "*.swp" ];
    lfs = {
      enable = true;
    };
    settings = {
      user.name = fullName;
      user.email = email;
      init.defaultBranch = "main";
      core = {
	    editor = "vim";
        autocrlf = "input";
      };
      # Sign commits with the SSH key (id_agenix) instead of GPG: it's
      # passphraseless (no per-commit prompt) and needs no gpg-agent/pinentry.
      # Add id_agenix.pub to GitHub as a *Signing* key for the Verified badge
      # (setup.sh does this). See README "Commit signing".
      # Sign commits with SSH (not GPG) using the agenix identity key, which is
      # already present and used for GitHub auth (see ssh.settings."github.com").
      # ssh-keygen (bundled with macOS) is the signer; no gpg/pinentry needed.
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingKey = "/Users/${user}/.ssh/id_agenix.pub";
      pull.rebase = true;
      rebase.autoStash = true;
      # Always reach GitHub over SSH (using id_agenix) even when a remote is
      # configured with an https:// URL. Without this, pushing to an https
      # remote uses HTTPS auth and prompts for a username/password instead of
      # the SSH key in ssh.settings."github.com" below.
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };

  vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [ vim-airline vim-airline-themes vim-tmux-navigator ];
    settings = { ignorecase = true; };
    extraConfig = ''
      "" General
      set number
      set history=1000
      set nocompatible
      set modelines=0
      set encoding=utf-8
      set scrolloff=3
      set showmode
      set showcmd
      set hidden
      set wildmenu
      set wildmode=list:longest
      set cursorline
      set ttyfast
      set nowrap
      set ruler
      set backspace=indent,eol,start
      set laststatus=2
      " Don't use clipboard=unnamedplus, use macOS pbcopy/pbpaste instead

      " Dir stuff
      set nobackup
      set nowritebackup
      set noswapfile
      set backupdir=~/.config/vim/backups
      set directory=~/.config/vim/swap

      " Relative line numbers for easy movement
      set relativenumber
      set rnu

      "" Whitespace rules
      set tabstop=8
      set shiftwidth=2
      set softtabstop=2
      set expandtab

      "" Searching
      set incsearch
      set gdefault

      "" Statusbar
      set nocompatible " Disable vi-compatibility
      set laststatus=2 " Always show the statusline
      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1

      "" Local keys and such
      let mapleader=","
      let maplocalleader=" "

      "" Change cursor on mode
      :autocmd InsertEnter * set cul
      :autocmd InsertLeave * set nocul

      "" File-type highlighting and configuration
      syntax on
      filetype on
      filetype plugin on
      filetype indent on

      "" macOS clipboard integration
      vnoremap <Leader>. :w !pbcopy<CR><CR>
      nnoremap <Leader>, :r !pbpaste<CR>

      "" Move cursor by display lines when wrapping
      nnoremap j gj
      nnoremap k gk

      "" Map leader-q to quit out of window
      nnoremap <leader>q :q<cr>

      "" Move around split
      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      "" Easier to yank entire line
      nnoremap Y y$

      "" Move buffers
      nnoremap <tab> :bnext<cr>
      nnoremap <S-tab> :bprev<cr>

      "" Like a boss, sudo AFTER opening the file to write
      cmap w!! w !sudo tee % >/dev/null

      let g:startify_lists = [
        \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
        \ { 'type': 'sessions',  'header': ['   Sessions']       },
        \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
        \ ]

      let g:startify_bookmarks = [
        \ '~/.local/share/src',
        \ ]

      let g:airline_theme='bubblegum'
      let g:airline_powerline_fonts = 1
      '';
     };

  ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "/Users/${user}/.ssh/config_external" ];
    # Per-host config. Attribute names are Host patterns; values use OpenSSH
    # directive names (capitalized). Replaces the deprecated `matchBlocks`.
    settings = {
      "*" = {
        SendEnv = [ "LANG" "LC_*" ];
        HashKnownHosts = true;
      };
      # Offer the shared agenix key for github.com so nix can fetch the private
      # nix-secrets flake input. Plain ssh (used by nix's git fetcher) won't pick
      # id_agenix up otherwise. setup.sh writes an equivalent block during the
      # first bootstrap (before home-manager runs); this is the managed version
      # that takes over on activation.
      "github.com" = {
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = "/Users/${user}/.ssh/id_agenix";
      };
    };
  };

  tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    sensibleOnTop = false;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible  # Re-enabled with workaround below
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
           set -g @tmux_power_theme 'gold'
        '';
      }
      {
        plugin = resurrect; # Used by tmux-continuum

        # Use XDG data directory
        # https://github.com/tmux-plugins/tmux-resurrect/issues/348
        extraConfig = ''
          set -g @resurrect-dir '${config.home.homeDirectory}/.cache/tmux/resurrect'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-pane-contents-area 'visible'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5' # minutes
        '';
      }
    ];
    terminal = "screen-256color";
    prefix = "C-x";
    escapeTime = 10;
    historyLimit = 50000;
    extraConfig = ''
      # Remove Vim mode delays
      set -g focus-events on

      # Forward extended keys (kitty keyboard protocol) to apps inside tmux so
      # Shift+Enter, Ctrl+Enter, etc. are distinguishable from plain Enter.
      # csi-u format sends Shift+Enter as `\x1b[13;2u`; the default `xterm`
      # format sends `\x1b[27;2;13~`, which Claude Code / opencode mis-handle.
      set -s extended-keys always
      set -g extended-keys-format csi-u
      set -as terminal-features 'xterm*:extkeys'

      # Enable full mouse support (wheel scrolls scrollback at the prompt
      # instead of sending arrow keys)
      set -g mouse on

      # -----------------------------------------------------------------------------
      # Key bindings
      # -----------------------------------------------------------------------------

      # Unbind default keys
      unbind C-b
      unbind '"'
      unbind %

      # Split panes, vertical or horizontal
      bind-key x split-window -v
      bind-key v split-window -h

      # Move around panes with vim-like bindings (h,j,k,l)
      bind-key -n M-k select-pane -U
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-l select-pane -R

      # Smart pane switching with awareness of Vim splits.
      # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      # sesh session manager — prefix + s opens a fuzzy popup of sessions,
      # zoxide dirs, and configured projects (replaces the default session list).
      bind-key s display-popup -E -w 60% -h 50% "sesh connect \"$(
        sesh list --icons | fzf --no-sort --ansi --prompt '⚡ ' \
          --header 'sesh: switch session/project'
      )\""

      # Darwin-specific fix for tmux 3.5a with sensible plugin
      # This MUST be at the very end of the config
      set -g default-command "$SHELL"
      '';
    };
}
