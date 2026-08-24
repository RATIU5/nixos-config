#!/usr/bin/env bash
# Deploy bobrwm config as a real file under ~/.config/bobrwm/config.zon.
# Bobrwm.app (GUI) cannot reliably read home-manager's nix-store symlinks;
# copy the managed source instead. Reload live when the WM is already running.
set -euo pipefail

CONFIG_SRC="@configSrc@"
DEST="${HOME}/.config/bobrwm/config.zon"

mkdir -p "$(dirname "$DEST")"
cp -f "$CONFIG_SRC" "$DEST"
chmod 644 "$DEST"

export PATH="/opt/homebrew/bin:${HOME}/.local/bin:/usr/bin:/bin:$PATH"
if command -v bobrwm >/dev/null 2>&1 && bobrwm query workspaces >/dev/null 2>&1; then
  if bobrwm reload-config; then
    echo "[bobrwm] config deployed and reloaded"
  else
    echo "[bobrwm] warning: config deployed but reload failed" >&2
  fi
else
  echo "[bobrwm] config deployed to $DEST"
fi
