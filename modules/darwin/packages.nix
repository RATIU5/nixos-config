{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # macOS-only
  dockutil # Manage icons in the dock
  ghostty-bin # Ghostty terminal (source build is broken on Darwin; use prebuilt)
]
