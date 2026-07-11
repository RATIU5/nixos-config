# pi agent config

Source of truth for `~/.pi` (earendil-works `pi` coding agent).

Managed by home-manager activation in `modules/darwin/home-manager.nix`:
tracked files are synced into `~/.pi` on each `build-switch`. Runtime state
(`auth.json`, sessions, `node_modules`) is left alone.

## Layout

```
dotfiles/pi/
├── package.json          # bun workspace root
├── tsconfig.json
└── agent/
    ├── settings.json     # theme, packages, thinking level
    ├── cloak.json        # secret masking
    ├── mcp.json          # MCP servers (no personal endpoints)
    ├── themes/
    └── extensions/       # auto-discovered by pi
```

## Extensions included

Standalone:

- `answer.ts` — extract follow-up questions into a TUI form
- `git-interceptor.ts` — no interactive git editors; block `--no-verify`
- `whimsical.ts` — random thinking spinner messages
- `worker-configuration-guard.ts` — block hand-edits of Wrangler types
- `contextio-proxy.ts` — route anthropic/openai/google/xai through local contextio

Packages:

- `pi-cloak` — secret cloaking via `cloak.json` (read-tool only)
- `pi-skill-toggle` — skill discovery / enable-disable UI
- `save-md` — save conversation markdown
- `web-tools` — webfetch + websearch (Exa; needs `EXA_API_KEY`)

Skipped from the upstream reference config:

- `opencode-cloudflare`
- personal MCP endpoints (`exe.mulroy.ai`, `uidotsh`, …)

Installed separately (not tracked in this tree):

- `herdr-agent-state.ts` — via `herdr integration install pi` on activation

## ContextIO

LLM traffic is routed through a local [`contextio`](https://github.com/larsderidder/contextio)
proxy for logging + redaction. Activation installs `ctxio` and starts the proxy
with the `pii` preset. The `contextio-proxy` extension rewrites provider baseUrls
(pi ignores `ANTHROPIC_BASE_URL` / `OPENAI_BASE_URL`).

```bash
pi                        # zsh wrapper ensures proxy is up
ctxio proxy status
ctxio monitor
ctxio inspect --last
/contextio-status         # inside pi
CONTEXTIO_DISABLED=1 pi   # bypass
```

## After switch

```bash
# once (or when package.json / workspace deps change)
cd ~/.pi && bun install

# after extension edits in this repo + build-switch
pi  # then /reload
```

## Checks

```bash
cd ~/.pi && bun run check
ctxio doctor
```
