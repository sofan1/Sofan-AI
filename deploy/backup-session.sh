#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# Backup WhatsApp session from local machine to repo
# ─────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HOME}/.hermes"
SESSION_SRC="${HERMES_HOME}/whatsapp/session"
SESSION_ARCHIVE="${SCRIPT_DIR}/session.tar.gz"

if [ ! -f "${SESSION_SRC}/creds.json" ]; then
  echo "❌ No WhatsApp session found at ${SESSION_SRC}"
  echo "   Pair WhatsApp first: bash WhatsApp-QR-Pair.sh"
  exit 1
fi

echo "📦 Backing up WhatsApp session..."
tar czf "${SESSION_ARCHIVE}" -C "${HERMES_HOME}/whatsapp" session/
echo "✅ Session backed up to ${SESSION_ARCHIVE}"
echo "   Next: git add deploy/session.tar.gz && git commit -m 'update session' && git push"
