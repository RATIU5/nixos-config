{ config, pkgs, lib, home-manager, user, fullName, email, ... }:

{
  users.users.${user} = {
    name     = "${user}";
    home     = "/Users/${user}";
    isHidden = false;
    shell    = pkgs.zsh;
  };

  # Autostart bobrwm (tiling WM) at login via a per-user LaunchAgent.
  # bobrwm is a Homebrew brew -> /opt/homebrew/bin/bobrwm and runs in the
  # foreground, so launchd supervises it directly: RunAtLoad starts it at login,
  # KeepAlive restarts it if it exits/crashes. stdout+stderr go to one log file
  # (see the `bwlog` zsh helper in modules/shared/home-manager.nix).
  launchd.user.agents.bobrwm = {
    serviceConfig = {
      ProgramArguments = [ "/opt/homebrew/bin/bobrwm" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${user}/Library/Logs/bobrwm.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/bobrwm.log";
    };
  };

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
    casks  = pkgs.callPackage ./casks.nix {};
    brews = [
      # bobrwm: HEAD-only Zig tiling WM from the bobrwm/tap tap (registered in
      # nix-homebrew.taps). Builds from source on install; pulls zig as a dep.
      { name = "bobrwm/tap/bobrwm"; args = [ "HEAD" ]; }
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
          stateVersion = "23.11";
        };
        # Auto-link every entry in dotfiles/config/ -> ~/.config/<entry>. Drop a
        # file or folder under dotfiles/config/ and `git add` it — no per-file
        # wiring needed. Copied into the Nix store (Option B: reproducible; edit
        # then `nix run .#build-switch`). recursive = true links files one-by-one
        # so apps can still write sibling state into the directory.
        xdg.configFile = builtins.mapAttrs
          (name: _: { source = ../../dotfiles/config + "/${name}"; recursive = true; })
          (builtins.readDir ../../dotfiles/config);
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib user fullName email; };
        manual.manpages.enable = false;
      };
  };
}
