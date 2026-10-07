#!/usr/bin/env bash
# Install the global Vite+ CLI (`vp`) via the upstream curl installer into
# ~/.vite-plus (VP_HOME pins the single-root layout so PATH is predictable).
# Idempotent: skips when already installed; upgrade with `vp upgrade`.
# Shell rc files are home-manager symlinks, so the installer's rc edits fail
# harmlessly; PATH is managed in home-manager zshrc instead.
# Network required on first install.
set -euo pipefail

export PATH="/opt/homebrew/bin:${HOME}/.local/bin:/usr/bin:/bin:$PATH"

export VP_HOME="${VP_HOME:-$HOME/.vite-plus}"
VP_BIN="${VP_HOME}/bin/vp"

if [[ -x "$VP_BIN" ]]; then
  echo "[vite-plus] already installed at $VP_BIN ($("$VP_BIN" --version 2>/dev/null | head -n1 || echo vp))"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "[vite-plus] curl not found — skipping install" >&2
  exit 0
fi

# CI=true makes the installer non-interactive. Keep existing Node.js and
# package managers (mise/bun/pnpm) instead of Vite+ shims; flip later with
# `vp env on`.
export CI=true
export VP_NODE_MANAGER=no
export VP_PM_MANAGER=no

if ! curl -fsSL https://vite.plus | bash; then
  echo "[vite-plus] warning: install failed (offline? network?)" >&2
fi

if [[ -x "$VP_BIN" ]]; then
  echo "[vite-plus] installed $("$VP_BIN" --version 2>/dev/null | head -n1 || echo vp) ($VP_BIN)"
else
  echo "[vite-plus] warning: vp binary missing after install" >&2
fi
