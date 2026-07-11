/**
 * ContextIO proxy routing
 *
 * Pi hardcodes provider baseUrls in its model registry; ANTHROPIC_BASE_URL /
 * OPENAI_BASE_URL alone do not redirect traffic. This extension rewrites the
 * built-in provider endpoints to the local contextio proxy so every LLM call
 * is logged (and redacted, if the proxy was started with --redact).
 *
 * Default proxy: http://127.0.0.1:4040  (source-tagged as /pi/...)
 * Disable: CONTEXTIO_DISABLED=1
 * Custom:  CONTEXTIO_PROXY_URL=http://127.0.0.1:4040
 *
 * xAI note: contextio has no built-in xAI upstream. We route the OpenAI-compat
 * path through the proxy and set `x-target-url` so the proxy forwards to
 * api.x.ai (requires CONTEXT_PROXY_ALLOW_TARGET_OVERRIDE=1 on the proxy).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DEFAULT_PROXY = "http://127.0.0.1:4040";

type ProviderRoute = {
  name: string;
  baseUrl: (proxy: string) => string;
  /** Extra request headers (e.g. x-target-url for non-built-in upstreams). */
  headers?: Record<string, string>;
};

/** Providers that speak a path shape contextio can classify + forward. */
const PROVIDERS: ProviderRoute[] = [
  // Anthropic Messages: origin only; SDK appends /v1/messages
  { name: "anthropic", baseUrl: (p) => `${p}/pi` },
  // OpenAI platform APIs: include /v1 so /responses and /chat/completions land correctly
  { name: "openai", baseUrl: (p) => `${p}/pi/v1` },
  // Google AI Studio / Gemini: include /v1beta (matches built-in model baseUrl)
  { name: "google", baseUrl: (p) => `${p}/pi/v1beta` },
  // xAI (Grok): OpenAI-compat chat completions → force upstream to api.x.ai
  {
    name: "xai",
    baseUrl: (p) => `${p}/pi/v1`,
    headers: {
      // Full URL required: contextio uses x-target-url as-is when it starts with http
      "x-target-url": "https://api.x.ai/v1/chat/completions",
    },
  },
];

function proxyRoot(): string | null {
  if (process.env.CONTEXTIO_DISABLED === "1") return null;
  const raw = (process.env.CONTEXTIO_PROXY_URL || DEFAULT_PROXY).trim().replace(/\/+$/, "");
  return raw || null;
}

export default function (pi: ExtensionAPI) {
  const root = proxyRoot();
  if (!root) return;

  for (const provider of PROVIDERS) {
    pi.registerProvider(provider.name, {
      baseUrl: provider.baseUrl(root),
      ...(provider.headers ? { headers: provider.headers } : {}),
    });
  }

  pi.registerCommand("contextio-status", {
    description: "Show whether pi is routing LLM traffic through contextio",
    handler: async (_args, ctx) => {
      if (process.env.CONTEXTIO_DISABLED === "1") {
        ctx.ui.notify("contextio: DISABLED (CONTEXTIO_DISABLED=1)", "warning");
        return;
      }
      const lines = [
        `contextio proxy: ${root}`,
        ...PROVIDERS.map((p) => {
          const extra = p.headers?.["x-target-url"]
            ? `  (→ ${p.headers["x-target-url"]})`
            : "";
          return `  ${p.name} → ${p.baseUrl(root)}${extra}`;
        }),
        "start/stop: ensure-contextio-proxy | ctxio proxy status | ctxio proxy stop",
        "bypass: CONTEXTIO_DISABLED=1 pi",
      ];
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
