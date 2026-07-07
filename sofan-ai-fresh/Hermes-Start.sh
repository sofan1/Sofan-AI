#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# Sofan Business AI - Hermes Agent Launcher
# ─────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HOME}/.hermes"
HERMES_AGENT="${HERMES_HOME}/hermes-agent"
WORKSPACE="${SCRIPT_DIR}"

echo "┌──────────────────────────────────────────────┐"
echo "│      Sofan AI Assistant - Hermes Agent       │"
echo "├──────────────────────────────────────────────┤"
echo "│ Commands:                                    │"
echo "│  chat      CLI interactive chat              │"
echo "│  dashboard Web UI at http://127.0.0.1:9119   │"
echo "│  gateway   WhatsApp/TG message responder     │"
echo "│  all       Dashboard + Gateway together       │"
echo "│  service   Install as systemd (auto-start)    │"
echo "│  whatsapp  Pair WhatsApp (QR code)           │"
echo "│  status    Check system status               │"
echo "│  model     Change AI model                   │"
echo "│  setup     Run setup wizard                  │"
echo "└──────────────────────────────────────────────┘"

CMD="${1:-chat}"

case "$CMD" in
  chat)
    echo "Starting Hermes CLI chat..."
    cd "$HERMES_AGENT" && uv run hermes chat \
      --provider gemini \
      -m "gemini-2.5-flash"
    ;;
  dashboard)
    echo "Starting Hermes Web Dashboard at http://127.0.0.1:9119"
    cd "$HERMES_AGENT" && uv run hermes dashboard --port 9119 --host 0.0.0.0
    ;;
  gateway)
    echo "Starting Hermes Gateway (WhatsApp auto-responder)..."
    echo "Send a message to your paired WhatsApp number to test."
    cd "$HERMES_AGENT" && uv run hermes gateway run
    ;;
  all)
    echo "Starting Hermes Dashboard + Gateway together..."
    cd "$HERMES_AGENT"
    uv run hermes dashboard --port 9119 --host 0.0.0.0 --no-open &
    DASH_PID=$!
    echo "  Dashboard PID: $DASH_PID (http://0.0.0.0:9119)"
    echo "  Starting gateway..."
    uv run hermes gateway run
    ;;
  whatsapp)
    echo "Generating WhatsApp QR code..."
    cd "$HERMES_AGENT" && uv run hermes whatsapp
    ;;
  qr-pair)
    cd "$WORKSPACE" && bash WhatsApp-QR-Pair.sh
    ;;
  model)
    cd "$HERMES_AGENT" && uv run hermes model
    ;;
  status)
    cd "$HERMES_AGENT" && uv run hermes status
    ;;
  service)
    echo "Installing/Managing systemd services..."
    case "${2:-status}" in
      install)
        mkdir -p "${HOME}/.config/systemd/user"
        cp "$WORKSPACE"/systemd/*.service "${HOME}/.config/systemd/user/"
        systemctl --user daemon-reload
        systemctl --user enable hermes-dashboard hermes-gateway hermes-webhook 2>/dev/null
        systemctl --user start hermes-dashboard hermes-gateway hermes-webhook 2>/dev/null
        echo "✅ All services installed (auto-start on boot)"
        echo "   Dashboard: http://<your-ip>:9119"
        echo "   Webhook:   http://<your-ip>:9120"
        ;;
      status)
        echo "=== Dashboard ==="
        systemctl --user status hermes-dashboard 2>&1 | head -10
        echo ""
        echo "=== Gateway ==="
        systemctl --user status hermes-gateway 2>&1 | head -10
        echo ""
        echo "=== Webhook ==="
        systemctl --user status hermes-webhook 2>&1 | head -10
        ;;
      stop)
        systemctl --user stop hermes-dashboard hermes-gateway hermes-webhook 2>/dev/null
        echo "Services stopped"
        ;;
      restart)
        systemctl --user restart hermes-dashboard hermes-webhook 2>/dev/null
        echo "Services restarted"
        ;;
      logs)
        journalctl --user -u hermes-dashboard -n 50 --no-pager
        ;;
      *)
        echo "Usage: ./Hermes-Start.sh service [install|status|stop|restart|logs]"
        ;;
    esac
    ;;
  setup)
    cd "$HERMES_AGENT" && uv run hermes setup
    ;;
  *)
    echo "Unknown command: $CMD"
    echo "Usage: ./Hermes-Start.sh [chat|dashboard|gateway|all|whatsapp|qr-pair|service|model|status|setup]"
    exit 1
    ;;
esac
