#!/usr/bin/env bash
# Launch the Next.js reverse-proxy (now at project root) that exposes
# the Hermes dashboard through the standard preview URL on port 3000.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${SCRIPT_DIR}/hermes-proxy.log"
PID_FILE="${SCRIPT_DIR}/hermes-proxy.pid"

cd "$PROXY_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")" 2>/dev/null || true
  sleep 2
fi

nohup ./node_modules/.bin/next dev -p 3000 -H 0.0.0.0 > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$PID_FILE"

sleep 8

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "ERROR: Next.js died immediately. Log:"
  cat "$LOG_FILE"
  exit 1
fi

echo "Next.js reverse-proxy started (PID $SERVER_PID)"
echo "Listening on http://0.0.0.0:3000"
echo "Forwards all requests to http://127.0.0.1:9119 (Hermes dashboard)"
echo "Log: $LOG_FILE"
