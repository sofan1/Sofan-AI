#!/usr/bin/env bash
# Launch the official Hermes Agent dashboard in the background.
# - Listens on 0.0.0.0:9119 (so preview-URL proxy can reach it)
# - Uses --skip-build (we already built the web assets via npm)
# - Uses --no-open (no browser in this environment)
# - Logs to /home/z/my-project/scripts/hermes-dashboard.log
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DIR="${HOME}/.hermes/hermes-agent"
LOG_FILE="${SCRIPT_DIR}/hermes-dashboard.log"
PID_FILE="${SCRIPT_DIR}/hermes-dashboard.pid"
export HERMES_HOME="${HOME}/.hermes"
export UV_CACHE_DIR="${HOME}/.cache/uv"

cd "$HERMES_DIR"

# Kill previous instance if any
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")" 2>/dev/null || true
  sleep 1
fi

# Stop any existing hermes dashboard processes (clean slate)
.venv/bin/hermes dashboard --stop >/dev/null 2>&1 || true

# Start dashboard
nohup env HERMES_HOME="$HERMES_HOME" UV_CACHE_DIR="$UV_CACHE_DIR" \
  .venv/bin/hermes dashboard \
    --port 9119 \
    --host 127.0.0.1 \
    --skip-build \
    --no-open \
  > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$PID_FILE"

# Give it time to boot
sleep 6

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  echo "ERROR: dashboard died immediately. Log:"
  cat "$LOG_FILE"
  exit 1
fi

echo "Hermes dashboard started (PID $SERVER_PID)"
echo "Listening on http://0.0.0.0:9119"
echo "Log: $LOG_FILE"
