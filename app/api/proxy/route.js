import { HERMES_TARGET } from '../_shared';
import { ensureServices } from '../../../lib/spawn-services.js';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';
export const fetchCache = 'force-no-store';

// Root path (/) — always goes to Hermes dashboard.
async function handle(req, method) {
  await ensureServices();
  const url = new URL(req.url);
  const targetUrl = `${HERMES_TARGET}/${url.search}`;
  let body = undefined;
  if (method !== 'GET' && method !== 'HEAD') {
    body = Buffer.from(await req.arrayBuffer());
  }
  const headers = new Headers(req.headers);
  headers.delete('host');
  headers.delete('connection');
  headers.delete('content-length');
  try {
    const upstream = await fetch(targetUrl, { method, headers, body, redirect: 'manual' });
    const respHeaders = new Headers(upstream.headers);
    respHeaders.set('Access-Control-Allow-Origin', '*');
    respHeaders.set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,PATCH,HEAD,OPTIONS');
    respHeaders.set('Access-Control-Allow-Headers', '*');
    return new Response(upstream.body, {
      status: upstream.status,
      statusText: upstream.statusText,
      headers: respHeaders,
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 502, headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function GET(req) { return handle(req, 'GET'); }
export async function POST(req) { return handle(req, 'POST'); }
export async function PUT(req) { return handle(req, 'PUT'); }
export async function DELETE(req) { return handle(req, 'DELETE'); }
export async function PATCH(req) { return handle(req, 'PATCH'); }
export async function HEAD(req) { return handle(req, 'HEAD'); }
export async function OPTIONS(req) { return handle(req, 'OPTIONS'); }
