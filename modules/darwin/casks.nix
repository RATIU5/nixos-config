{ lib, profile, ... }:

lib.optionals (profile != "vm") ([
  # Browsers (Safari is built-in)
  "arc"
  "zen"

  # Dev tools
  "ghostty" # GPU-accelerated terminal (cask so Spotlight/Launchpad index it)
  "zed" # Code editor (cask so Spotlight/Launchpad/Raycast index it)
  "yaak" # OSS API client (Insomnia alternative)

  # Utilities
  "1password"
  "figma"
  "tailscale-app"
  "jordanbaird-ice" # Ice — menu-bar item manager
  "stats" # Menu-bar system monitor
  "localsend" # AirDrop-style cross-platform file transfer
  "adguard" # Network-wide ad blocker

  # Design / SEO
  "affinity"

  # Productivity
  "homerow" # Keyboard-driven UI navigation
  "raycast"
  "setapp"
  "obsidian" # Notes / knowledge base

  # Communication
  "discord"
  "zoom"
]
++ lib.optionals (profile == "work") [
  "slack" # Work comms (work profile only)
])
