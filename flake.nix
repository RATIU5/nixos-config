{
  description = "macOS (nix-darwin) configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, agenix, secrets } @inputs:
    let
      # Per-machine identity. The attribute name (work/personal) is what you
      # select with `nix run .#build-switch`; `user` must match the real macOS account.
      machines = {
        work     = { system = "aarch64-darwin"; user = "john.memmott"; };
        personal = { system = "aarch64-darwin"; user = "ratiu5"; };
        vm       = { system = "aarch64-darwin"; user = "admin"; }; # test VM
      };
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs darwinSystems f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git age age-plugin-yubikey ];
          shellHook = with pkgs; ''
            export EDITOR=vim
          '';
        };
      };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName} "$@"
        '')}/bin/${scriptName}";
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "clean" = mkApp "clean" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };
    in
    {
      # Exposed so the build scripts can resolve $(whoami) -> config label.
      inherit machines;
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
      darwinConfigurations =
        let
          mkDarwin = { system, user, enableSecrets }:
            darwin.lib.darwinSystem {
              inherit system;
              specialArgs = inputs // { inherit user enableSecrets; };
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
          # For each machine: the normal config, plus a `<label>-no-secrets`
          # variant that skips agenix (for first-boot testing).
          withSecrets = nixpkgs.lib.mapAttrs
            (_: m: mkDarwin (m // { enableSecrets = true; })) machines;
          noSecrets = nixpkgs.lib.mapAttrs'
            (name: m: nixpkgs.lib.nameValuePair "${name}-no-secrets"
              (mkDarwin (m // { enableSecrets = false; }))) machines;
        in
        withSecrets // noSecrets;
    };
}
