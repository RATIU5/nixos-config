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
        # Auto-link every top-level entry under dotfiles/config/ into ~/.config/.
        # herdr config lives at dotfiles/config/herdr/config.toml.
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
        # Install mise tools declared in dotfiles/config/mise/config.toml
        # (linked to ~/.config/mise/). Includes the rust toolchain (stable via
        # rustup). Idempotent: already-installed versions are no-ops. Network
        # required on first run; failure is non-fatal so offline switches still
        # succeed.
        # Retry once: aqua/github backends hit transient network/rate-limit
        # failures that a second attempt clears. reshim afterwards so new tools
        # (e.g. herdr) get a PATH shim without a manual `mise reshim`.
        home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.mise}/bin/mise install \
            || $DRY_RUN_CMD ${pkgs.mise}/bin/mise install \
            || echo "warning: mise install failed (offline? network?)"
          $DRY_RUN_CMD ${pkgs.mise}/bin/mise reshim || true
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
        # Sync pi (earendil-works) agent config from dotfiles/pi into ~/.pi.
        # Writable copies so `bun install` and runtime state (auth, sessions)
        # can live alongside managed files. Skips personal MCP endpoints and
        # the opencode-cloudflare extension from the reference tree.
        # herdr-agent-state.ts is owned by `herdr integration install pi` and
        # is preserved by the sync script.
        # ${../../dotfiles/pi} is a path literal so Nix copies it into the store
        # and the activation script always sees a frozen snapshot.
        home.activation.syncPiConfig =
          let
            # Path literal coerced into a string → copied into the Nix store.
            piSrc = "${../../dotfiles/pi}";
            syncScript = pkgs.writeShellScript "sync-pi-config"
              (builtins.replaceStrings [ "@piSrc@" ] [ piSrc ]
                (builtins.readFile ./scripts/sync-pi-config.sh));
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            export PATH="${lib.getBin pkgs.bun}/bin:${lib.getBin pkgs.coreutils}/bin:$PATH"
            $DRY_RUN_CMD ${syncScript}
          '';
        # Install Herdr's Pi lifecycle/session integration after the pi tree
        # is synced (extensions dir must exist) and mise has had a chance to
        # install the herdr binary. Re-runs on every switch so a herdr upgrade
        # refreshes the bundled extension.
        home.activation.installHerdrIntegrations = lib.hm.dag.entryAfter [ "syncPiConfig" "miseInstall" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "install-herdr-integrations"
            (builtins.readFile ./scripts/install-herdr-integrations.sh)}
        '';
        # Install @contextio/cli (LLM API proxy with redaction) via bun -g,
        # then ensure a background proxy is running so pi (via contextio-proxy.ts)
        # can route anthropic/openai/google/xai through it.
        home.activation.installContextio = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "install-contextio"
            (builtins.readFile ./scripts/install-contextio.sh)}
        '';
        home.activation.ensureContextioProxy = lib.hm.dag.entryAfter [ "installContextio" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "ensure-contextio-proxy"
            (builtins.readFile ./scripts/ensure-contextio-proxy.sh)}
        '';
        # Install OpenSpec CLI via bun -g and seed global pi skills/prompts
        # (~/.pi/agent/{skills,prompts}) so /opsx-* works without per-project
        # init. Project-local `openspec init --tools pi` still creates openspec/.
        home.activation.installOpenSpec = lib.hm.dag.entryAfter [ "syncPiConfig" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "install-openspec"
            (builtins.readFile ./scripts/install-openspec.sh)}
        '';
      };
  };
}
