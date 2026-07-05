#!/usr/bin/env python3
"""
Sofan Business AI - Webhook API Server
Acts as bridge between the website contact form and Hermes Agent.
Listens on port 9120 for POST requests from the website.
"""
import os
import sys
import json
import asyncio
import subprocess
from datetime import datetime

HERMES_AGENT = os.path.expanduser("~/.hermes/hermes-agent")
HERMES_HOME = os.path.expanduser("~/.hermes")

try:
    from aiohttp import web
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "aiohttp"], check=True)
    from aiohttp import web

LOG_FILE = os.path.join(HERMES_HOME, "webhook-messages.jsonl")

def log_message(direction, data):
    entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "direction": direction,
        "data": data
    }
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")

async def handle_contact_form(request):
    """Handle contact form submissions from the website."""
    try:
        data = await request.json()
    except Exception:
        data = await request.post()
        data = dict(data)

    log_message("inbound", data)

    # Send notification to admin
    name = data.get("name", data.get("fullName", "Unknown"))
    email = data.get("email", "N/A")
    phone = data.get("phone", data.get("phoneNumber", "N/A"))
    service = data.get("service", "N/A")
    message = data.get("message", data.get("projectDetails", "N/A"))
    budget = data.get("budget", data.get("budgetRange", "N/A"))

    response_text = (
        f"📩 *New Website Inquiry*\n"
        f"*Name:* {name}\n"
        f"*Email:* {email}\n"
        f"*Phone:* {phone}\n"
        f"*Service:* {service}\n"
        f"*Budget:* {budget}\n"
        f"*Message:* {message}"
    )

    log_message("notification", {"text": response_text})

    return web.json_response({
        "status": "received",
        "message": "Thank you! We'll get back to you shortly.",
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })

async def handle_chat_message(request):
    """Handle AI chat messages from the website widget."""
    try:
        data = await request.json()
    except Exception:
        return web.json_response({"error": "invalid JSON"}, status=400)

    log_message("chat_inbound", data)
    message = data.get("message", "")

    # Forward to Hermes via subprocess (oneshot)
    try:
        result = subprocess.run(
            ["uv", "run", "hermes", "chat", "-q", message,
             "--model", "gemini-2.5-flash", "--provider", "gemini", "-Q"],
            cwd=HERMES_AGENT,
            capture_output=True, text=True, timeout=60,
            env={**os.environ, "HERMES_HOME": HERMES_HOME}
        )
        reply = result.stdout.strip() or "I'll connect you with our team shortly."
    except Exception as e:
        reply = "I'll connect you with our team shortly."

    log_message("chat_outbound", {"reply": reply})

    return web.json_response({
        "reply": reply,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })

async def handle_health(request):
    return web.json_response({"status": "ok", "service": "sofan-webhook"})

async def handle_messages(request):
    """Return message history."""
    messages = []
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE) as f:
            for line in f:
                line = line.strip()
                if line:
                    messages.append(json.loads(line))
    return web.json_response(messages[-100:])

app = web.Application()
app.router.add_post("/webhook/contact", handle_contact_form)
app.router.add_post("/webhook/chat", handle_chat_message)
app.router.add_get("/webhook/health", handle_health)
app.router.add_get("/webhook/messages", handle_messages)

if __name__ == "__main__":
    port = int(os.environ.get("WEBHOOK_PORT", "9120"))
    print(f"Sofan Webhook API running on http://0.0.0.0:{port}")
    print(f"Endpoints:")
    print(f"  POST /webhook/contact  - Contact form submissions")
    print(f"  POST /webhook/chat     - Chat messages")
    print(f"  GET  /webhook/health   - Health check")
    print(f"  GET  /webhook/messages - Message history")
    web.run_app(app, host="0.0.0.0", port=port)
