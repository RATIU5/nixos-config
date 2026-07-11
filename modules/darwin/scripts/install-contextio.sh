#!/usr/bin/env bash
# Install @contextio/cli into ~/.npm-packages (already on PATH via home-manager).
# Idempotent: re-runs `npm install -g` which is a no-op when already current.
set -euo pipefail

export PATH="/opt/homebrew/bin:${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/bin:/bin:$PATH"

NPM_PREFIX="${HOME}/.npm-packages"
mkdir -p "$NPM_PREFIX"

if ! command -v npm >/dev/null 2>&1; then
  echo "[contextio] npm not found — skipping install" >&2
  exit 0
fi

# Pin version so activation is reproducible across machines.
CONTEXTIO_VERSION="${CONTEXTIO_VERSION:-0.3.0}"

if ! npm install -g --prefix "$NPM_PREFIX" "@contextio/cli@${CONTEXTIO_VERSION}"; then
  echo "[contextio] warning: npm install failed (offline? network?)" >&2
  exit 0
fi

export PATH="${NPM_PREFIX}/bin:$PATH"
if command -v ctxio >/dev/null 2>&1; then
  echo "[contextio] installed $(ctxio --version 2>/dev/null || echo ctxio) at ${NPM_PREFIX}"
else
  echo "[contextio] warning: ctxio binary missing after install" >&2
fi

# Install the ensure-proxy helper next to other user bins so the shell wrapper
# can call it. Source lives next to this script in the Nix store when activated,
# and next to this file in the repo during manual runs.
BIN_DIR="${HOME}/.local/bin"
mkdir -p "$BIN_DIR"
ENSURE_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ensure-contextio-proxy.sh"
if [[ -f "$ENSURE_SRC" ]]; then
  cp -f "$ENSURE_SRC" "${BIN_DIR}/ensure-contextio-proxy"
  chmod +x "${BIN_DIR}/ensure-contextio-proxy"
fi
