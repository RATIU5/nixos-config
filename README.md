# nixos-config (macOS / nix-darwin)

Personal, declarative macOS configuration built on
[nix-darwin](https://github.com/LnL7/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager), using Nix Flakes.

A single command (`./setup.sh`) takes a fresh Mac — or a fresh macOS VM — from
nothing to a fully configured machine: packages, Homebrew casks, dock, shell,
git, and encrypted secrets (SSH keys, GPG signing key) via
[agenix](https://github.com/ryantm/agenix).

> Based on [dustinlyons/nixos-config](https://github.com/dustinlyons/nixos-config),
> trimmed to macOS only and wired to a private `nix-secrets` repo.

---

## Contents

- [What you need before you start](#what-you-need-before-you-start)
- [TL;DR — set up a new machine](#tldr--set-up-a-new-machine)
- [Step by step](#step-by-step)
- [How secrets work (read this once)](#how-secrets-work-read-this-once)
- [First-time setup (creating the shared key + secrets)](#first-time-setup-creating-the-shared-key--secrets)
- [Daily use](#daily-use)
- [Managing secrets](#managing-secrets)
- [Repository layout](#repository-layout)
- [Troubleshooting](#troubleshooting)

---

## What you need before you start

| Thing | Why | Where |
|---|---|---|
| A Mac (Apple Silicon or Intel) or a macOS VM | The target | — |
| Internet access | Downloads Nix + packages | — |
| A GitHub account with access to the config + `nix-secrets` repos | To clone them | github.com/RATIU5 |
| **The shared agenix key** (`id_agenix`, *passphraseless*) | Decrypts your secrets; also pulls the private `nix-secrets` repo | **1Password** → "agenix shared key" |
| (Optional) the GPG signing key | Signed git commits | 1Password |

You do **not** need to install anything by hand first. `setup.sh` installs the
Xcode Command Line Tools and Nix for you. The only thing you must supply is the
**shared key**, and only if you want secrets.

> [!IMPORTANT]
> The shared `id_agenix` **must have no passphrase**. agenix decrypts
> non-interactively at every build; a passphrase would break that. See
> [How secrets work](#how-secrets-work-read-this-once).

---

## TL;DR — set up a new machine

```sh
# 1. Get the repo
git clone https://github.com/RATIU5/nixos-config.git ~/Developer/nixos-config
cd ~/Developer/nixos-config

# 2. (secrets machines only) drop the shared key from 1Password, then:
#    paste private -> ~/.ssh/id_agenix , public -> ~/.ssh/id_agenix.pub
mkdir -p ~/.ssh && chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_agenix
chmod 644 ~/.ssh/id_agenix.pub

# 3. Make sure this machine is in the flake (add an entry if missing — see Step 4)

# 4. Run it
./setup.sh
```

Want to try the machine **without** secrets first? `./setup.sh --no-secrets`.

---

## Step by step

### 1. Clone the repo

```sh
git clone https://github.com/RATIU5/nixos-config.git ~/Developer/nixos-config
cd ~/Developer/nixos-config
```

HTTPS is used here so you can clone before any SSH key exists.

### 2. Place the shared agenix key (skip if using `--no-secrets`)

`setup.sh` uses `~/.ssh/id_agenix` both to decrypt secrets and to pull the
private `nix-secrets` flake input. Get it from 1Password:

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# paste the PRIVATE key body into:
#   ~/.ssh/id_agenix
# paste the PUBLIC key line into:
#   ~/.ssh/id_agenix.pub
chmod 600 ~/.ssh/id_agenix
chmod 644 ~/.ssh/id_agenix.pub
```

> [!WARNING]
> If the private key file isn't `chmod 600`, SSH silently ignores it and you'll
> get `Permission denied (publickey)`. This is the #1 gotcha.

If you skip this step, `setup.sh` will **generate a brand-new** `id_agenix`.
That new key is *not* a recipient of your existing secrets, so secrets won't
decrypt until you register it (the per-host path — avoid it; use the shared key).

### 3. Register the key with GitHub (once per key, not per machine)

The shared key's public half must be on the GitHub account that owns
`nix-secrets`, so Nix can pull it over SSH. If you reuse the same shared key
everywhere, this is already done. To confirm:

```sh
ssh -T git@github.com    # expect: "Hi RATIU5! You've successfully authenticated"
```

If it fails, add the key (needs the `gh` CLI, or do it in the GitHub web UI):

```sh
gh ssh-key add ~/.ssh/id_agenix.pub --title "$(hostname) $(date +%Y-%m)"
```

### 4. Make sure this machine is in `flake.nix`

The build picks a config by matching your **username** against the `machines`
map in `flake.nix`. If your user isn't there, add it and commit (Nix flakes only
see git-tracked files):

```nix
# flake.nix → machines = { ... }
yourusername = { system = "aarch64-darwin"; user = "yourusername"; };
# use "x86_64-darwin" on Intel
```

```sh
git add flake.nix && git commit -m "add machine: yourusername"
```

> You can override detection without editing the flake:
> `MACHINE=<label> ./setup.sh`.

### 5. Run the bootstrap

```sh
./setup.sh
```

What it does, in order:

1. Installs **Xcode Command Line Tools** (gives you `git`). If it has to install
   them, accept the GUI prompt and re-run `./setup.sh`.
2. Installs **Nix** via the Determinate Systems installer (if not present), and
   loads it into the current shell.
3. Ensures `~/.ssh/id_agenix` exists (generates one only if missing).
4. **Secrets registration prompt:** prints the SSH public key and the machine's
   age recipient, then waits. With the **shared key already in place and on
   GitHub, both are already done — just press Enter.** (The prompt exists for
   the per-host model; you're using the shared model.)
5. Resolves your config label from the `machines` map.
6. Runs `nix run .#build-switch` to build and activate the system.

When it finishes, open a new terminal to pick up the new environment.

---

## How secrets work (read this once)

Secrets (your GitHub SSH key, GPG signing key, etc.) live **encrypted** in a
separate private repo, `nix-secrets`, as `*.age` files. agenix decrypts them at
build time and places them on disk (e.g. `~/.ssh/id_github`).

Two facts drive everything:

1. **To fetch `nix-secrets`,** Nix needs an SSH key authorized on GitHub.
2. **To decrypt the `.age` files,** the machine needs a private key whose public
   half is listed as a *recipient* in `nix-secrets/secrets.nix`. This is
   cryptographic — no token or password manager can substitute.

This repo uses **one shared key for both jobs**: `~/.ssh/id_agenix`.
- It's on GitHub → fetch works.
- It's the recipient in `secrets.nix` → decrypt works on every machine that has
  the file.

That's why a new machine is just "drop the key, build." Because the *same* key
is a recipient everywhere, you **never edit `secrets.nix` or re-encrypt** when
adding a machine.

> [!NOTE]
> **Bootstrap chicken-and-egg:** one of the secrets *is* a GitHub SSH key
> (`id_github`). You can't decrypt it until you've already pulled `nix-secrets`,
> which needs a key. That's why you place the shared `id_agenix` by hand first —
> it breaks the cycle. After the first build, agenix manages the rest.

**Trade-off:** the shared-key model is simple but means one key decrypts
everything. If you'd rather compartmentalize per machine, use per-host keys —
but then every new machine requires adding its recipient to `secrets.nix` and
**re-encrypting every secret** (`agenix -r`). This repo is set up for the shared
model.

The decrypt identity is configured in
[`modules/darwin/secrets.nix`](modules/darwin/secrets.nix) (`age.identityPaths`).

---

## First-time setup (creating the shared key + secrets)

Do this **once, ever** — the first time you stand up this config, before any new
machine can use the shared-key flow.

### 1. Create the shared agenix key (passphraseless)

```sh
ssh-keygen -t ed25519 -N "" -C "agenix" -f ~/.ssh/id_agenix
chmod 600 ~/.ssh/id_agenix
```

Save **both** `id_agenix` and `id_agenix.pub` in 1Password ("agenix shared
key"). Add the public key to GitHub: `gh ssh-key add ~/.ssh/id_agenix.pub`.

### 2. Create the private `nix-secrets` repo

A private GitHub repo named `nix-secrets` with a `secrets.nix` at its root:

```nix
let
  shared = "ssh-ed25519 AAAA...   agenix";   # contents of id_agenix.pub
in {
  "github-ssh-key.age".publicKeys     = [ shared ];
  "github-signing-key.age".publicKeys = [ shared ];
}
```

> agenix takes the SSH public key line **directly** as a recipient — no
> `age1...` conversion needed.

### 3. Create each secret

Encrypt your real key material to the `.age` files. The `EDITOR="cp <file>"`
trick fills the temp file from an existing plaintext file, then agenix encrypts
it:

```sh
cd ~/Developer/nix-secrets

# GitHub SSH key (delivered to ~/.ssh/id_github on hosts)
EDITOR="cp $HOME/.ssh/id_github" \
  nix run github:ryantm/agenix -- -i ~/.ssh/id_agenix -e github-ssh-key.age

# GPG signing key — export it first (passphraseless), then encrypt
nix shell nixpkgs#gnupg -c gpg --batch --passphrase '' \
  --quick-generate-key "Your Name <you@example.com>" ed25519 sign 0
nix shell nixpkgs#gnupg -c gpg --export-secret-keys --armor you@example.com > /tmp/pgp_github.key
EDITOR="cp /tmp/pgp_github.key" \
  nix run github:ryantm/agenix -- -i ~/.ssh/id_agenix -e github-signing-key.age
rm /tmp/pgp_github.key
```

Also upload the GPG **public** key at github.com/settings/keys → GPG keys
(no title field; identity comes from the key). The email in the key must be a
**verified** email on your GitHub account.

```sh
nix shell nixpkgs#gnupg -c gpg --export --armor you@example.com   # paste into GitHub
```

### 4. Commit, push, point the flake at it

```sh
cd ~/Developer/nix-secrets && git add -A && git commit -m "init secrets" && git push
cd ~/Developer/nixos-config
nix flake update secrets    # re-lock to the new nix-secrets commit
nix run .#build-switch
```

> [!NOTE]
> If you're *re-keying* and an `.age` file already exists but can no longer be
> decrypted (e.g. lost passphrase), **delete the file first** (`rm
> github-ssh-key.age`) so agenix creates it fresh instead of trying to decrypt
> the old one.

---

## Daily use

```sh
nix run .#build          # build only, don't switch (dry check)
nix run .#build-switch   # build and activate
nix run .#rollback       # revert to the previous generation
nix run .#clean          # garbage-collect old generations

nix flake update         # update all inputs
nix flake update secrets # update just the secrets input
nix flake check          # validate the flake
```

After editing **any** `.nix` file: `nix run .#build-switch`.
After adding **any new file**: `git add` it first — flakes ignore untracked
files.

---

## Managing secrets

Add a new secret:

1. In `nix-secrets/secrets.nix`, add `"thing.age".publicKeys = [ shared ];`.
2. `EDITOR=vim nix run github:ryantm/agenix -- -e thing.age` (write, save).
3. Reference it in `modules/darwin/secrets.nix` under `age.secrets`.
4. Commit/push `nix-secrets`, then `nix flake update secrets && nix run .#build-switch`.

Rotate / re-key all secrets to the recipients in `secrets.nix`:

```sh
cd ~/Developer/nix-secrets
nix run github:ryantm/agenix -- -r -i ~/.ssh/id_agenix
```

---

## Repository layout

```
.
├── setup.sh                 # one-command bootstrap for a fresh machine
├── flake.nix                # inputs + machines map + darwinConfigurations
├── apps/<arch>-darwin/      # build / build-switch / rollback / clean scripts
├── hosts/darwin/            # macOS system configuration
└── modules/
    ├── shared/              # cross-machine: packages, home-manager, fonts
    └── darwin/              # macOS: packages, casks, dock, secrets, home-manager
```

See [CLAUDE.md](CLAUDE.md) for a deeper map of the modules and conventions.

---

## Troubleshooting

**`experimental Nix feature 'nix-command' is disabled`**
Flakes/`nix-command` aren't enabled. `setup.sh` passes the flag itself, but for
manual `nix` commands either enable it permanently:
```sh
mkdir -p ~/.config/nix
printf 'experimental-features = nix-command flakes\n' >> ~/.config/nix/nix.conf
```
or prefix each call — the flag goes **right after `nix`**:
```sh
nix --extra-experimental-features 'nix-command flakes' run .#build-switch
```

**`git@github.com: Permission denied (publickey)`** when fetching `secrets`
The shared key isn't usable. Check, in order:
```sh
ls -l ~/.ssh/id_agenix                 # exists?
chmod 600 ~/.ssh/id_agenix             # perms must be 600, or SSH ignores it
ssh -T git@github.com                   # "Hi RATIU5!" = good
```
If still denied, the public key isn't on the GitHub account:
`gh ssh-key add ~/.ssh/id_agenix.pub`.

**`age: error: no identity matched any of the recipients`**
agenix tried to decrypt an existing `.age` file with a key that isn't one of its
recipients. Either supply the right identity (`-i ~/.ssh/id_agenix`), or if the
old file is unrecoverable, `rm` it and re-create the secret fresh.

**SSH key asks for a passphrase / agenix can't decrypt unattended**
The agenix key must be **passphraseless**. Generate a new one with
`ssh-keygen -t ed25519 -N "" ...`, add it as a recipient, re-key, and update
`age.identityPaths`.

**`No machine in flake.nix matches user '<you>'`**
Add your user to the `machines` map in `flake.nix`, `git add flake.nix`, and
re-run — or `MACHINE=<label> ./setup.sh`.

**`error: Path 'overlays' does not exist in Git repository`**
Stale reference to a removed overlays loader. This config no longer uses
`overlays/`; make sure `modules/shared/default.nix` doesn't read that path.

**`error: Unexpected files in /etc, aborting activation`** /
**`Build user group has mismatching GID`**
macOS/Nix install edge cases. Follow the linked guidance in the
[Determinate Systems Sequoia notes](https://determinate.systems/posts/nix-support-for-macos-sequoia/);
for the `/etc` case, move the named files aside (append `.before-nix-darwin`)
and re-run.
</content>
</invoke>
