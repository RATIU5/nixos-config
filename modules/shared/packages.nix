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
  bat # Cat clone with syntax highlighting
  biome # Web toolchain (formatter/linter)
  btop # System monitor and process viewer
  coreutils # Basic file/text/shell utilities
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

  # Language toolchains
  bun # JavaScript runtime / package manager
  go # Go
  nodejs_24 # Node.js (includes npm)
  odin # Odin language compiler

  # Editors
  helix # Modal terminal editor
  zed-editor # Zed editor

  # Dev environments / containers
  devenv # Reproducible per-project dev shells
  podman # Daemonless container engine
] ++ myFonts
