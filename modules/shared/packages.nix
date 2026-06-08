{ pkgs, ... }:
let
  myFonts = import ./fonts.nix { inherit pkgs; };
in
with pkgs; [
  # Secrets management (agenix)
  age # File encryption tool agenix builds on
  ssh-to-age # Convert SSH keys to age recipients/identities

  # TUI / CLI tools
  act # Run GitHub Actions locally
  aspell # Spell checker
  aspellDicts.en # English dictionary for aspell
  atuin # Shell history with sync/search
  bat # Cat clone with syntax highlighting
  biome # Web toolchain (formatter/linter)
  btop # System monitor and process viewer
  coreutils # Basic file/text/shell utilities
  delta # Syntax-highlighting pager for git diffs
  difftastic # Structural diff tool
  direnv # Per-directory environment variables (wired via programs.direnv)
  dust # Disk usage analyzer
  eza # Modern ls replacement
  fd # Fast find alternative
  ffmpeg # Multimedia framework
  fzf # Fuzzy finder
  gh # GitHub CLI
  gitleaks # Secret scanner
  glow # Markdown renderer for terminal
  htop # Interactive process viewer
  iftop # Network bandwidth monitor
  jq # JSON processor
  killall # Kill processes by name
  lazygit # Terminal UI for git
  macchina # Fast system info fetch (neofetch/fetch aliases)
  mise # Polyglot runtime/version manager (activated in home-manager.nix initContent)
  mkcert # Local HTTPS certificates
  ngrok # Secure tunneling service
  openssh # SSH client and server
  pandoc # Document converter
  ripgrep # Fast text search tool
  # starship is installed via programs.starship in home-manager.nix
  tmux # Terminal multiplexer
  tree # Directory tree viewer
  unzip # ZIP archive extractor
  uv # Python package installer
  wget # File downloader
  yazi # Terminal file manager
  # zoxide is installed via programs.zoxide in home-manager.nix

  # Workflow / dev TUIs
  sesh # tmux session manager (fzf + zoxide-aware project jumper)
  lazydocker # Container TUI (works with podman via DOCKER_HOST)
  ast-grep # Structural code search/refactor (`sg`)
  sd # Intuitive find/replace (sed without the line-noise)
  watchexec # Run a command on file change
  xh # Fast HTTP client (httpie-like)

  # Language toolchains
  bun # JavaScript runtime / package manager
  go # Go
  nodejs_24 # Node.js (includes npm)
  odin # Odin language compiler (pinned to stable nixpkgs via overlay — see modules/shared/default.nix)

  # Editors
  helix # Modal terminal editor
  zed-editor # Zed editor

  # Dev environments / containers
  devenv # Reproducible per-project dev shells
  podman # Daemonless container engine

  # Language servers & formatters (for Helix). Language *runtimes* (node, go,
  # python, rust, ...) are managed per-project by mise; these are the editor
  # tooling that Helix auto-wires once the binaries are on PATH.
  # -- LSPs --
  typescript-language-server # JS / TS / JSX / TSX
  astro-language-server # Astro
  svelte-language-server # Svelte
  vscode-langservers-extracted # HTML / CSS / JSON / ESLint
  emmet-ls # Emmet expansion in markup
  tailwindcss-language-server # Tailwind class IntelliSense
  yaml-language-server # YAML
  marksman # Markdown
  taplo # TOML (LSP + formatter)
  graphql-language-service-cli # GraphQL
  dockerfile-language-server # Dockerfile
  bash-language-server # Bash
  lua-language-server # Lua
  sqls # SQL
  ruff # Python: LSP (`ruff server`) + linter + formatter
  pyright # Python: type checking
  rust-analyzer # Rust LSP (toolchain itself via `mise use rust@...`)
  phpactor # PHP
  nixd # Nix (smarter than nil for flakes)
  # ols (Odin LSP) omitted: nixpkgs build is broken against current Odin.
  # Build from source against the Homebrew odin on PATH (versions match):
  #   git clone https://github.com/DanielGavin/ols ~/.local/share/ols
  #   cd ~/.local/share/ols && ./build.sh && ./odinfmt.sh
  #   ln -sf ~/.local/share/ols/{ols,odinfmt} ~/.local/bin/
  # OLS_BUILTIN_FOLDER is exported in home-manager.nix; odinfmt is wired as the
  # Odin formatter in dotfiles/config/helix/languages.toml.
  gopls # Go
  golangci-lint-langserver # Go linting (referenced in languages.toml)
  shopify-cli # Shopify Liquid: `shopify theme language-server`
  # -- Formatters / linters --
  oxlint # Fast JS/TS linter (oxc); LSP not yet in nixpkgs
  stylua # Lua formatter
  shfmt # Shell formatter
  shellcheck # Shell linter
  nixpkgs-fmt # Nix formatter
  statix # Nix linter (also run in CI)
  deadnix # Nix dead-code linter
  # biome (JS/TS/JSON/CSS format+lint) already listed above
] ++ myFonts
