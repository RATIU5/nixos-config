#!/usr/bin/env bash
# Build OLS (Odin Language Server) from source against the Homebrew odin.
# Runs during home-manager activation: clones on first run, rebuilds only
# when the upstream master branch has new commits.
set -euo pipefail

OLS_DIR="$HOME/.local/share/ols"
BIN_DIR="$HOME/.local/bin"
ODIN_BIN="/opt/homebrew/bin/odin"

if [[ ! -x "$ODIN_BIN" ]]; then
  echo "[ols] odin not found at $ODIN_BIN — skipping build (run 'brew install odin' first)" >&2
  exit 0
fi

export PATH="/opt/homebrew/bin:/usr/bin:/usr/local/bin:$PATH"
mkdir -p "$BIN_DIR"

NEEDS_BUILD=0

if [[ ! -d "$OLS_DIR/.git" ]]; then
  echo "[ols] cloning..."
  rm -rf "$OLS_DIR"
  git clone --depth 1 https://github.com/DanielGavin/ols "$OLS_DIR"
  NEEDS_BUILD=1
else
  if git -C "$OLS_DIR" fetch --depth 1 origin master 2>/dev/null; then
    LOCAL=$(git -C "$OLS_DIR" rev-parse HEAD)
    REMOTE=$(git -C "$OLS_DIR" rev-parse FETCH_HEAD)
    if [[ "$LOCAL" != "$REMOTE" ]]; then
      echo "[ols] updating..."
      # Shallow clone: FETCH_HEAD shares no history with HEAD, so a merge fails
      # with "unrelated histories". This is a build-only mirror, so just reset.
      git -C "$OLS_DIR" reset --hard FETCH_HEAD
      NEEDS_BUILD=1
    fi
  else
    echo "[ols] fetch failed (offline?), using cached repo"
  fi
fi

# Rebuild if binaries are missing or are not actual compiled executables
# (a shell script also passes -x, so we check for Mach-O explicitly)
if [[ ! -x "$OLS_DIR/ols" || ! -x "$OLS_DIR/odinfmt" ]] || \
   ! file "$OLS_DIR/ols" 2>/dev/null | grep -q "Mach-O"; then
  NEEDS_BUILD=1
fi

if [[ "$NEEDS_BUILD" == "1" ]]; then
  echo "[ols] building..."
  cd "$OLS_DIR"

  # Odin dev-2026-05 added .Haiku to Odin_OS_Type; patch OLS until it catches up.
  BUILD_FILE="src/server/build.odin"
  if ! grep -q '\.Haiku' "$BUILD_FILE"; then
    awk '/\.Unknown[[:space:]]*=[[:space:]]*"unknown",/{print; print "\t.Haiku        = \"haiku\","; next}1' \
      "$BUILD_FILE" > "$BUILD_FILE.tmp" && mv "$BUILD_FILE.tmp" "$BUILD_FILE"
    echo "[ols] patched: added .Haiku to os_enum_to_string"
  fi

  ./build.sh
  ./odinfmt.sh
  echo "[ols] built ($(git -C "$OLS_DIR" rev-parse --short HEAD))"
else
  echo "[ols] already up to date ($(git -C "$OLS_DIR" rev-parse --short HEAD))"
fi

# Always write wrapper scripts (not symlinks) so GUI apps like Zed get the
# right environment without sourcing the shell. Remove first to avoid following
# any pre-existing symlink into the OLS build dir.
rm -f "$BIN_DIR/ols"
cat > "$BIN_DIR/ols" <<'EOF'
#!/usr/bin/env bash
export OLS_BUILTIN_FOLDER="$HOME/.local/share/ols/builtin"
# mise shims first so `odin` resolves to the project-pinned version
export PATH="$HOME/.local/share/mise/shims:/opt/homebrew/bin:/usr/bin:/usr/local/bin:$PATH"
exec "$HOME/.local/share/ols/ols" "$@"
EOF
chmod +x "$BIN_DIR/ols"

rm -f "$BIN_DIR/odinfmt"
cat > "$BIN_DIR/odinfmt" <<'EOF'
#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:$PATH"
exec "$HOME/.local/share/ols/odinfmt" "$@"
EOF
chmod +x "$BIN_DIR/odinfmt"
