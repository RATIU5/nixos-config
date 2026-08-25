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

  # Fuzzy finder + completion engine. enableZshIntegration wires CTRL-T (files)
  # and ALT-C (cd), plus fuzzy tab-completion for cd/kill/ssh. CTRL-R is left
  # to Atuin (historyWidget.command = "" so they don't fight).
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
    fileWidget = {
      command = "fd --type f --hidden --follow --exclude .git";
      options = [
        "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      ];
    };
    changeDirWidget.command = "fd --type d --hidden --follow --exclude .git";
    # Atuin owns CTRL-R; empty command disables fzf's history binding.
    historyWidget.command = "";
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
    plugins = [ ];
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

      # zsh's NOMATCH (on by default) errors out a whole command line when an
      # unquoted arg contains glob chars ('?', '*', '[', etc.) with no local
      # filesystem match — a constant trap for pasting URLs with query
      # strings (webapp https://x.com/y?z=1). Disable it so those pass
      # through literally instead of aborting, matching bash's default
      # behavior.
      unsetopt nomatch

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
      # on Apple SDK 26). It needs its builtin/ folder pointed to explicitly
      # since the binary is symlinked onto PATH. See modules/shared/packages.nix.
      export OLS_BUILTIN_FOLDER="$HOME/.local/share/ols/builtin"

      # The Nix-packaged Shopify CLI tries to download cloudflared into its
      # own (read-only) store path when `shopify app dev` starts a tunnel.
      # Pointing it at the nixpkgs cloudflared skips that download.
      export SHOPIFY_CLI_CLOUDFLARED_PATH="${pkgs.cloudflared}/bin/cloudflared"

      # Define PATH variables
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      # Legacy npm global prefix (kept for any older tools).
      export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.composer/vendor/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/.local/share/src/conductly/bin:$PATH
      export PATH=$HOME/.local/share/src/conductly/utils:$PATH
      export PYTHONPATH="$HOME/.local-pip/packages:$PYTHONPATH"
      # bun global CLIs (ctxio, openspec, …) — prefer over ~/.npm-packages
      export PATH="$HOME/.cache/.bun/bin:$PATH"
      export PATH="$HOME/.nub/bin:$PATH"
      # nub's `install -g` links bins into pnpm's standard macOS global dir
      # (~/Library/pnpm), not ~/.nub/bin itself -- e.g. `nub install -g pake-cli`.
      export PNPM_HOME="$HOME/Library/pnpm"
      export PATH="$PNPM_HOME:$PATH"

      # Rust toolchain (from project `mise install` or manual rustup) lands here.
      export PATH="$HOME/.cargo/bin:$PATH"
      export PATH="/opt/homebrew/bin:$PATH"
      export PATH="$HOME/.opencode/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      [ -d "$HOME/.cache/.bun/bin" ] && export PATH="$HOME/.cache/.bun/bin:$PATH"

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

      # contextio: local LLM proxy (log + redact). Ensures the background
      # proxy is up, then runs the real pi. Bypass with CONTEXTIO_DISABLED=1
      # or `command pi`. Proxy itself: ctxio proxy status|stop|monitor.
      # NOTE: do not use `ctxio proxy -d` — v0.3.0 drops --redact flags.
      ensure-contextio() {
        if command -v ensure-contextio-proxy >/dev/null 2>&1; then
          ensure-contextio-proxy >/dev/null 2>&1 || true
        elif command -v ctxio >/dev/null 2>&1; then
          # Fallback: start with full flags via node entry (same as helper).
          if ! ctxio proxy status 2>/dev/null | grep -Eqi 'running \(pid'; then
            local entry
            entry="$(command -v ctxio 2>/dev/null || true)"
            if [[ -z "$entry" || ! -f "$entry" ]]; then
              for candidate in \
                "$HOME/.cache/.bun/install/global/node_modules/@contextio/cli/dist/main.js" \
                "$HOME/.npm-packages/lib/node_modules/@contextio/cli/dist/main.js"
              do
                [[ -f "$candidate" ]] && entry="$candidate" && break
              done
            fi
            if [[ -n "$entry" && -f "$entry" ]]; then
              local preset="''${CONTEXTIO_REDACT_PRESET:-pii}"
              local max="''${CONTEXTIO_LOG_MAX_SESSIONS:-50}"
              mkdir -p "$HOME/.contextio"
              # Allow x-target-url (used by xAI routing) from localhost only.
              CONTEXT_PROXY_ALLOW_TARGET_OVERRIDE=1 \
                nohup node "$entry" proxy --port 4040 --log-max-sessions "$max" --redact --redact-preset "$preset" \
                >>"$HOME/.contextio/proxy.log" 2>&1 &
              echo "{\"pid\":$!,\"port\":4040,\"startedAt\":\"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"}" >"$HOME/.contextio/background.json"
            fi
          fi
        fi
      }
      pi() {
        if [[ "''${CONTEXTIO_DISABLED:-0}" != "1" ]]; then
          ensure-contextio
        fi
        command pi "$@"
      }

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

      # ---------------------------------------------------------------------
      # webapp - package a website as a native desktop app, via Pake
      #
      #   webapp <url> [name]     build a desktop app for a URL
      #   webapp -l               list apps you've built
      #
      # Backed by Pake (https://github.com/tw93/Pake): a Rust/Tauri CLI that
      # compiles a real, tiny (~5MB) native .app around the system webview.
      # No AppleScript, no UI automation, no Accessibility/Automation
      # permissions -- just a CLI build with a stable --json result.
      #
      # Requires: npm install -g pake-cli
      #   (needs Node 20.9+; pake offers to install a Rust toolchain itself
      #   the first time cargo is missing)
      #
      # Builds happen in a scratch dir; only the finished .app is moved into
      # /Applications (falls back to ~/Applications if that's not writable --
      # Finder and Launchpad only look in /Applications, not ~/Applications,
      # so this is what makes the app show up there instead of just Spotlight
      # and Raycast). A small TSV registry (webapp -l) tracks what's built.
      # ---------------------------------------------------------------------

      webapp() {
        local url="$1"
        local name="$2"

        case "$url" in
          -l | --list)
            _webapp_list
            return $?
            ;;
          "" | -h | --help)
            command cat <<'USAGE'
      Usage: webapp <url> [name]
             webapp -l

      Packages a website (or a local static build) as a native desktop app in
      /Applications, using Pake (https://github.com/tw93/Pake) -- a Rust/Tauri
      CLI that compiles a real, tiny (~5MB) app around the system webview.
      Launch it from Launchpad, Raycast, Spotlight, or Finder by name.

        webapp https://app.asana.com
        webapp app.asana.com Asana
        webapp https://mail.google.com "Gmail"
        webapp ./dist MyTool          # local static build (needs index.html)

      Name is optional for a URL -- left off, it's derived from the hostname.
      Google OAuth and similar SSO flows can reject the embedded webview; that's
      a Pake/webview limitation, not something this function can fix.

      Requires: npm install -g pake-cli
        (needs Node 20.9+; pake offers to install a Rust toolchain itself the
        first time cargo is missing)
      USAGE
            return 1
            ;;
        esac

        if [ "$(uname -s)" != "Darwin" ]; then
          printf 'webapp: macOS only\n' >&2
          return 1
        fi

        if ! command -v pake >/dev/null 2>&1; then
          printf 'webapp: pake-cli is not installed.\n' >&2
          printf '  npm install -g pake-cli\n' >&2
          return 4
        fi

        if ! command -v jq >/dev/null 2>&1; then
          printf 'webapp: jq is required to parse pake --json output.\n' >&2
          return 4
        fi

        case "$url" in
          http://* | https://*) ;;
          *)
            if [ -e "$url" ]; then
              :
            else
              url="https://$url"
            fi
            ;;
        esac

        if [ -z "$name" ]; then
          case "$url" in
            http://* | https://*)
              name="$(printf '%s\n' "$url" | sed -E 's#^[a-z]+://##; s#/.*##; s#^www\.##; s#\..*##')"
              ;;
            *)
              name="$(basename "$url")"
              ;;
          esac
          name="$(printf '%s' "$name" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
        fi

        # /Applications is drwxrwxr-x root:admin on a normal Mac, so any admin
        # user (the default account type) can write there without sudo. Fall
        # back to ~/Applications (Spotlight/Raycast still find it there) if not.
        local appdir="/Applications"
        [ -w "$appdir" ] || appdir="$HOME/Applications"
        mkdir -p "$appdir"

        local registry="$XDG_DATA_HOME/webapp/registry.tsv"
        mkdir -p "$(dirname "$registry")"

        local builddir
        builddir="$(mktemp -d "''${TMPDIR:-/tmp}/webapp-build.XXXXXX")" || {
          printf 'webapp: could not create a temp build directory\n' >&2
          return 1
        }

        printf 'Building "%s" from %s ...\n' "$name" "$url" >&2
        _webapp_do_build "$url" "$name" "$builddir" "$registry" "$appdir"
        local rc=$?
        rm -rf "$builddir"
        return "$rc"
      }

      # Runs pake, parses its --json contract, moves the result into $appdir,
      # and records it in the registry. Split out from webapp() so the caller
      # can guarantee the temp build dir is always cleaned up.
      _webapp_do_build() {
        local url="$1" name="$2" builddir="$3" registry="$4" appdir="$5"

        # NOTE: not named "status" -- zsh reserves that as a read-only alias
        # for $?, and `local status` fails with "read-only variable: status".
        local result pakestatus
        result="$(cd "$builddir" && pake "$url" --name "$name" --targets app --json 2>/dev/null)"
        pakestatus=$?

        if [ -z "$result" ] || ! printf '%s' "$result" | jq -e . >/dev/null 2>&1; then
          printf 'webapp: pake produced no usable JSON output (exit %d).\n' "$pakestatus" >&2
          printf '  Re-run without --json to see the full build log:\n' >&2
          printf '  cd "%s" && pake "%s" --name "%s" --targets app\n' "$builddir" "$url" "$name" >&2
          [ "$pakestatus" -eq 0 ] && pakestatus=1
          return "$pakestatus"
        fi

        local ok
        ok="$(printf '%s' "$result" | jq -r '.ok')"
        if [ "$ok" != "true" ]; then
          local code msg hint
          code="$(printf '%s' "$result" | jq -r '.error.code // "UNKNOWN"')"
          msg="$(printf '%s' "$result" | jq -r '.error.message // "no message"')"
          hint="$(printf '%s' "$result" | jq -r '.error.hint // empty')"
          printf 'webapp: build failed (%s): %s\n' "$code" "$msg" >&2
          [ -n "$hint" ] && printf '  hint: %s\n' "$hint" >&2
          [ "$pakestatus" -eq 0 ] && pakestatus=1
          return "$pakestatus"
        fi

        local outpath
        outpath="$(printf '%s' "$result" | jq -r '[.outputs[] | select(.format=="app")][0].path // .outputs[0].path // empty')"

        if [ -z "$outpath" ] || [ ! -e "$outpath" ]; then
          printf 'webapp: pake reported success but no output file was found.\n' >&2
          printf '%s\n' "$result" >&2
          return 1
        fi

        local appname target
        appname="$(basename "$outpath")"
        target="$appdir/$appname"
        if [ "$outpath" != "$target" ]; then
          rm -rf "$target"
          mv -f "$outpath" "$target" && outpath="$target"
        fi

        printf 'Created %s\n' "$outpath"
        printf '%s\t%s\t%s\t%s\n' "$name" "$url" "$outpath" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$registry"

        local warnings
        warnings="$(printf '%s' "$result" | jq -r '.warnings[]?' 2>/dev/null)"
        [ -n "$warnings" ] && printf 'webapp: warnings:\n%s\n' "$warnings" >&2

        printf 'Launch it from Raycast or Spotlight as "%s".\n' "$name"
      }

      # List apps previously built by webapp, from its registry file.
      _webapp_list() {
        local registry="$XDG_DATA_HOME/webapp/registry.tsv"
        if [ ! -s "$registry" ]; then
          printf 'No webapp-built apps found.\n' >&2
          return 1
        fi

        local name url path createdAt found=0
        while IFS=$'\t' read -r name url path createdAt; do
          [ -n "$name" ] || continue
          [ -e "$path" ] || continue
          printf '%-24s %-45s %s\n' "$name" "$url" "$path"
          found=1
        done <"$registry"

        [ "$found" -eq 1 ] || printf 'No webapp-built apps found (registry entries no longer exist on disk).\n' >&2
      }

      # Auto-start herdr only in a real interactive TTY (regular terminal
      # windows: Ghostty, Terminal.app, iTerm, …). Skip IDE-embedded terminals,
      # non-TTY GUI env capture (Zed, etc.), and anything already inside herdr.
      if command -v herdr &>/dev/null \
        && [[ -o interactive ]] \
        && [[ -t 0 ]] \
        && [[ -z "''${HERDR_ENV:-}" ]] \
        && [[ -z "''${HERDR_PANE_ID:-}" ]] \
        && [[ -z "''${TMUX:-}" ]] \
        && [[ ! "$TERM" =~ screen ]] \
        && [[ ! "$TERM" =~ tmux ]] \
        && [[ "''${TERM_PROGRAM:-}" != "vscode" ]] \
        && [[ "''${TERM_PROGRAM:-}" != "cursor" ]] \
        && [[ -z "''${VSCODE_INJECTION:-}" ]] \
        && [[ -z "''${INSIDE_EMACS:-}" ]]; then
        exec herdr
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
    plugins = with pkgs.vimPlugins; [ vim-airline vim-airline-themes ];
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

}
