#!/usr/bin/env bash
# Install Herdr's official Pi agent-state extension into ~/.pi.
# Idempotent: herdr rewrites the extension file when missing or stale.
# Non-fatal when herdr is not on PATH yet (first install race / offline).
set -euo pipefail

# mise shims first (declarative install path), then Homebrew / local bins.
export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

HERDR_BIN="$(command -v herdr 2>/dev/null || true)"
# Fallback: mise installs herdr even when the shim isn't activated yet
# (e.g. config just landed mid-activation). Prefer the versioned binary.
if [[ -z "$HERDR_BIN" ]]; then
  for candidate in \
    "${HOME}/.local/share/mise/installs/herdr/latest/herdr" \
    "${HOME}/.local/share/mise/installs/herdr/0/herdr"
  do
    if [[ -x "$candidate" ]]; then
      HERDR_BIN="$candidate"
      break
    fi
  done
fi
if [[ -z "$HERDR_BIN" ]]; then
  echo "[herdr] binary not found on PATH — skipping integration install" >&2
  exit 0
fi

# Extensions dir must exist before herdr will write the plugin.
mkdir -p "${HOME}/.pi/agent/extensions"

if ! "$HERDR_BIN" integration install pi; then
  echo "[herdr] warning: 'integration install pi' failed" >&2
  exit 0
fi

echo "[herdr] pi integration installed"
