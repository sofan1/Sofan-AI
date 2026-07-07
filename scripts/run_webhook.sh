#!/usr/bin/env bash
# Launch the Sofan AI webhook server in the background.
# Logs go to /home/z/my-project/scripts/webhook.log
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
APP_DIR="${WORKSPACE_DIR}/sofan-ai-fresh"
LOG_FILE="${SCRIPT_DIR}/webhook.log"
PID_FILE="${SCRIPT_DIR}/webhook.pid"

mkdir -p "$HOME/.hermes"

cd "$APP_DIR"

# Kill any previous instance
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")" 2>/dev/null || true
  sleep 1
fi

# Start server in background, output to log
nohup python3 webhook-server.py > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$PID_FILE"

# Wait for it to come up
sleep 2

# Verify it's still alive
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "ERROR: server died immediately. Log:"
  cat "$LOG_FILE"
  exit 1
fi

echo "Webhook server started (PID $SERVER_PID)"
echo "Listening on http://0.0.0.0:9120"
echo "Log: $LOG_FILE"
echo ""
echo "Endpoints:"
echo "  POST /webhook/contact"
echo "  POST /webhook/chat"
echo "  GET  /webhook/health"
echo "  GET  /webhook/messages"
