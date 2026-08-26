// Screenshot a page at an exact viewport, via CDP device emulation.
//   node tools/shot.mjs <width> <height> <mobile:true|false> <url-path...>
//   node tools/shot.mjs 390 844 true /tin-tuc/      → <tmpdir>/ln-em-tin-tuc-390.png
//   node tools/shot.mjs 390 844 true /              → <tmpdir>/ln-em-home-390.png
//
// Use this rather than `chrome --headless --screenshot --window-size=...`,
// which silently clips mobile layouts and reports bogus overflow.

import { spawn } from 'node:child_process';
import net from 'node:net';
import os from 'node:os';
import { writeFileSync } from 'node:fs';

const CHROME = process.env.CHROME ?? {
  win32: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  darwin: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
}[process.platform] ?? 'google-chrome';
const PYTHON = process.env.PYTHON
  ?? (process.platform === 'win32' ? '.venv/Scripts/python.exe' : '.venv/bin/python');
const PORT_CDP = 9333;
const PORT_HTTP = Number(process.env.PORT_HTTP ?? 8000);

const [width, height, mobileArg, ...pages] = process.argv.slice(2);
if (!pages.length) {
  console.error('usage: node tools/shot.mjs <width> <height> <mobile:true|false> <page...>');
  process.exit(2);
}
const mobile = mobileArg === 'true';

const portOpen = (port) => new Promise((res) => {
  const s = net.connect(port, '127.0.0.1');
  s.on('connect', () => { s.end(); res(true); });
  s.on('error', () => res(false));
});
const waitPort = (port, ms = 15000) => new Promise((res, rej) => {
  const t = setInterval(async () => {
    if (await portOpen(port)) { clearInterval(t); res(); }
  }, 200);
  setTimeout(() => { clearInterval(t); rej(new Error(`timeout waiting for :${port}`)); }, ms);
});

let server = null;
if (!(await portOpen(PORT_HTTP))) {
  server = spawn(PYTHON, ['manage.py', 'runserver', String(PORT_HTTP), '--noreload'],
    { stdio: 'ignore' });
  await waitPort(PORT_HTTP);
}

const chrome = spawn(CHROME, ['--headless=new', `--remote-debugging-port=${PORT_CDP}`,
  // Must be absolute: Chrome exits 21 on a drive-relative path like /tmp/....
  '--no-first-run', `--user-data-dir=${os.tmpdir()}/ln-chrome-shot`, 'about:blank'], { stdio: 'ignore' });
await waitPort(PORT_CDP);

const { webSocketDebuggerUrl } = await (await fetch(
  `http://127.0.0.1:${PORT_CDP}/json/new?about:blank`, { method: 'PUT' })).json();
const ws = new WebSocket(webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r));
let id = 0; const pending = new Map();
ws.addEventListener('message', m => {
  const x = JSON.parse(m.data);
  if (x.id && pending.has(x.id)) { pending.get(x.id)(x); pending.delete(x.id); }
});
const send = (method, params = {}) => new Promise(r => {
  const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params }));
});

await send('Page.enable');
for (const page of pages) {
  const name = page.replace(/^\/+|\/+$/g, '').replace(/\//g, '-') || 'home';
  await send('Emulation.setDeviceMetricsOverride', {
    width: Number(width), height: Number(height), deviceScaleFactor: 2, mobile,
  });
  await send('Page.navigate', { url: `http://127.0.0.1:${PORT_HTTP}${page.startsWith('/') ? page : '/' + page}` });
  await new Promise(r => setTimeout(r, 800));

  const over = await send('Runtime.evaluate', {
    expression: 'document.documentElement.scrollWidth - document.documentElement.clientWidth',
    returnByValue: true,
  });
  const shot = await send('Page.captureScreenshot', { format: 'png' });
  const out = `${os.tmpdir()}/ln-em-${name}-${width}.png`;
  writeFileSync(out, Buffer.from(shot.result.data, 'base64'));
  console.log(`${out}  overflow=${over.result.result.value}px`);
}

ws.close();
chrome.kill();
server?.kill();
