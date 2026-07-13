#!/usr/bin/env bash
# Ensure a background contextio proxy is running WITH redaction enabled.
#
# NOTE: `ctxio proxy -d` (v0.3.0) spawns only `proxy --port 4040` and drops
# --redact / --log-* flags. We start the node entrypoint ourselves with the
# full arg list and write background.json so `ctxio proxy status|stop` still work.
set -euo pipefail

export PATH="${HOME}/.cache/.bun/bin:${HOME}/.npm-packages/bin:${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:$PATH"

STATE_DIR="${HOME}/.contextio"
BG_JSON="${STATE_DIR}/background.json"
LOG_FILE="${STATE_DIR}/proxy.log"
PORT="${CONTEXTIO_PORT:-4040}"
PRESET="${CONTEXTIO_REDACT_PRESET:-pii}"
MAX_SESSIONS="${CONTEXTIO_LOG_MAX_SESSIONS:-50}"

# Required so provider-level x-target-url (e.g. xAI → api.x.ai) is honored.
# Only accepted from localhost; safe for a loopback proxy.
export CONTEXT_PROXY_ALLOW_TARGET_OVERRIDE="${CONTEXT_PROXY_ALLOW_TARGET_OVERRIDE:-1}"

if ! command -v ctxio >/dev/null 2>&1; then
  echo "[contextio] ctxio not on PATH — run build-switch or install-contextio.sh" >&2
  exit 0
fi

# Resolve CLI entry (bun global bin links straight at dist/main.js).
CLI_ENTRY=""
if command -v ctxio >/dev/null 2>&1; then
  candidate="$(command -v ctxio)"
  # bun: symlink → package dist/main.js; npm: wrapper script that requires dist
  if [[ -f "$candidate" ]]; then
    CLI_ENTRY="$candidate"
  fi
fi
if [[ -z "$CLI_ENTRY" || ! -f "$CLI_ENTRY" ]]; then
  for candidate in \
    "${HOME}/.cache/.bun/install/global/node_modules/@contextio/cli/dist/main.js" \
    "${HOME}/.npm-packages/lib/node_modules/@contextio/cli/dist/main.js"
  do
    if [[ -f "$candidate" ]]; then
      CLI_ENTRY="$candidate"
      break
    fi
  done
fi
if [[ -z "$CLI_ENTRY" || ! -f "$CLI_ENTRY" ]]; then
  echo "[contextio] could not resolve @contextio/cli entrypoint — skipping" >&2
  exit 0
fi

is_running() {
  # Prefer ctxio status if it reports a live pid
  if ctxio proxy status 2>/dev/null | grep -Eqi 'running \(pid'; then
    return 0
  fi
  # Also trust background.json + live process
  if [[ -f "$BG_JSON" ]]; then
    local pid
    pid="$(node -e "try{const s=require(process.argv[1]); process.stdout.write(String(s.pid||''))}catch{}" "$BG_JSON" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

if is_running; then
  exit 0
fi

# Clean stale state
rm -f "$BG_JSON"
mkdir -p "$STATE_DIR"

# Build argv. Logging on by default; redaction on unless CONTEXTIO_NO_REDACT=1.
args=(proxy --port "$PORT" --log-max-sessions "$MAX_SESSIONS")
if [[ "${CONTEXTIO_NO_REDACT:-0}" != "1" ]]; then
  args+=(--redact --redact-preset "$PRESET")
fi
if [[ -n "${CONTEXTIO_REDACT_POLICY:-}" && -f "${CONTEXTIO_REDACT_POLICY}" ]]; then
  args+=(--redact-policy "$CONTEXTIO_REDACT_POLICY")
fi
if [[ "${CONTEXTIO_REDACT_REVERSIBLE:-0}" == "1" ]]; then
  args+=(--redact-reversible)
fi

# Detach: nohup + background, write pid for ctxio stop/status compatibility.
nohup node "$CLI_ENTRY" "${args[@]}" >>"$LOG_FILE" 2>&1 &
pid=$!

# Wait briefly for listen
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if ! kill -0 "$pid" 2>/dev/null; then
    break
  fi
  if command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    break
  fi
  if curl -sf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

if ! kill -0 "$pid" 2>/dev/null; then
  echo "[contextio] warning: proxy process exited early — see $LOG_FILE" >&2
  exit 0
fi

node -e "
const fs = require('fs');
const state = {
  pid: Number(process.argv[1]),
  port: Number(process.argv[2]),
  startedAt: new Date().toISOString(),
};
fs.writeFileSync(process.argv[3], JSON.stringify(state, null, 2) + '\n');
" "$pid" "$PORT" "$BG_JSON"

redact_label="on/${PRESET}"
if [[ "${CONTEXTIO_NO_REDACT:-0}" == "1" ]]; then
  redact_label="off"
fi
echo "[contextio] background proxy started (pid $pid, port $PORT, redact=$redact_label)"
