{ config, pkgs, nixpkgs-odin, ... }:

{

  nixpkgs = {
    # Pull odin from pinned stable nixpkgs (unstable build is broken on the new SDK).
    overlays = [
      (final: prev: {
        odin = nixpkgs-odin.legacyPackages.${prev.stdenv.hostPlatform.system}.odin;
      })
    ];
    config = {
      allowUnfree = true;
      #cudaSupport = true;
      #cudaCapabilities = ["8.0"];
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };
  };
}
