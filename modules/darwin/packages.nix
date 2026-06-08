{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # macOS-only
  # Ghostty is installed as a Homebrew cask (modules/darwin/casks.nix), not via
  # nixpkgs: home-manager symlinks .app bundles into "~/Applications/Home Manager
  # Apps", which macOS Spotlight/Launchpad won't index. The cask installs into
  # /Applications so it's discoverable, and it auto-updates.
]
