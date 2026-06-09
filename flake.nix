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
    # Override the Homebrew CLI source. nix-homebrew pins brew 5.1.11, which
    # has no macOS 27 ("Golden Gate") support and dies with
    # `unknown or unsupported macOS version: :dunno`. Pinned to the head of
    # Homebrew PR #22592 (preliminary macOS 27 support). Drop this override and
    # the nix-homebrew.package line below once that lands in a tagged release.
    brew-src = {
      url = "github:Homebrew/brew/7750fa03645dc7b72f35dfde2d766bea3b006866";
      flake = false;
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
    # Third-party tap for bobrwm (HEAD-only Zig tiling WM). `bobrwm/tap` ->
    # github.com/bobrwm/homebrew-tap by Homebrew convention.
    homebrew-bobrwm = {
      url = "github:bobrwm/homebrew-tap";
      flake = false;
    };
    secrets = {
      url = "git+ssh://git@github.com/RATIU5/nix-secrets.git";
      flake = false;
    };
    # SFMono patched with Nerd Font glyphs + FiraCode ligatures.
    sf-mono-liga-src = {
      url = "github:shaunsingh/SFMono-Nerd-Font-Ligaturized";
      flake = false;
    };
  };
  outputs = { self, darwin, nix-homebrew, brew-src, homebrew-bundle, homebrew-core, homebrew-cask, homebrew-bobrwm, home-manager, nixpkgs, agenix, secrets, sf-mono-liga-src } @inputs:
    let
      # All personal settings (name, email, machines) live in config.nix —
      # edit that one file to make this repo yours.
      userConfig = import ./config.nix;
      inherit (userConfig) machines fullName email githubUser;
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
          mkDarwin = profile: user:
            darwin.lib.darwinSystem {
              inherit system;
              specialArgs = inputs // { inherit user profile fullName email githubUser; };
              modules = [
                home-manager.darwinModules.home-manager
                nix-homebrew.darwinModules.nix-homebrew
                {
                  nix-homebrew = {
                    inherit user;
                    enable = true;
                    # See the brew-src input above (macOS 27 support).
                    package = inputs.brew-src // {
                      name = "brew-5.1.15-macos27";
                      version = "5.1.15";
                    };
                    # The newer brew (from brew-src) defaults
                    # HOMEBREW_REQUIRE_TAP_TRUST=true, which refuses to load
                    # formulae from third-party taps (e.g. bobrwm/tap) until
                    # `brew trust`ed. nix-homebrew runs brew non-interactively,
                    # so opt out declaratively. Tied to the brew-src override;
                    # remove both together.
                    extraEnv = {
                      HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
                    };
                    taps = {
                      "homebrew/homebrew-core" = homebrew-core;
                      "homebrew/homebrew-cask" = homebrew-cask;
                      "homebrew/homebrew-bundle" = homebrew-bundle;
                      "bobrwm/homebrew-tap" = homebrew-bobrwm;
                    };
                    mutableTaps = false;
                    autoMigrate = true;
                  };
                }
                ./hosts/darwin
              ];
            };
        in
        nixpkgs.lib.mapAttrs (profile: user: mkDarwin profile user) machines;
    };
}
