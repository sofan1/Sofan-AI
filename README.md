# Hermes Agent Dashboard — Self-Contained Workspace

Next.js 16 reverse-proxy that fronts the official **Hermes Agent** dashboard
(`NousResearch/hermes-agent`) and the **Sofan** custom webhook server, all
behind a single published URL.

## Architecture

```
                ┌──────────────────────────────────────────┐
│   Published URL (port 3000)               │
│   https://sofan-ai.space-z.ai/           │
                └──────────────────┬───────────────────────┘
                                   │
                                   ▼
                ┌──────────────────────────────────────────┐
                │   Next.js 16 Reverse-Proxy               │
                │   proxy.ts → /api/proxy/*                │
                │   lib/spawn-services.js (auto-spawn)     │
                └──────┬───────────────────────┬───────────┘
                       │ /webhook/*            │ everything else
                       ▼                       ▼
       ┌───────────────────────────┐  ┌───────────────────────────┐
       │  Sofan Webhook (Python)   │  │  Hermes Dashboard (Python)│
       │  0.0.0.0:9120             │  │  127.0.0.1:9119           │
       │  /webhook/{contact,chat,  │  │  Loopback = no auth       │
       │   health,messages}        │  │  React SPA in web_dist/   │
       └───────────────────────────┘  └───────────────────────────┘
```

## Routes exposed through the published URL

| Path                       | Method | Description                          |
|----------------------------|--------|--------------------------------------|
| `/`                        | GET    | Hermes dashboard (WebUI, no auth)    |
| `/webhook/contact`         | POST   | Sofan contact form webhook           |
| `/webhook/chat`            | POST   | Sofan chat message webhook           |
| `/webhook/health`          | GET    | Sofan webhook health check           |
| `/webhook/messages`        | GET    | Sofan message history                |
| `/api/status`              | GET    | Combined JSON health-check           |

## Self-contained auto-spawn

The Next.js proxy auto-spawns Hermes + webhook on first request if they
aren't already running (see `lib/spawn-services.js`). So the platform
only needs to start Next.js — everything else comes up on demand.

## Local development

```bash
npm install
npm run dev          # http://localhost:3000
```

## Production

```bash
npm install
npm run build
npm run start        # http://0.0.0.0:3000
```

## Add API keys

Edit `/home/z/.hermes/.env` (inside the workspace) or use the Hermes
dashboard UI (Settings → API Keys) after the dashboard is up.

Supported providers:
- Google Gemini   — https://aistudio.google.com/app/apikey
- OpenRouter      — https://openrouter.ai/keys
- OpenCode Zen    — https://opencode.ai/zen/

## Files

```
app/api/proxy/route.js          Root / → Hermes
app/api/proxy/[...path]/route.js Catch-all → Hermes or Webhook (path-based)
app/api/status/route.js          Combined health endpoint
app/api/_shared.js               Upstream target constants
lib/spawn-services.js            Lazy auto-spawn for Hermes + webhook
proxy.ts                         Middleware: rewrites paths to /api/proxy/*
scripts/start_all.sh             One-shot launcher for all 3 services
sofan-ai-fresh/                  Cloned github.com/sofan1/Sofan-AI (launchers + webhook)
```

## Security notes

- `.env`, `session.tar.gz`, build artifacts, and logs are gitignored.
- Hermes binds to 127.0.0.1 (loopback) — bypasses the basic_auth gate.
  Re-enable auth by changing bind to 0.0.0.0 and adding `basic_auth`
  block to `~/.hermes/config.yaml`.
- The Sofan-AI repo's `deploy/.env` and `deploy/session.tar.gz` contain
  COMPROMISED credentials (committed to a public repo). Rotate them
  before use. They are gitignored here.
