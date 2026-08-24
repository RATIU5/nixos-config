#!/usr/bin/env bash
# Install nub via the upstream curl installer (bins under ~/.nub/bin).
# Idempotent: skips when already installed; re-run after removing ~/.nub to
# reinstall. Network required on first install.
set -euo pipefail

export PATH="/opt/homebrew/bin:${HOME}/.local/share/mise/shims:${HOME}/.cache/.bun/bin:${HOME}/.local/bin:/usr/bin:/bin:$PATH"

NUB_INSTALL_DIR="${NUB_INSTALL_DIR:-$HOME/.nub}"
NUB_BIN="${NUB_INSTALL_DIR}/bin/nub"

if [[ -x "$NUB_BIN" ]]; then
  echo "[nub] already installed at $NUB_BIN ($("$NUB_BIN" --version 2>/dev/null || echo nub))"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "[nub] curl not found — skipping install" >&2
  exit 0
fi

export NUB_NO_MODIFY_PATH=1
export NUB_INSTALL_DIR

if ! curl -fsSL https://nubjs.com/install.sh | bash; then
  echo "[nub] warning: install failed (offline? network?)" >&2
  exit 0
fi

export PATH="${NUB_INSTALL_DIR}/bin:$PATH"
if command -v nub >/dev/null 2>&1; then
  echo "[nub] installed $(nub --version 2>/dev/null || echo nub) ($(command -v nub))"
else
  echo "[nub] warning: nub binary missing after install" >&2
fi
