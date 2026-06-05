{
  description = "macOS (nix-darwin) configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pinned stable nixpkgs used only for `odin` — the unstable build pulls
    # LLVM18 compiler-rt that fails against apple-sdk-26.4 / libc++21.
    nixpkgs-odin.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    agenix.url = "github:ryantm/agenix";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    secrets = {
      url = "git+ssh://git@github.com/RATIU5/nix-secrets.git";
      flake = false;
    };
  };
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, nixpkgs-odin, agenix, secrets } @inputs:
    let
      # All personal settings (name, email, machines) live in config.nix —
      # edit that one file to make this repo yours.
      userConfig = import ./config.nix;
      inherit (userConfig) machines fullName email;
      # Apple Silicon only.
      system = "aarch64-darwin";
      forAllSystems = f: nixpkgs.lib.genAttrs [ system ] f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
      };
      mkApp = scriptName: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName} "$@"
        '')}/bin/${scriptName}";
      };
      mkDarwinApps = _: {
        "build" = mkApp "build";
        "build-switch" = mkApp "build-switch";
        "clean" = mkApp "clean";
        "rollback" = mkApp "rollback";
      };
    in
    {
      # Exposed so the build scripts can resolve $(whoami) -> config label.
      inherit machines;
      devShells = forAllSystems devShell;
      apps = forAllSystems mkDarwinApps;
      darwinConfigurations =
        let
          mkDarwin = user:
            darwin.lib.darwinSystem {
              inherit system;
              specialArgs = inputs // { inherit user fullName email; };
              modules = [
                home-manager.darwinModules.home-manager
                nix-homebrew.darwinModules.nix-homebrew
                {
                  nix-homebrew = {
                    inherit user;
                    enable = true;
                    taps = {
                      "homebrew/homebrew-core" = homebrew-core;
                      "homebrew/homebrew-cask" = homebrew-cask;
                      "homebrew/homebrew-bundle" = homebrew-bundle;
                    };
                    mutableTaps = false;
                    autoMigrate = true;
                  };
                }
                ./hosts/darwin
              ];
            };
        in
        nixpkgs.lib.mapAttrs (_: user: mkDarwin user) machines;
    };
}
