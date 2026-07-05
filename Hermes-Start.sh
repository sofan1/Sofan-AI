#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# Sofan Business AI - Hermes Agent Launcher
# ─────────────────────────────────────────────────────
set -e

HERMES_AGENT="${HOME}/.hermes/hermes-agent"
WORKSPACE="/media/zorin/DATA1/Projects/Sofan"

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
    cd "$HERMES_AGENT" && uv run hermes dashboard --port 9119 --host 127.0.0.1
    ;;
  gateway)
    echo "Starting Hermes Gateway (WhatsApp auto-responder)..."
    echo "Send a message to your paired WhatsApp number to test."
    cd "$HERMES_AGENT" && uv run hermes gateway run
    ;;
  all)
    echo "Starting Hermes Dashboard + Gateway together..."
    cd "$HERMES_AGENT"
    uv run hermes dashboard --port 9119 --host 127.0.0.1 --no-open &
    DASH_PID=$!
    echo "  Dashboard PID: $DASH_PID (http://127.0.0.1:9119)"
    echo "  Starting gateway..."
    uv run hermes gateway run
    ;;
  whatsapp)
    echo "Generating WhatsApp QR code..."
    cd "$HERMES_AGENT" && uv run hermes whatsapp
    ;;
  qr-pair)
    cd "$WORKSPACE" && ./WhatsApp-QR-Pair.sh
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
        systemctl --user daemon-reload
        systemctl --user enable hermes-dashboard
        systemctl --user start hermes-dashboard
        echo "✅ Dashboard service installed (auto-starts on boot)"
        echo "   http://127.0.0.1:9119"
        ;;
      status)
        echo "=== Dashboard ==="
        systemctl --user status hermes-dashboard 2>&1 | head -10
        echo ""
        echo "=== Gateway ==="
        systemctl --user status hermes-gateway 2>&1 | head -10
        ;;
      stop)
        systemctl --user stop hermes-dashboard hermes-gateway 2>/dev/null
        echo "Services stopped"
        ;;
      restart)
        systemctl --user restart hermes-dashboard 2>/dev/null
        echo "Dashboard restarted"
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
