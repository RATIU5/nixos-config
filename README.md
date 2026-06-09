# RATIU5' macOS Nix Config

![example](./example.png)

Reproducible **Apple Silicon macOS** setup using [nix-darwin](https://github.com/LnL7/nix-darwin) + [home-manager](https://github.com/nix-community/home-manager). Fork it, edit one file, run one script.

- Declarative packages + Homebrew casks via home-manager
- Zsh with starship, zoxide, fzf, atuin, eza, autosuggestions
- [Helix](https://helix-editor.com) pre-wired for ~25 languages (LSPs + formatters) via [mise](https://mise.jdx.dev)
- Encrypted secrets via [agenix](https://github.com/ryantm/agenix) — one passphraseless key per machine
- Catppuccin Mocha across Ghostty, Helix, Yazi, tmux, fzf, and starship

## Layout

```
config.nix            # your settings: name, email, machines (edit this)
setup.sh              # one-shot bootstrap
flake.nix             # inputs + outputs (set your secrets repo URL here)
modules/shared/       # cross-machine: packages, home-manager
modules/darwin/       # macOS: casks, dock, secrets
dotfiles/config/      # tool configs (auto-linked to ~/.config/)
```

## What's inside

<details>
<summary><strong>CLI &amp; TUI tools</strong></summary>

| Tool            | Purpose                           |
| --------------- | --------------------------------- |
| `act`           | Run GitHub Actions locally        |
| `aspell` (+en)  | Spell checker                     |
| `atuin`         | Shell history with search/sync    |
| `bat`           | `cat` with syntax highlighting    |
| `biome`         | JS/TS/JSON/CSS formatter + linter |
| `btop` / `htop` | System / process monitors         |
| `coreutils`     | GNU core utilities                |
| `delta`         | Syntax-highlighting git pager     |
| `difftastic`    | Structural diff                   |
| `direnv`        | Per-directory environments        |
| `dust`          | Disk usage analyzer               |
| `eza`           | Modern `ls`                       |
| `fd`            | Fast `find`                       |
| `ffmpeg`        | Multimedia framework              |
| `fzf`           | Fuzzy finder                      |
| `gh`            | GitHub CLI                        |
| `gitleaks`      | Secret scanner                    |
| `glow`          | Terminal markdown renderer        |
| `iftop`         | Network bandwidth monitor         |
| `jq`            | JSON processor                    |
| `lazygit`       | Git TUI                           |
| `lazydocker`    | Container TUI (podman)            |
| `macchina`      | System info fetch                 |
| `mise`          | Per-project runtime manager       |
| `mkcert`        | Local HTTPS certs                 |
| `ngrok`         | Secure tunnels                    |
| `pandoc`        | Document converter                |
| `ripgrep`       | Fast text search                  |
| `sd`            | Intuitive find/replace            |
| `sesh`          | tmux session manager              |
| `ast-grep`      | Structural code search/refactor   |
| `tmux`          | Terminal multiplexer              |
| `tree`          | Directory tree                    |
| `uv`            | Python package installer          |
| `watchexec`     | Run command on file change        |
| `wget`          | File downloader                   |
| `xh`            | Fast HTTP client                  |
| `yazi`          | File manager                      |
| `zoxide`        | Smarter `cd`                      |

</details>

<details>
<summary><strong>Editors, languages &amp; containers</strong></summary>

| Category                            | Tools                            |
| ----------------------------------- | -------------------------------- |
| Editors                             | `helix`, `zed-editor`            |
| Language runtimes (also via `mise`) | `bun`, `go`, `nodejs_24`, `odin` |
| Dev environments / containers       | `devenv`, `podman`               |

**Helix language servers & formatters:**

| Language                   | LSP                                       | Formatter                             |
| -------------------------- | ----------------------------------------- | ------------------------------------- |
| TS / JS / JSX / TSX        | `typescript-language-server`              | biome                                 |
| Astro                      | `astro-language-server`                   | biome                                 |
| Svelte                     | `svelte-language-server`                  | biome                                 |
| HTML / CSS / JSON / ESLint | `vscode-langservers-extracted`            | biome                                 |
| Tailwind / Emmet           | `tailwindcss-language-server`, `emmet-ls` | —                                     |
| YAML                       | `yaml-language-server`                    | —                                     |
| Markdown                   | `marksman`                                | —                                     |
| TOML                       | `taplo`                                   | taplo                                 |
| GraphQL                    | `graphql-language-service-cli`            | biome                                 |
| Dockerfile                 | `dockerfile-language-server`              | —                                     |
| Bash                       | `bash-language-server`                    | `shfmt` (+ `shellcheck`)              |
| Lua                        | `lua-language-server`                     | `stylua`                              |
| SQL                        | `sqls`                                    | —                                     |
| Python                     | `ruff`, `pyright`                         | ruff                                  |
| Rust                       | `rust-analyzer`                           | rustfmt (mise toolchain)              |
| PHP                        | `phpactor`                                | —                                     |
| Nix                        | `nixd`                                    | `nixpkgs-fmt` (+ `statix`, `deadnix`) |
| Go                         | `gopls`, `golangci-lint-langserver`       | gofmt                                 |
| Liquid (Shopify)           | `shopify-cli` theme LSP                   | —                                     |
| Odin                       | `ols` (built from source)                 | `odinfmt`                             |

</details>

<details>
<summary><strong>GUI apps (Homebrew casks)</strong></summary>

| Cask              | Purpose                       | Profiles  |
| ----------------- | ----------------------------- | --------- |
| `arc`             | Browser                       | all\*     |
| `zen`             | Browser                       | all\*     |
| `yaak`            | API client                    | all\*     |
| `1password`       | Password manager              | all\*     |
| `figma`           | Design                        | all\*     |
| `tailscale-app`   | Mesh VPN                      | all\*     |
| `jordanbaird-ice` | Menu-bar item manager         | all\*     |
| `stats`           | Menu-bar system monitor       | all\*     |
| `localsend`       | Cross-platform file transfer  | all\*     |
| `adguard`         | Network-wide ad blocker       | all\*     |
| `affinity`        | Design / photo editing        | all\*     |
| `homerow`         | Keyboard-driven UI navigation | all\*     |
| `raycast`         | Launcher                      | all\*     |
| `setapp`          | App subscription manager      | all\*     |
| `obsidian`        | Notes / knowledge base        | all\*     |
| `discord`         | Communication                 | all\*     |
| `zoom`            | Video conferencing            | all\*     |
| `slack`           | Work comms                    | work only |

\*all = `work` and `personal`. The `vm` profile installs no casks.

</details>

## Setup

### Forking (first time ever)

**1. Fork the repo**

Click **Fork** on GitHub, then clone your fork:

```sh
git clone https://github.com/<you>/nixos-config.git ~/Developer/nixos-config
cd ~/Developer/nixos-config
```

**2. Generate the shared SSH key**

This one key authenticates with GitHub (to pull secrets) and signs your commits. Generate it once and save both files to 1Password — you'll drop them onto every new machine.

```sh
ssh-keygen -t ed25519 -N "" -C agenix -f ~/.ssh/id_agenix
```

**3. Add the key to GitHub (two roles, same key)**

Go to GitHub → **Settings → SSH and GPG keys → New SSH key** and add `~/.ssh/id_agenix.pub` **twice**:

| Key type        | Why                                               |
| --------------- | ------------------------------------------------- |
| Authentication  | Lets GitHub pull the private `nix-secrets` repo   |
| Signing         | Gives commits the green **Verified** badge        |

**4. Create a private `nix-secrets` repo**

This repo holds your encrypted secrets (SSH keys, tokens, etc.). Create it on GitHub, then locally:

```sh
gh repo create nix-secrets --private --clone
cd ~/Developer/nix-secrets
```

Create `secrets.nix` listing `id_agenix.pub` as the recipient:

```nix
let
  key = "ssh-ed25519 AAAA...";  # contents of ~/.ssh/id_agenix.pub
in {
  "github-ssh-key.age".publicKeys = [ key ];
}
```

Encrypt your first secret (opens `$EDITOR` — paste the value, save, quit):

```sh
EDITOR=vim nix run github:ryantm/agenix -- -e github-ssh-key.age
git add -A && git commit -m "init" && git push
```

**5. Point the config at your secrets repo**

In `flake.nix`, change the `secrets` input URL:

```nix
secrets.url = "git+ssh://git@github.com/<you>/nix-secrets.git";
```

**6. Edit `config.nix`**

```nix
fullName = "Your Name";
email    = "you@example.com";  # must be a verified email on your GitHub account

machines = {
  personal = "yourmacosusername";  # run `whoami` to get this
};
```

**7. Run setup**

```sh
./setup.sh
```

Installs Xcode CLT and Nix if needed, then builds and switches. Done.

---

### New machine (already have a secrets repo)

Drop the shared key from 1Password:

```sh
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# paste private key -> ~/.ssh/id_agenix
# paste public key  -> ~/.ssh/id_agenix.pub
chmod 600 ~/.ssh/id_agenix && chmod 644 ~/.ssh/id_agenix.pub
```

Add the machine to the `machines` map in `config.nix`, then:

```sh
git clone https://github.com/<you>/nixos-config.git ~/Developer/nixos-config
cd ~/Developer/nixos-config && ./setup.sh
```

> Any new `.nix` files you create must be `git add`-ed before building — Nix flakes only see tracked files.

## Updating

```sh
nix run .#build-switch   # apply config changes
nix run .#rollback       # undo last switch
nix run .#clean          # remove old generations
nix flake update         # bump all inputs
```
