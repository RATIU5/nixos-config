#!/usr/bin/env bash
#
# Bootstrap a fresh macOS machine with this nix-darwin config.
#
# Usage (from a cloned checkout):
#   ./setup.sh
#
# Override the auto-detected config label:
#   MACHINE=personal ./setup.sh
#
# Requires the shared agenix key at ~/.ssh/id_agenix BEFORE running (drop it
# from 1Password — see the README). Secrets are mandatory; the build won't
# proceed without it.
set -euo pipefail

for a in "$@"; do
  case "$a" in
    *) printf "Unknown argument: %s\n" "$a" >&2; exit 1 ;;
  esac
done

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
info()  { printf "${YELLOW}==> %s${NC}\n" "$1"; }
ok()    { printf "${GREEN}✓ %s${NC}\n" "$1"; }
die()   { printf "${RED}✗ %s${NC}\n" "$1" >&2; exit 1; }
pause() { printf "${YELLOW}%s${NC}" "$1"; read -r _; }

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# 0. Hardware guard — Apple Silicon macOS only --------------------------------
[ "$(uname -s)" = "Darwin" ] || die "This config is macOS only (got $(uname -s))."
[ "$(uname -m)" = "arm64" ]  || die "This config supports Apple Silicon (arm64) Macs only; got $(uname -m)."
NIX="nix --extra-experimental-features nix-command --extra-experimental-features flakes"

# 1. Xcode Command Line Tools (provides git) -------------------------------
if ! xcode-select -p >/dev/null 2>&1; then
  info "Installing Xcode Command Line Tools (accept the GUI prompt, then re-run)..."
  xcode-select --install || true
  die "Re-run ./setup.sh once Command Line Tools finish installing."
fi
ok "Xcode Command Line Tools present"

# 2. Nix (Determinate installer; config sets nix.enable = false) -----------
if ! command -v nix >/dev/null 2>&1; then
  info "Installing Nix (Determinate Systems installer)..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  # Load nix into the current shell so the rest of the script can use it.
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
command -v nix >/dev/null 2>&1 || die "nix not on PATH — open a new terminal and re-run ./setup.sh"
ok "Nix available"

# 3. SSH identity (agenix decrypts with ~/.ssh/id_agenix) ------------------
# This is the shared key. It must already be in place — drop it from 1Password
# before running. We refuse to generate one: a fresh key can't decrypt the
# existing secrets, so an auto-generated key would only cause a confusing build
# failure later.
KEY="$HOME/.ssh/id_agenix"
if [ ! -f "$KEY" ]; then
  die "Missing $KEY. Drop the shared agenix key (private + .pub) from 1Password into ~/.ssh first — see the README, then re-run."
fi
ok "Shared agenix key present"

# 3b. Ensure ssh offers id_agenix for github.com -------------------------------
# Nix's git fetch uses plain ssh, which won't offer id_agenix unless ~/.ssh/config
# says to. On a fresh Mac there's no default key to fall back on, so the build
# fails with "Permission denied (publickey)". Add the block once, idempotently.
SSH_CONFIG="$HOME/.ssh/config"
if [ ! -f "$SSH_CONFIG" ] || ! grep -qE '^[[:space:]]*Host[[:space:]]+github\.com([[:space:]]|$)' "$SSH_CONFIG"; then
  info "Adding github.com -> id_agenix block to $SSH_CONFIG"
  mkdir -p "$HOME/.ssh"
  cat >> "$SSH_CONFIG" <<'EOF'

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_agenix
  IdentitiesOnly yes
EOF
  chmod 600 "$SSH_CONFIG"
  ok "ssh config updated"
else
  ok "ssh config already has a github.com entry"
fi

# 4. Sanity-check that the key can reach GitHub for the private nix-secrets input
echo
info "Checking GitHub access for the shared key (needed to pull nix-secrets)..."
if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -qi "successfully authenticated"; then
  ok "GitHub recognises the key"
else
  info "Could not confirm GitHub auth for $KEY. If the build fails to fetch"
  info "nix-secrets, add the public key to GitHub as an Authentication key:"
  echo "       $(cat "$KEY.pub")"
  pause "Press Enter to continue anyway (or Ctrl-C to stop)... "
fi

