#!/usr/bin/env bash
# Install @fission-ai/openspec with bun and seed global pi skills + prompts.
#
# Per https://github.com/Fission-AI/OpenSpec/blob/main/docs/supported-tools.md
# Pi uses:
#   .pi/skills/openspec-*/SKILL.md   (project)
#   .pi/prompts/opsx-*.md           (project)
#
# Pi also loads global user resources from:
#   ~/.pi/agent/skills/
#   ~/.pi/agent/prompts/
#
# This script installs the CLI via `bun install -g` (bins under
# ~/.cache/.bun/bin) and mirrors the core-profile Pi artifacts into ~/.pi/agent
# so /opsx-* and openspec skills work without a per-project init.
# Project-local `openspec init --tools pi` still owns the openspec/ specs tree.
set -euo pipefail

export PATH="/opt/homebrew/bin:${HOME}/.local/share/mise/shims:${HOME}/.cache/.bun/bin:${HOME}/.local/bin:/usr/bin:/bin:$PATH"
# Prefer no anonymous telemetry during activation installs.
export OPENSPEC_TELEMETRY="${OPENSPEC_TELEMETRY:-0}"

if ! command -v bun >/dev/null 2>&1; then
  echo "[openspec] bun not found — skipping install" >&2
  exit 0
fi

# Pin for reproducible activation; override with OPENSPEC_VERSION=...
OPENSPEC_VERSION="${OPENSPEC_VERSION:-1.6.0}"

if ! bun install -g "@fission-ai/openspec@${OPENSPEC_VERSION}"; then
  echo "[openspec] warning: bun install -g failed (offline? network?)" >&2
  exit 0
fi

export PATH="${HOME}/.cache/.bun/bin:$PATH"
if ! command -v openspec >/dev/null 2>&1; then
  echo "[openspec] warning: openspec binary missing after bun install -g" >&2
  exit 0
fi

echo "[openspec] installed $(openspec --version 2>/dev/null || echo openspec) via bun ($(command -v openspec))"

# Prefer core profile (propose/explore/apply/sync/archive + update command files).
# Non-fatal if config commands fail on older/newer CLI shapes.
openspec config set profile core >/dev/null 2>&1 || true

# Generate Pi tool artifacts into a temp project, then copy into global pi dirs.
# openspec init is project-scoped; we only keep the .pi/{skills,prompts} outputs.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/openspec-pi.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

if ! (
  cd "$TMP"
  openspec init --tools pi --profile core --force
); then
  echo "[openspec] warning: failed to generate pi skills/prompts" >&2
  exit 0
fi

if [[ ! -d "$TMP/.pi/skills" || ! -d "$TMP/.pi/prompts" ]]; then
  echo "[openspec] warning: expected .pi/skills and .pi/prompts missing after init" >&2
  exit 0
fi

PI_AGENT="${HOME}/.pi/agent"
mkdir -p "$PI_AGENT/skills" "$PI_AGENT/prompts"

# Replace previous OpenSpec-managed skill dirs / opsx prompts only.
# Leave other user skills/prompts alone.
for dir in "$PI_AGENT/skills"/openspec-*; do
  [[ -e "$dir" ]] || continue
  rm -rf "$dir"
done
for f in "$PI_AGENT/prompts"/opsx-*.md; do
  [[ -e "$f" ]] || continue
  rm -f "$f"
done

# Copy freshly generated artifacts
cp -R "$TMP/.pi/skills/." "$PI_AGENT/skills/"
cp -R "$TMP/.pi/prompts/." "$PI_AGENT/prompts/"

skill_count="$(find "$PI_AGENT/skills" -mindepth 1 -maxdepth 1 -type d -name 'openspec-*' | wc -l | tr -d ' ')"
prompt_count="$(find "$PI_AGENT/prompts" -maxdepth 1 -type f -name 'opsx-*.md' | wc -l | tr -d ' ')"
echo "[openspec] seeded ${skill_count} skills and ${prompt_count} prompts into ${PI_AGENT}"
