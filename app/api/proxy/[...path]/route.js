import { pickTarget } from '../../_shared';
import { ensureServices } from '../../../../lib/spawn-services.js';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';
export const fetchCache = 'force-no-store';

async function handle(req, context, method) {
  await ensureServices();
  const params = await context.params;
  const pathArr = params?.path || [];
  const pathStr = Array.isArray(pathArr) ? pathArr.join('/') : String(pathArr || '');
  const url = new URL(req.url);
  const target = pickTarget(pathStr);
  const targetUrl = `${target}/${pathStr}${url.search}`;
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
    return new Response(JSON.stringify({ error: String(e), target: targetUrl }), {
      status: 502, headers: { 'Content-Type': 'application/json' }
    });
  }
}

export async function GET(req, ctx) { return handle(req, ctx, 'GET'); }
export async function POST(req, ctx) { return handle(req, ctx, 'POST'); }
export async function PUT(req, ctx) { return handle(req, ctx, 'PUT'); }
export async function DELETE(req, ctx) { return handle(req, ctx, 'DELETE'); }
export async function PATCH(req, ctx) { return handle(req, ctx, 'PATCH'); }
export async function HEAD(req, ctx) { return handle(req, ctx, 'HEAD'); }
export async function OPTIONS(req, ctx) { return handle(req, ctx, 'OPTIONS'); }
