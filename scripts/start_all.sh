#!/bin/bash
# ===================================================================
# Hermes Dashboard + Sofan Webhook + Next.js Reverse-Proxy launcher
# All three services run inside the workspace so the published URL
# (https://preview-<bot-id>.space-z.ai/) is fully self-contained.
#
# Routes through the published URL:
#   /                      → Hermes dashboard (WebUI, no auth)
#   /webhook/contact       → POST — Sofan contact form webhook
#   /webhook/chat          → POST — Sofan chat message webhook
#   /webhook/health        → GET  — Sofan webhook health check
#   /webhook/messages      → GET  — Sofan message history
#   /api/status            → GET  — combined health-check JSON
# ===================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
HERMES_HOME="${HOME}/.hermes"
HERMES_AGENT="${HERMES_HOME}/hermes-agent"

# Kill any stale instances
pkill -9 -f "hermes dashboard" 2>/dev/null || true
pkill -9 -f "webhook-server" 2>/dev/null || true
pkill -9 -f "next dev" 2>/dev/null || true
pkill -9 -f "next-server" 2>/dev/null || true
sleep 2

mkdir -p "${HERMES_HOME}/logs"

# 1) Hermes dashboard on 127.0.0.1:9119 (loopback = no auth gate)
setsid bash -c "
  cd ${HERMES_AGENT}
  UV_CACHE_DIR=${HOME}/.cache/uv exec .venv/bin/hermes dashboard \
    --port 9119 --host 127.0.0.1 --skip-build --no-open
" < /dev/null > ${HERMES_HOME}/logs/hermes-dashboard.log 2>&1 &
echo "Hermes dashboard: PID $! → 127.0.0.1:9119"

# 2) Sofan webhook server on 0.0.0.0:9120
setsid bash -c "
  cd ${WORKSPACE_DIR}/sofan-ai-fresh
  WEBHOOK_PORT=9120 exec python3 webhook-server.py
" < /dev/null > ${HERMES_HOME}/logs/sofan-webhook.log 2>&1 &
echo "Sofan webhook:    PID $! → 0.0.0.0:9120"

# 3) Next.js reverse-proxy on 0.0.0.0:3000 (entry point for the published URL)
setsid bash -c "
  cd ${WORKSPACE_DIR}
  exec npm run start
" < /dev/null > /tmp/next-prod.log 2>&1 &
echo "Next.js proxy:    PID $! → 0.0.0.0:3000"

# Wait for ports to come up
echo ""
echo "Waiting for services to come up..."
for port in 9119 9120 3000; do
  for i in $(seq 1 30); do
    if ss -tln 2>/dev/null | grep -q ":$port "; then
      echo "  ✓ port $port up"
      break
    fi
    sleep 1
  done
done

echo ""
echo "=== Final status ==="
ss -tlnp 2>/dev/null | grep -E ":(3000|9119|9120)" || echo "no ports up"
echo ""
echo "=== Health check ==="
curl -s http://127.0.0.1:3000/api/status 2>/dev/null | python3 -m json.tool 2>/dev/null | head -25 || echo "Waiting for services..."
