// Lazily-spawn Hermes + Sofan webhook on first request.
// The route handlers call ensureServices() before forwarding, so the
// published workspace is fully self-contained (services auto-start
// on boot, no external dependencies).
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, appendFileSync, createWriteStream } from 'node:fs';
import { join } from 'node:path';

const HOME = process.env.HOME; // auto-detected from environment
const LOG_DIR = join(HOME, '.hermes', 'logs');
if (!existsSync(LOG_DIR)) mkdirSync(LOG_DIR, { recursive: true });

let spawnPromise = null;

export async function isPortUp(port) {
  try {
    const r = await fetch(`http://127.0.0.1:${port}/`, { method: 'GET', signal: AbortSignal.timeout(800) });
    return r.status < 500;
  } catch { return false; }
}

function pipeTo(child, logPath) {
  const out = createWriteStream(logPath, { flags: 'a' });
  child.stdout?.pipe(out);
  child.stderr?.pipe(out);
}

function spawnHermes() {
  const hermesBin = join(HOME, '.hermes', 'hermes-agent', '.venv', 'bin', 'hermes');
  const hermesDir = join(HOME, '.hermes', 'hermes-agent');
  if (!existsSync(hermesBin)) return;
  const log = join(LOG_DIR, 'hermes-dashboard.log');
  const child = spawn(hermesBin, [
    'dashboard', '--port', '9119', '--host', '127.0.0.1', '--skip-build', '--no-open',
  ], {
    cwd: hermesDir,
    env: { ...process.env, UV_CACHE_DIR: join(HOME, '.cache', 'uv') },
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: true,
  });
  pipeTo(child, log);
  child.on('error', (e) => { try { appendFileSync(log, `[spawn error] ${e}\n`); } catch {} });
  child.unref();
}

function spawnWebhook() {
  const script = new URL('../sofan-ai-fresh/webhook-server.py', import.meta.url).pathname;
  if (!existsSync(script)) return;
  const log = join(LOG_DIR, 'sofan-webhook.log');
  const child = spawn('python3', [script], {
    cwd: new URL('../sofan-ai-fresh', import.meta.url).pathname,
    env: { ...process.env, WEBHOOK_PORT: '9120' },
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: true,
  });
  pipeTo(child, log);
  child.on('error', (e) => { try { appendFileSync(log, `[spawn error] ${e}\n`); } catch {} });
  child.unref();
}

async function waitForPort(port) {
  for (let i = 0; i < 40; i++) {
    if (await isPortUp(port)) return true;
    await new Promise((r) => setTimeout(r, 800));
  }
  return false;
}

export async function ensureServices() {
  if (spawnPromise) return spawnPromise;
  spawnPromise = (async () => {
    const tasks = [];
    if (!(await isPortUp(9119))) {
      spawnHermes();
      tasks.push(waitForPort(9119));
    }
    if (!(await isPortUp(9120))) {
      spawnWebhook();
      tasks.push(waitForPort(9120));
    }
    await Promise.all(tasks);
  })();
  return spawnPromise;
}
