{ config, pkgs, lib, home-manager, user, profile, fullName, email, ... }:

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
      # odin: latest-release bottle. The nixpkgs build breaks on Apple SDK 26
      # (compiler-rt-libc-18 fails); Homebrew tracks current odin and is what
      # OLS is built from source against (see modules/shared/packages.nix).
      # `brew upgrade odin` to update both together.
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
        # gh/hosts.yml is intentionally NOT managed here. `gh auth login` stores
        # its OAuth token in that file, so it must stay writable — a read-only
        # Nix-store symlink makes auth fail with "permission denied". Because the
        # auto-linker uses recursive = true, ~/.config/gh is a real directory, so
        # gh creates and owns hosts.yml itself on first login. The static
        # settings in dotfiles/config/gh/config.yml are still linked below.
        xdg.configFile = builtins.mapAttrs
          (name: _: { source = ../../dotfiles/config + "/${name}"; recursive = true; })
          (builtins.readDir ../../dotfiles/config);
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib user fullName email; };
        manual.manpages.enable = false;
        # Clone and compile OLS from source against the Homebrew odin on each
        # activation. The script is a no-op when the repo is already current.
        home.activation.buildOls = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "build-ols"
            (builtins.readFile ./scripts/build-ols.sh)}
        '';
      };
  };
}
