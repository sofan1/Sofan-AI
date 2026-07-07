
---
Task ID: publish-workspace
Agent: main
Task: Make the workspace publishable via the platform URL with gateway + webhook fully self-contained (no external dependencies)

Work Log:
- Refactored Next.js reverse-proxy to route /webhook/* to Sofan webhook (port 9120), everything else to Hermes dashboard (port 9119)
- Added /api/status endpoint that probes both backends and returns combined JSON health
- Added permissive CORS headers so external channels (WhatsApp, web forms) can hit the published URL directly
- Built lazy auto-spawn in lib/spawn-services.js — route handlers call ensureServices() before forwarding, which spawns Hermes + webhook if not already running (waits up to ~30s for ports to come up)
- Tried instrumentation.ts first but Next.js 16 Edge Runtime validator blocked all Node.js APIs (child_process, fs, path, process.versions); switched to lazy-init pattern triggered by HTTP requests instead
- Production build (npm run build) succeeded; production start (npm start) verified working
- End-to-end test: started ONLY Next.js with all backends down, hit /api/status → auto-spawned Hermes + webhook in 3.4s, all returned 200
- Created /home/z/my-project/scripts/start_all.sh as a convenience launcher (uses setsid for proper detach)
- Updated /home/z/my-project/download/hermes-dashboard-credentials.txt with full route map, auth re-enable instructions, API key rotation links, and WhatsApp repair guidance

Stage Summary:
- Workspace is fully self-contained: only Next.js needs to be running; Hermes + webhook auto-spawn on first request
- All routes verified through proxy:
    /                    → Hermes dashboard (HTTP 200, HTML, 721 bytes)
    /webhook/contact     → POST returns 200 with confirmation
    /webhook/chat        → POST endpoint
    /webhook/health      → GET returns 200 with {"status":"ok"}
    /webhook/messages    → GET returns 200 with message history
    /api/status          → GET returns combined JSON health-check
- Static assets (1.9MB JS, 112KB CSS) load with correct content types
- Production build artifacts in /home/z/my-project/.next/ ready for platform to deploy
- Platform will run `npm start` which starts Next.js on port 3000; auto-spawn handles the rest
