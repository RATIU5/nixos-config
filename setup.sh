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
# Skip agenix/secrets entirely (first-boot testing before nix-secrets is wired):
#   ./setup.sh --no-secrets
#
set -euo pipefail

NO_SECRETS=0
for a in "$@"; do
  case "$a" in
    --no-secrets) NO_SECRETS=1 ;;
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

# 3. SSH identity (agenix decrypts with ~/.ssh/id_ed25519) -----------------
KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
  info "Generating SSH key at $KEY ..."
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -f "$KEY"
fi
ok "SSH key present"

# 4. Show what must be registered before secrets can decrypt ---------------
if [ "$NO_SECRETS" -eq 1 ]; then
  info "Skipping secrets setup (--no-secrets); building the agenix-free variant."
else
  AGE_RECIPIENT="$($NIX run nixpkgs#ssh-to-age -- < "$KEY.pub" 2>/dev/null || true)"
  echo
  info "Before building, register this machine:"
  echo "  1) Add the SSH PUBLIC key to GitHub (to pull the private nix-secrets input):"
  echo "       $(cat "$KEY.pub")"
  if [ -n "$AGE_RECIPIENT" ]; then
    echo "  2) Add this age recipient to nix-secrets/secrets.nix and re-encrypt:"
    echo "       $AGE_RECIPIENT"
  else
    echo "  2) Add this machine's age recipient to nix-secrets/secrets.nix:"
    echo "       run:  nix run nixpkgs#ssh-to-age < $KEY.pub"
  fi
  echo
  pause "Press Enter once both are done (or Ctrl-C to stop)... "
fi

# 5. Resolve the config label (same logic as the build scripts) ------------
ME="$(whoami)"
if [ -z "${MACHINE:-}" ]; then
  # `|| true` so a no-match (empty result) doesn't trip `set -e` silently.
  MACHINE="$($NIX eval --raw .#machines \
    --apply 'ms: let m = builtins.filter (n: ms.${n}.user == "'"$ME"'") (builtins.attrNames ms); in if m == [] then "" else builtins.head m' 2>/dev/null || true)"
fi
if [ -z "$MACHINE" ]; then
  printf "${RED}No machine in flake.nix matches user '%s'.${NC}\n" "$ME" >&2
  printf "${YELLOW}Add an entry to the machines map in flake.nix, e.g.:${NC}\n" >&2
  printf "    %s = { system = \"aarch64-darwin\"; user = \"%s\"; };\n" "$ME" "$ME" >&2
  printf "${YELLOW}then commit it (git add flake.nix) and re-run. Or override: MACHINE=<label> ./setup.sh${NC}\n" >&2
  exit 1
fi
ok "Using config label: $MACHINE"

# 6. Build and switch ------------------------------------------------------
BUILD_ARGS=""
[ "$NO_SECRETS" -eq 1 ] && BUILD_ARGS="--no-secrets"
info "Running build-switch ${BUILD_ARGS}..."
MACHINE="$MACHINE" $NIX run .#build-switch -- $BUILD_ARGS

ok "Done. Open a new terminal to pick up the new environment."
