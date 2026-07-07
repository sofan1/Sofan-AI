#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# WhatsApp QR Pairing - Run in an interactive terminal
# QR code is SAVED AS IMAGE (~/.hermes/whatsapp-qr.png)
# so you can open and scan it from your mobile
# ─────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HOME}/.hermes"
HERMES_AGENT="${HERMES_HOME}/hermes-agent"
SESSION_DIR="${HERMES_HOME}/whatsapp/session"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          Sofan AI - WhatsApp QR Pairing                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

# Ensure bridge deps
if [ ! -d "${HERMES_AGENT}/scripts/whatsapp-bridge/node_modules" ]; then
  echo "→ Installing bridge dependencies..."
  cd "${HERMES_AGENT}/scripts/whatsapp-bridge"
  npm install --no-fund --no-audit --progress=false
fi

mkdir -p "$SESSION_DIR"

# Clear existing session if requested
if [ -f "${SESSION_DIR}/creds.json" ]; then
  echo "⚠ Existing session found."
  read -p "  Re-pair? (y/N): " -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then rm -rf "${SESSION_DIR:?}"/*; else
    echo "✓ Using existing session."
    echo "  Start gateway: cd ${HERMES_AGENT} && uv run hermes gateway run"
    exit 0
  fi
fi

echo ""
echo "📱 Open WhatsApp → Menu → Linked Devices → Link a Device"
echo "   QR image will be saved to: ${HERMES_HOME}/whatsapp-qr.png"
echo ""

cd "${HERMES_AGENT}/scripts/whatsapp-bridge"
node bridge.js --pair-only --session "$SESSION_DIR"

echo ""
if [ -f "${SESSION_DIR}/creds.json" ]; then
  echo "✅ WhatsApp paired! Update session:"
  echo "   cd ${SCRIPT_DIR} && bash deploy/backup-session.sh"
  echo "   Then commit and push the new session.tar.gz"
else
  echo "⚠ Pairing incomplete. Run again."
fi
