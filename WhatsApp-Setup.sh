#!/usr/bin/env bash
# Hermes Agent - WhatsApp QR Pairing Script
# Run this script in an interactive terminal to connect WhatsApp
set -e

HERMES_HOME="${HOME}/.hermes"
HERMES_AGENT="${HERMES_HOME}/hermes-agent"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          Sofan AI - Hermes WhatsApp Setup                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This will generate a QR code for WhatsApp Web pairing."
echo "Open WhatsApp on your phone → Menu → Linked Devices → Link a Device"
echo "Then scan the QR code shown below."
echo ""
echo "Starting Hermes WhatsApp pairing..."
echo ""

cd "${HERMES_AGENT}"
uv run hermes whatsapp
