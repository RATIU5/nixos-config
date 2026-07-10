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
      # omp (oh-my-pi): AI coding agent CLI from can1357/tap (registered in
      # nix-homebrew.taps). The formula installs zsh completions itself.
      "can1357/tap/omp"
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
          # GUI apps (Zed) capture env from login shells / session vars.
          # Put cargo on PATH outside interactive zshrc so non-TTY capture works.
          sessionPath = [ "$HOME/.cargo/bin" ];
          # Ensure the screenshot target dir exists (system.defaults.screencapture.location).
          file."Pictures/Screenshots/.keep".text = "";
          # Ghostty is a Homebrew cask, which only ships the `ghostty` binary
          # inside the app bundle. Symlink it onto PATH (~/.local/bin is on PATH)
          # so the CLI (`ghostty +list-themes`, etc.) works like the old nix build.
          file.".local/bin/ghostty".source =
            config.lib.file.mkOutOfStoreSymlink "/Applications/Ghostty.app/Contents/MacOS/ghostty";
          # Login-shell / sh capture path for cargo (complements sessionPath + zshrc).
          # Conditional: rustup creates ~/.cargo/env; skip until toolchain exists.
          file.".profile".text = ''
            [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
          '';
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
        #
        # tmux is intentionally EXCLUDED: home-manager's `programs.tmux` already
        # generates ~/.config/tmux/tmux.conf (so plugins load via run-shell). It
        # sources dotfiles/config/tmux/tmux.conf for all hand-written settings, so
        # that file stays the editable source of truth without colliding with the
        # generated config.
        xdg.configFile = builtins.mapAttrs
          (name: _: { source = ../../dotfiles/config + "/${name}"; recursive = true; })
          (builtins.removeAttrs (builtins.readDir ../../dotfiles/config) [ "tmux" ]);
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib user fullName email; };
        manual.manpages.enable = false;
        # Clone and compile OLS from source against the Homebrew odin on each
        # activation. The script is a no-op when the repo is already current.
        home.activation.buildOls = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "build-ols"
            (builtins.readFile ./scripts/build-ols.sh)}
        '';
        # Install mise tools declared in dotfiles/config/mise/config.toml
        # (linked to ~/.config/mise/). Includes the rust toolchain (stable via
        # rustup). Idempotent: already-installed versions are no-ops. Network
        # required on first run; failure is non-fatal so offline switches still
        # succeed.
        home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.mise}/bin/mise install || \
            echo "warning: mise install failed (offline? network?)"
        '';
        # Second-brain Obsidian vault: clone the private repo to ~/brain on
        # first activation (no-op when it already exists). Content lives in
        # git, not Nix — nix only bootstraps the checkout.
        home.activation.cloneBrain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ ! -d "$HOME/brain/.git" ]; then
            $DRY_RUN_CMD ${pkgs.git}/bin/git clone git@github.com:RATIU5/nix-ai-brain.git "$HOME/brain" || \
              echo "warning: could not clone nix-ai-brain vault (SSH key not set up yet?)"
          fi
        '';
      };
  };
}
