import { HERMES_TARGET, WEBHOOK_TARGET } from '../_shared';
import { ensureServices, isPortUp } from '../../../lib/spawn-services.js';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';
export const fetchCache = 'force-no-store';

async function probe(name, url) {
  const start = Date.now();
  try {
    const r = await fetch(url, { method: 'GET', signal: AbortSignal.timeout(3000) });
    return { name, url, ok: r.ok, status: r.status, ms: Date.now() - start };
  } catch (e) {
    return { name, url, ok: false, error: String(e), ms: Date.now() - start };
  }
}

export async function GET() {
  await ensureServices();
  const [hermes, webhook] = await Promise.all([
    probe('hermes', `${HERMES_TARGET}/`),
    probe('webhook', `${WEBHOOK_TARGET}/webhook/health`),
  ]);
  const allOk = hermes.ok && webhook.ok;
  return Response.json({
    status: allOk ? 'ok' : 'degraded',
    published_url_hint: 'Access the dashboard at the root path /',
    services: {
      hermes_dashboard: { ...hermes, target: HERMES_TARGET, description: 'Hermes Agent dashboard + built-in webhooks/channels' },
      sofan_webhook: { ...webhook, target: WEBHOOK_TARGET, description: 'Sofan custom webhook (contact/chat/messages)' },
    },
    routes: {
      '/': 'Hermes dashboard (WebUI)',
      '/webhook/contact': 'POST — Sofan contact form webhook',
      '/webhook/chat': 'POST — Sofan chat message webhook',
      '/webhook/health': 'GET — Sofan webhook health check',
      '/webhook/messages': 'GET — Sofan retrieve messages',
      '/api/status': 'GET — this status page',
    },
  }, { status: allOk ? 200 : 503 });
}
