# nixos-config

My macOS setup, declared with [nix-darwin](https://github.com/LnL7/nix-darwin) +
[home-manager](https://github.com/nix-community/home-manager). One script gets a
fresh Mac or VM to a fully configured machine — packages, casks, dock, shell,
git, and secrets via [agenix](https://github.com/ryantm/agenix).

## Layout

```
setup.sh              # one-shot bootstrap
flake.nix             # inputs + machines map
apps/<arch>-darwin/   # build / build-switch / rollback / clean
hosts/darwin/         # system config
modules/shared/       # cross-machine: packages, home-manager
modules/darwin/       # macOS: casks, dock, secrets
```

## Secrets, briefly

Secrets live encrypted in a private `nix-secrets` repo and are decrypted at build
time by `~/.ssh/id_agenix` — one passphraseless key that does two jobs: pulls
`nix-secrets` (it's on GitHub) and decrypts the `.age` files (it's a recipient in
`secrets.nix`). Same key on every machine, so a new machine is just "drop the key,
build." The key lives in 1Password.

## First-time setup (new machine)

```sh
git clone https://github.com/RATIU5/nixos-config.git ~/Developer/nixos-config
cd ~/Developer/nixos-config
```

Drop the shared key from 1Password (skip if you don't need secrets — use
`./setup.sh --no-secrets`):

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# paste private -> ~/.ssh/id_agenix , public -> ~/.ssh/id_agenix.pub
chmod 600 ~/.ssh/id_agenix
chmod 644 ~/.ssh/id_agenix.pub
```

Make sure GitHub knows the key as an **Authentication key** (once per key, not per
machine) — `ssh -T git@github.com` should greet you. If not:

```sh
gh ssh-key add ~/.ssh/id_agenix.pub --title "$(hostname)"
```

Add this machine to the `machines` map in `flake.nix` if your user isn't there,
then commit it (flakes ignore untracked files):

```nix
youruser = { system = "aarch64-darwin"; user = "youruser"; };  # x86_64-darwin on Intel
```

Run it:

```sh
./setup.sh
```

It installs the Xcode CLT and Nix if needed, then builds and switches.

## Updating

```sh
nix run .#build-switch   # apply config changes
nix run .#rollback       # undo to previous generation
nix run .#clean          # gc old generations
nix flake update         # bump all inputs (or `nix flake update secrets`)
```

Edit a `.nix` file → `nix run .#build-switch`. New file → `git add` it first.

## Creating the shared key (one time, ever)

Only needed when standing this up from scratch:

```sh
ssh-keygen -t ed25519 -N "" -C agenix -f ~/.ssh/id_agenix
```

Save it in 1Password, add the pubkey to GitHub, and list it as the recipient for
every secret in `nix-secrets/secrets.nix`.
