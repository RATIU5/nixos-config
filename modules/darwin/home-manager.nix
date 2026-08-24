{ config, pkgs, lib, home-manager, user, profile, fullName, email, ... }:

{
  users.users.${user} = {
    name     = "${user}";
    home     = "/Users/${user}";
    isHidden = false;
    shell    = pkgs.zsh;
  };

  # bobrwm (tiling WM) is installed as a Homebrew cask (Bobrwm.app). Set
  # `.start_at_login = true` in dotfiles/config/bobrwm/config.zon so the app
  # registers its bundled LaunchAgent; config is copied to a real file on
  # activation (see installBobrwmConfig) because the GUI cannot read nix-store
  # symlinks reliably.

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
    # Keep brew formulae in sync with the pinned homebrew-core flake input on
    # every `build-switch`. Without this, bumping homebrew-core is a no-op for
    # already-installed formulae (e.g. odin stays on an old dev-YYYY-MM version
    # while OLS builds against master and starts referencing newer tokens).
    onActivation = {
      autoUpdate = false;   # formula versions are pinned via the flake input
      upgrade    = true;    # ...so upgrade to whatever that pin resolves to
      cleanup    = "none";
    };
    casks  = pkgs.callPackage ./casks.nix { inherit profile; };
    brews = [
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

  # bobrwm/tap ships a disabled stub formula and a cask with the same name;
  # brew bundle fetch resolves the clash as a formula and fails. Install the
  # cask directly after bundle instead (see activationScripts.homebrew below).
  system.activationScripts.homebrew.text = lib.mkAfter (
    lib.optionalString (profile != "vm") ''
      if [ -f /opt/homebrew/bin/brew ]; then
        if sudo --preserve-env=PATH --user=${user} --set-home \
          env HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew list --cask bobrwm/tap/bobrwm &>/dev/null; then
          echo "bobrwm cask already installed — skipping" >&2
        else
          echo "installing bobrwm cask..." >&2
          sudo --preserve-env=PATH --user=${user} --set-home \
            env HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew install --cask bobrwm/tap/bobrwm
        fi
      fi
    ''
  );

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
          # Bobrwm cask symlinks bobrwm-cli → bobrwm under /opt/homebrew/bin;
          # mirror onto ~/.local/bin for shells and activation scripts that skip
          # the full login PATH.
          file.".local/bin/bobrwm".source =
            config.lib.file.mkOutOfStoreSymlink "/Applications/Bobrwm.app/Contents/MacOS/bobrwm-cli";
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
        # bobrwm is excluded: Bobrwm.app needs a real config file (see
        # installBobrwmConfig). herdr config lives at dotfiles/config/herdr/config.toml.
        xdg.configFile =
          let
            configEntries = builtins.removeAttrs (builtins.readDir ../../dotfiles/config) [ "bobrwm" ];
          in
          builtins.mapAttrs
            (name: _: { source = ../../dotfiles/config + "/${name}"; recursive = true; })
            configEntries;
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib user fullName email; };
        manual.manpages.enable = false;
        # Clone and compile OLS from source against the Homebrew odin on each
        # activation. The script is a no-op when the repo is already current.
        home.activation.buildOls = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "build-ols"
            (builtins.readFile ./scripts/build-ols.sh)}
        '';
        # Copy bobrwm config to ~/.config/bobrwm/config.zon (real file, not a
        # nix-store symlink) and reload when Bobrwm.app is already running.
        home.activation.installBobrwmConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${pkgs.writeShellScript "install-bobrwm-config"
            (builtins.replaceStrings [ "@configSrc@" ] [ "${../../dotfiles/config/bobrwm/config.zon}" ]
              (builtins.readFile ./scripts/install-bobrwm-config.sh))}
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
        # is synced (extensions dir must exist). Re-runs on every switch so a
        # herdr upgrade refreshes the bundled extension.
        home.activation.installHerdrIntegrations = lib.hm.dag.entryAfter [ "syncPiConfig" ] ''
          export PATH="${lib.makeBinPath [ pkgs.herdr ]}:$PATH"
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
        # Install nub (JS runtime/tooling) via upstream curl installer into
        # ~/.nub/bin. PATH is managed in home-manager zshrc, not shell profiles.
        home.activation.installNub = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export PATH="${pkgs.curl}/bin:$PATH"
          $DRY_RUN_CMD ${pkgs.writeShellScript "install-nub"
            (builtins.readFile ./scripts/install-nub.sh)}
        '';
      };
  };
}
