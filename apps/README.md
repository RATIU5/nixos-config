# Apps

The [apps](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-run#apps)
in this directory are Nix installables wired up by the `mkApp` function in
`flake.nix`. They target Apple Silicon (`aarch64-darwin`) only.

Run them with `nix run .#<name>` (`build`, `build-switch`, `clean`, `rollback`).
