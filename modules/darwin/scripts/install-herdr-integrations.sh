#!/usr/bin/env bash
# Install Herdr's official Pi agent-state extension into ~/.pi.
# Idempotent: herdr rewrites the extension file when missing or stale.
# Non-fatal when herdr is not on PATH yet (e.g. before first build-switch).
set -euo pipefail

export PATH="${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

HERDR_BIN="$(command -v herdr 2>/dev/null || true)"
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
