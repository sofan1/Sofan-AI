// Upstream targets — both run inside this same workspace, so the
// published URL is fully self-contained (no external dependencies).
export const HERMES_TARGET = 'http://127.0.0.1:9119';   // Hermes Agent dashboard + built-in webhooks/channels
export const WEBHOOK_TARGET = 'http://127.0.0.1:9120';  // Sofan custom webhook server (contact form, chat, messages)

// Routes prefixed with this go to the Sofan webhook server.
export const WEBHOOK_PREFIX = 'webhook';

export function pickTarget(pathStr) {
  const seg = pathStr.split('/')[0] || '';
  return seg === WEBHOOK_PREFIX ? WEBHOOK_TARGET : HERMES_TARGET;
}