# 5. Resolve the config label (same logic as the build scripts) ------------
ME="$(whoami)"
if [ -z "${MACHINE:-}" ]; then
  # `|| true` so a no-match (empty result) doesn't trip `set -e` silently.
  MACHINE="$($NIX eval --raw .#machines \
    --apply 'ms: let m = builtins.filter (n: ms.${n} == "'"$ME"'") (builtins.attrNames ms); in if m == [] then "" else builtins.head m' 2>/dev/null || true)"
fi
if [ -z "$MACHINE" ]; then
  printf "${RED}No machine in config.nix matches user '%s'.${NC}\n" "$ME" >&2
  printf "${YELLOW}Add an entry to the machines map in config.nix, e.g.:${NC}\n" >&2
  printf "    %s = \"%s\";\n" "$ME" "$ME" >&2
  printf "${YELLOW}then commit it (git add config.nix) and re-run. Or override: MACHINE=<label> ./setup.sh${NC}\n" >&2
  exit 1
fi
ok "Using config label: $MACHINE"

# 6. Move stock /etc files aside so nix-darwin can take them over ----------
# On a fresh Mac these are Apple's defaults; nix-darwin refuses to overwrite
# files it didn't create. Back them up once so the first activation succeeds.
for f in /etc/bashrc /etc/zshrc /etc/zprofile /etc/bash.bashrc /etc/nix/nix.conf; do
  if [ -e "$f" ] && [ ! -e "$f.before-nix-darwin" ]; then
    info "Backing up $f -> $f.before-nix-darwin"
    sudo mv "$f" "$f.before-nix-darwin"
  fi
done

# nix-homebrew (mutableTaps = false) wants to own this dir; move a pre-existing
# one aside so it can manage taps itself.
TAPS="/opt/homebrew/Library/Taps"
if [ -e "$TAPS" ] && [ ! -L "$TAPS" ] && [ ! -e "$TAPS.before-nix-darwin" ]; then
  info "Backing up $TAPS -> $TAPS.before-nix-darwin"
  sudo mv "$TAPS" "$TAPS.before-nix-darwin"
fi

# 7. Build and switch ------------------------------------------------------
info "Running build-switch..."
MACHINE="$MACHINE" $NIX run .#build-switch

# 8. Odin language server (ols) -------------------------------------------------
# nixpkgs' ols build is broken against current Odin, so we build it from source
# against the Homebrew odin installed by build-switch (both track the latest
# release, so they stay in sync). Idempotent and non-fatal: a failure here
# doesn't abort the bootstrap.
# Make sure the freshly-installed odin is reachable in this shell.
export PATH="/run/current-system/sw/bin:/opt/homebrew/bin:$HOME/.nix-profile/bin:$HOME/.local/bin:$PATH"
OLS_DIR="$HOME/.local/share/ols"
if ! command -v odin >/dev/null 2>&1; then
  info "odin not on PATH in this shell — skipping ols build. Open a new terminal and re-run ./setup.sh, or build ols manually (see modules/shared/packages.nix)."
elif [ -x "$HOME/.local/bin/ols" ]; then
  ok "ols already installed"
else
  info "Building Odin language server (ols) from source..."
  if [ ! -d "$OLS_DIR/.git" ]; then
    git clone --depth 1 https://github.com/DanielGavin/ols "$OLS_DIR"
  fi
  if ( cd "$OLS_DIR" && ./build.sh && ./odinfmt.sh ); then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$OLS_DIR/ols" "$HOME/.local/bin/ols"
    ln -sf "$OLS_DIR/odinfmt" "$HOME/.local/bin/odinfmt"
    ok "ols + odinfmt installed to ~/.local/bin"
  else
    info "ols build failed — build it manually later (see modules/shared/packages.nix note)."
  fi
fi

# 9. Register id_agenix as a GitHub SSH *signing* key (Verified commits) -------
# Commits are signed with ~/.ssh/id_agenix (gpg.format=ssh, set in home-manager
# git config). GitHub tracks auth and signing keys separately, so the same key
# must be added a second time with type=signing to get the green Verified badge.
# Best-effort and idempotent: needs an authenticated gh (installed by build-switch).
echo
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if gh ssh-key add "$HOME/.ssh/id_agenix.pub" --type signing --title "$(hostname -s)-signing" 2>/dev/null; then
    ok "Registered id_agenix.pub as a GitHub signing key"
  else
    ok "GitHub signing key already present"
  fi
else
  info "gh not authenticated — to get Verified commits, add the signing key once:"
  info "  gh auth login && gh ssh-key add ~/.ssh/id_agenix.pub --type signing"
fi

ok "Done. Open a new terminal to pick up the new environment."
