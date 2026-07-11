#!/usr/bin/env bash
# Sync tracked pi agent config from the Nix store into ~/.pi.
# Runtime state (auth.json, sessions, node_modules, bun.lock) is preserved.
# Idempotent: only rewrites when source content differs.
set -euo pipefail

PI_HOME="${HOME}/.pi"
SRC="@piSrc@"

if [[ ! -d "$SRC" ]]; then
  echo "[pi] source missing at $SRC — skipping" >&2
  exit 0
fi

mkdir -p "$PI_HOME/agent/themes" "$PI_HOME/agent/extensions"

# Copy a single file if content differs (or dest missing).
sync_file() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "$src" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    return 0
  fi
  # Prefer install over cp so we own a writable copy (not a store symlink).
  install -m 0644 "$src" "$dest"
}

# Recursively sync a directory tree of files (no node_modules).
sync_tree() {
  local src_root="$1"
  local dest_root="$2"
  local rel path dest

  # Find all regular files under src_root, excluding node_modules.
  while IFS= read -r -d '' path; do
    rel="${path#"$src_root"/}"
    # skip node_modules anywhere in the path
    case "$rel" in
      */node_modules/*|node_modules/*) continue ;;
    esac
    dest="$dest_root/$rel"
    sync_file "$path" "$dest"
  done < <(find "$src_root" -type f -print0)
}

# Workspace root files
sync_file "$SRC/package.json" "$PI_HOME/package.json"
sync_file "$SRC/tsconfig.json" "$PI_HOME/tsconfig.json"
sync_file "$SRC/.gitignore" "$PI_HOME/.gitignore"
sync_file "$SRC/README.md" "$PI_HOME/README.md"

# Agent config
sync_file "$SRC/agent/settings.json" "$PI_HOME/agent/settings.json"
sync_file "$SRC/agent/cloak.json" "$PI_HOME/agent/cloak.json"
sync_file "$SRC/agent/mcp.json" "$PI_HOME/agent/mcp.json"

# Themes + extensions (full trees)
if [[ -d "$SRC/agent/themes" ]]; then
  sync_tree "$SRC/agent/themes" "$PI_HOME/agent/themes"
fi
if [[ -d "$SRC/agent/extensions" ]]; then
  # Remove managed package dirs that were dropped from the source tree so
  # renames/deletes in the repo actually land on disk. Standalone .ts files
  # and package dirs present in SRC are rewritten below.
  # herdr-agent-state.ts is installed by `herdr integration install pi` (see
  # install-herdr-integrations.sh) and must NOT be deleted here.
  if [[ -e "$PI_HOME/agent/extensions/opencode-cloudflare" && ! -e "$SRC/agent/extensions/opencode-cloudflare" ]]; then
    rm -rf "$PI_HOME/agent/extensions/opencode-cloudflare"
  fi
  sync_tree "$SRC/agent/extensions" "$PI_HOME/agent/extensions"
fi

# Install/refresh bun workspace deps when package.json changed or node_modules missing.
# Non-fatal so offline switches still succeed.
need_install=0
if [[ ! -d "$PI_HOME/node_modules" ]]; then
  need_install=1
elif [[ -f "$PI_HOME/package.json" ]]; then
  # crude: if any workspace package.json is newer than node_modules, reinstall
  if find "$PI_HOME/agent/extensions" -name package.json -newer "$PI_HOME/node_modules" 2>/dev/null | grep -q .; then
    need_install=1
  elif [[ "$PI_HOME/package.json" -nt "$PI_HOME/node_modules" ]]; then
    need_install=1
  fi
fi

if [[ "$need_install" -eq 1 ]]; then
  if command -v bun >/dev/null 2>&1; then
    echo "[pi] bun install in $PI_HOME" >&2
    (cd "$PI_HOME" && bun install) || \
      echo "warning: pi bun install failed (offline? network?)" >&2
  else
    echo "warning: bun not on PATH; run 'cd ~/.pi && bun install' after switch" >&2
  fi
fi
