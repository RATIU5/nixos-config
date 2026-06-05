{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [
  # macOS-only
  ghostty-bin # Ghostty terminal (source build is broken on Darwin; use prebuilt)
]
