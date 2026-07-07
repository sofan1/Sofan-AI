#!/usr/bin/env bash
# ─────────────────────────────────────────────────────
# Sofan Business AI - Remote Server Setup
# Clones config & deploys Hermes Agent on a new machine
# ─────────────────────────────────────────────────────
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="${REPO_DIR}/deploy"
HERMES_HOME="${HOME}/.hermes"
HERMES_AGENT="${HERMES_HOME}/hermes-agent"

echo "╔═══════════════════════════════════════════════╗"
echo "║   Sofan Business AI - Remote Setup            ║"
echo "╚═══════════════════════════════════════════════╝"

# ── Step 1: Install dependencies ──
echo ""
echo "📦 Step 1: Installing system dependencies..."
if command -v apt &>/dev/null; then
  sudo apt update -qq && sudo apt install -y -qq curl git python3 python3-pip nodejs npm
elif command -v yum &>/dev/null; then
  sudo yum install -y curl git python3 python3-pip nodejs npm
elif command -v apk &>/dev/null; then
  apk add curl git python3 py3-pip nodejs npm
fi

# ── Step 2: Install uv ──
echo ""
echo "📦 Step 2: Installing uv (Python package manager)..."
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# ── Step 3: Install Hermes Agent ──
echo ""
echo "🤖 Step 3: Installing Hermes Agent..."
if [ ! -d "${HERMES_AGENT}" ]; then
  mkdir -p "${HERMES_HOME}"
  uv tool install hermes-agent --directory "${HERMES_AGENT}" 2>/dev/null || \
    git clone https://github.com/NousResearch/hermes-agent.git "${HERMES_AGENT}" 2>/dev/null
  cd "${HERMES_AGENT}" && uv sync
else
  echo "   Hermes already installed at ${HERMES_AGENT}"
fi

# ── Step 4: Deploy configuration ──
echo ""
echo "⚙️  Step 4: Deploying configuration..."
cp "${DEPLOY_DIR}/config.yaml" "${HERMES_HOME}/config.yaml"
cp "${DEPLOY_DIR}/.env" "${HERMES_HOME}/.env"
mkdir -p "${HERMES_HOME}/profiles"
cp "${DEPLOY_DIR}/profiles/"* "${HERMES_HOME}/profiles/" 2>/dev/null || true

# ── Step 5: Restore WhatsApp session ──
echo ""
echo "📱 Step 5: Restoring WhatsApp session..."
if [ -f "${DEPLOY_DIR}/session.tar.gz" ]; then
  mkdir -p "${HERMES_HOME}/whatsapp/session"
  tar xzf "${DEPLOY_DIR}/session.tar.gz" -C "${HERMES_HOME}/whatsapp/"
  echo "   WhatsApp session restored (paired & ready)"
fi

# ── Step 6: Install WhatsApp bridge deps ──
echo ""
echo "🔌 Step 6: Installing WhatsApp bridge..."
if [ -d "${HERMES_AGENT}/scripts/whatsapp-bridge" ]; then
  cd "${HERMES_AGENT}/scripts/whatsapp-bridge"
  npm install --no-fund --no-audit --progress=false 2>/dev/null
fi

# ── Step 7: Setup systemd services ──
echo ""
echo "🔄 Step 7: Installing systemd services..."
mkdir -p "${HOME}/.config/systemd/user"
cp "${DEPLOY_DIR}/systemd/"*.service "${HOME}/.config/systemd/user/"
systemctl --user daemon-reload

# ── Step 8: Enable linger (survive logout) ──
echo ""
echo "🔒 Step 8: Enabling linger..."
sudo loginctl enable-linger "${USER}" 2>/dev/null || true

# ── Done ──
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║   ✅ Setup Complete!                          ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║   Start services:                             ║"
echo "║     systemctl --user start hermes-dashboard   ║"
echo "║     systemctl --user start hermes-gateway     ║"
echo "║     systemctl --user start hermes-webhook     ║"
echo "║                                               ║"
echo "║   Dashboard: http://<your-ip>:9119            ║"
echo "║   Webhook:   http://<your-ip>:9120            ║"
echo "║                                               ║"
echo "║   URL:      https://sofan-ai.space-z.ai/      ║"
echo "║   Login:    admin / ZROPYofOkatPbxuB          ║"
echo "╚═══════════════════════════════════════════════╝"
