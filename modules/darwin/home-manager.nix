{ config, pkgs, lib, home-manager, user, profile, fullName, email, githubUser, ... }:

{
  users.users.${user} = {
    name     = "${user}";
    home     = "/Users/${user}";
    isHidden = false;
    shell    = pkgs.zsh;
  };

  # bobrwm (tiling WM) manages its own launchd agent via `bobrwm service
  # install/start/stop`. Run those once manually; no Nix LaunchAgent here to
  # avoid a competing second instance.

  homebrew = {
    # This is a module from nix-darwin
    # Homebrew is *installed* via the flake input nix-homebrew

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    enable = true;
    casks  = pkgs.callPackage ./casks.nix { inherit profile; };
    brews = [
      # bobrwm: HEAD-only Zig tiling WM from the bobrwm/tap tap (registered in
      # nix-homebrew.taps). Builds from source on install; pulls zig as a dep.
      { name = "bobrwm/tap/bobrwm"; args = [ "HEAD" ]; }
      # odin: latest-release bottle. The nixpkgs build breaks on the new Apple
      # SDK; Homebrew tracks current odin and stays in sync with ols master
      # (built from source in setup.sh). `brew upgrade odin` to update.
      "odin"
    ];
    #masApps = {
    #  "hidden-bar"   = 1452453066;
    #  "wireguard"    = 1451685025;
    #};
  };

  home-manager = {
    useGlobalPkgs = true;
    # On a fresh machine, pre-existing dotfiles (the bootstrap ~/.ssh/config from
    # setup.sh, stock shell rc files, etc.) would otherwise make activation abort
    # with "would be clobbered". Back them up instead so the first switch succeeds.
    backupFileExtension = "hm-backup";
    users.${user} = { pkgs, config, lib, ... }:
      {
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix {};
          # Ensure the screenshot target dir exists (system.defaults.screencapture.location).
          file."Pictures/Screenshots/.keep".text = "";
          # Ghostty is a Homebrew cask, which only ships the `ghostty` binary
          # inside the app bundle. Symlink it onto PATH (~/.local/bin is on PATH)
          # so the CLI (`ghostty +list-themes`, etc.) works like the old nix build.
          file.".local/bin/ghostty".source =
            config.lib.file.mkOutOfStoreSymlink "/Applications/Ghostty.app/Contents/MacOS/ghostty";
          stateVersion = "23.11";
        };
        # Auto-link every entry in dotfiles/config/ -> ~/.config/<entry>. Drop a
        # file or folder under dotfiles/config/ and `git add` it — no per-file
        # wiring needed. Copied into the Nix store (Option B: reproducible; edit
        # then `nix run .#build-switch`). recursive = true links files one-by-one
        # so apps can still write sibling state into the directory.
        xdg.configFile = (builtins.mapAttrs
          (name: _: { source = ../../dotfiles/config + "/${name}"; recursive = true; })
          (builtins.readDir ../../dotfiles/config))
        # gh CLI host file is generated from config.nix (githubUser) rather than
        # checked in, so a fork doesn't ship someone else's username.
        // {
          "gh/hosts.yml".text = ''
            github.com:
                git_protocol: https
                users:
                    ${githubUser}:
                user: ${githubUser}
          '';
        };
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib user fullName email; };
        manual.manpages.enable = false;
      };
  };
}
