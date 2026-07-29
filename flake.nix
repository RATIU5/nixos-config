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
      # Bumped to include Resource::Patch#type (required by newer homebrew-core
      # formulae like python@3.14; the old pin crashed `brew upgrade` with
      # `undefined method 'type' for an instance of Resource::Patch`).
      url = "github:Homebrew/brew/ebba6285f24fc5dc066db43cc9a0e341fd4a4ea2";
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
    # Third-party tap for omp (oh-my-pi coding agent CLI). `can1357/tap` ->
    # github.com/can1357/homebrew-tap by Homebrew convention.
    homebrew-can1357 = {
      url = "github:can1357/homebrew-tap";
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
    # Daily-updated AI coding agents. Used for pi so we track current releases
    # instead of the lagging nixpkgs pin
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
  };
  outputs = { self, darwin, nix-homebrew, brew-src, homebrew-bundle, homebrew-core, homebrew-cask, homebrew-bobrwm, homebrew-can1357, home-manager, nixpkgs, agenix, secrets, sf-mono-liga-src, llm-agents } @inputs:
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
          mkDarwin = profile: user:
            darwin.lib.darwinSystem {
              inherit system;
              specialArgs = inputs // { inherit user profile fullName email; };
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
                      # Brew 5.1.x's HOMEBREW_FORBID_PACKAGES_FROM_PATHS check
                      # rejects formulae whose realpath resolves outside
                      # Library/Taps — i.e. every nix-homebrew symlinked
                      # third-party tap ("Homebrew requires formulae to be in a
                      # tap, rejecting ... (/nix/store/...)"). Setting
                      # HOMEBREW_DEVELOPER is the only opt-out on 5.1.x; fixed
                      # properly in brew >= 6.0.1 (Homebrew/brew#22872), so
                      # remove alongside the brew-src pin.
                      HOMEBREW_DEVELOPER = "1";
                    };
                    taps = {
                      "homebrew/homebrew-core" = homebrew-core;
                      "homebrew/homebrew-cask" = homebrew-cask;
                      "homebrew/homebrew-bundle" = homebrew-bundle;
                      "bobrwm/homebrew-tap" = homebrew-bobrwm;
                      "can1357/homebrew-tap" = homebrew-can1357;
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
