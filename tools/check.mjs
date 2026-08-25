// Headless-Chrome regression suite for the Django site.
//   node tools/check.mjs                      → all 8 pages, exits non-zero on failure
//   PAGES=/san-pham/ node tools/check.mjs     → just one page
//
// Starts `manage.py runserver` on PORT_HTTP if nothing is listening, so there is
// nothing to remember before running it.

import { spawn } from 'node:child_process';
import net from 'node:net';
import os from 'node:os';

const CHROME = process.env.CHROME
  ?? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const PORT_CDP = 9222;
const PORT_HTTP = Number(process.env.PORT_HTTP ?? 8000);
const BASE = `http://127.0.0.1:${PORT_HTTP}`;

const ALL_PAGES = ['/', '/gioi-thieu/', '/thuong-hieu/', '/san-pham/',
  '/hop-tac-dai-ly/', '/hang-chinh-hang/', '/tin-tuc/', '/lien-he/'];

// PAGES=/san-pham/,/tin-tuc/ scopes the run while a page is mid-conversion.
const PAGES = process.env.PAGES
  ? process.env.PAGES.split(',').map(s => s.trim()).filter(Boolean)
  : ALL_PAGES;

// san-pham filter cases: [selector, expected visible SKUs]. Sequential —
// each click layers on the previous state (category and brand are independent axes).
const FILTER_CASES = [
  ['[data-filter="cat"][data-value="quy"]', 5],
  ['[data-filter="brand"][data-value="Daliyuan"]', 1],
  ['[data-filter="cat"][data-value="uong"]', 2],
  ['[data-filter="brand"][data-value="Haochidian"]', 0],
  ['[data-filter="cat"][data-value="all"]', 4],
  ['[data-filter="brand"][data-value="all"]', 17],
];

let failures = 0;
const fail = (msg) => { failures += 1; return msg; };

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
  server = spawn('.venv/Scripts/python.exe', ['manage.py', 'runserver', String(PORT_HTTP), '--noreload'],
    { stdio: 'ignore' });
  await waitPort(PORT_HTTP);
}

const chrome = spawn(CHROME, [
  '--headless=new', `--remote-debugging-port=${PORT_CDP}`,
  '--no-first-run', '--no-default-browser-check',
  // Must be absolute: Chrome exits 21 on a drive-relative path like /tmp/....
  `--user-data-dir=${os.tmpdir()}/ln-chrome-profile`, '--window-size=1280,900',
  'about:blank',
], { stdio: 'ignore' });

const cleanup = () => { try { chrome.kill(); } catch {} try { server?.kill(); } catch {} };
process.on('exit', cleanup);

await waitPort(PORT_CDP);

const { webSocketDebuggerUrl } = await (await fetch(
  `http://127.0.0.1:${PORT_CDP}/json/new?about:blank`, { method: 'PUT' })).json();
const ws = new WebSocket(webSocketDebuggerUrl);
await new Promise(r => ws.addEventListener('open', r));

let id = 0;
const pending = new Map();
const events = [];
ws.addEventListener('message', (m) => {
  const msg = JSON.parse(m.data);
  if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
  else if (msg.method) events.push(msg);
});
const send = (method, params = {}) => new Promise(r => {
  const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params }));
});

await send('Runtime.enable');
await send('Log.enable');
await send('Page.enable');

const evalJs = async (expression) => {
  const r = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (r.result?.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails));
  return r.result.result.value;
};

const goto = async (path) => {
  const status = (await fetch(`${BASE}${path}`, { redirect: 'manual' })).status;
  // fail() only counts; log it too or a wrong URL name is silently invisible.
  if (status !== 200) console.log(fail(`HTTP_${status} ${path}`));
  events.length = 0;
  await send('Page.navigate', { url: `${BASE}${path}` });
  await new Promise(r => setTimeout(r, 900));
};

const consoleErrors = () => events
  .filter(e => e.method === 'Log.entryAdded' && ['error', 'warning'].includes(e.params.entry.level))
  .map(e => `${e.params.entry.level}: ${e.params.entry.text} ${e.params.entry.url ?? ''}`);

console.log('=== per-page checks (1280px) ===');
for (const p of PAGES) {
  await goto(p);
  const d = JSON.parse(await evalJs(`(() => {
    const brokenImg = [...document.images].filter(i => !i.complete || i.naturalWidth === 0).map(i => i.getAttribute('src'));
    const noAlt = [...document.images].filter(i => !i.hasAttribute('alt')).length;
    const overflow = document.documentElement.scrollWidth - document.documentElement.clientWidth;
    return JSON.stringify({ brokenImg, noAlt, overflow, h1: document.querySelectorAll('h1').length });
  })()`));
  const flags = [];
  if (d.brokenImg.length) flags.push(fail(`BROKEN_IMG ${d.brokenImg.join(',')}`));
  if (d.noAlt) flags.push(fail(`NO_ALT ${d.noAlt}`));
  if (d.overflow > 0) flags.push(fail(`H_OVERFLOW ${d.overflow}px`));
  if (d.h1 !== 1) flags.push(fail(`H1_COUNT ${d.h1}`));
  for (const e of consoleErrors()) flags.push(fail(e));
  console.log(`${p.padEnd(24)} ${flags.length ? flags.join(' | ') : 'ok'}`);
}

console.log('\n=== mobile overflow (390x844) ===');
await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
for (const p of PAGES) {
  await goto(p);
  const d = JSON.parse(await evalJs(`(() => {
    const de = document.documentElement;
    const over = de.scrollWidth - de.clientWidth;
    const culprits = over > 0 ? [...document.querySelectorAll('*')]
      .filter(el => el.getBoundingClientRect().right > de.clientWidth + 1)
      .slice(0, 4).map(el => el.tagName.toLowerCase() + (el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\\s+/).join('.') : ''))
      : [];
    const navHidden = getComputedStyle(document.querySelector('.site-nav__links')).display === 'none';
    const fab = getComputedStyle(document.querySelector('.floating-actions')).display;
    const h1 = document.querySelector('h1');
    const nav = document.querySelector('.site-nav');
    return JSON.stringify({ over, culprits, navHidden, fab,
      h1px: h1 ? getComputedStyle(h1).fontSize : null,
      navH: Math.round(nav.getBoundingClientRect().height) });
  })()`));
  const flags = [];
  if (d.over > 0) flags.push(fail(`H_OVERFLOW ${d.over}px [${d.culprits.join(', ')}]`));
  if (!d.navHidden) flags.push(fail('NAV_NOT_COLLAPSED'));
  if (d.fab === 'none') flags.push(fail('FAB_HIDDEN'));
  // The mobile nav must stay one row; wrapping pushes it past ~70px.
  if (d.navH > 72) flags.push(fail(`NAV_WRAPPED ${d.navH}px`));
  console.log(`${p.padEnd(24)} h1=${d.h1px} nav=${d.navH}px ${flags.length ? flags.join(' | ') : 'ok'}`);
}
await send('Emulation.clearDeviceMetricsOverride');

if (PAGES.includes('/san-pham/')) {
console.log('\n=== san-pham filters ===');
await goto('/san-pham/');
for (const [sel, expect] of FILTER_CASES) {
  await evalJs(`document.querySelector(${JSON.stringify(sel)}).click()`);
  const r = JSON.parse(await evalJs(`(() => JSON.stringify({
    count: document.querySelector('[data-count]').textContent,
    visible: [...document.querySelector('[data-product-grid]').children].filter(c => !c.hidden).length,
    gridHidden: document.querySelector('[data-product-grid]').hidden,
    emptyHidden: document.querySelector('[data-empty-state]').hidden,
    pressed: [...document.querySelectorAll('[data-filter]')].filter(b => b.getAttribute('aria-pressed') === 'true').map(b => b.dataset.filter + '=' + b.dataset.value),
  }))()`));
  const ok = Number(r.count) === expect && r.visible === expect
    && r.emptyHidden === (expect > 0) && r.gridHidden === (expect === 0);
  if (!ok) fail(sel);
  console.log(`${ok ? 'PASS' : 'FAIL'} ${sel.padEnd(48)} expect=${expect} count=${r.count} visible=${r.visible} empty=${!r.emptyHidden} [${r.pressed}]`);
}
}

if (PAGES.includes('/')) {
console.log('\n=== nav toggle (390px) ===');
await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true });
await goto('/');
const closed = await evalJs(`getComputedStyle(document.querySelector('.site-nav__links')).display`);
await evalJs(`document.querySelector('.site-nav__toggle').click()`);
const opened = JSON.parse(await evalJs(`JSON.stringify({d: getComputedStyle(document.querySelector('.site-nav__links')).display, a: document.querySelector('.site-nav__toggle').getAttribute('aria-expanded')})`));
const navOk = closed === 'none' && opened.d === 'flex' && opened.a === 'true';
if (!navOk) fail('nav toggle');
console.log(`closed=${closed} -> open=${opened.d} aria-expanded=${opened.a} ${navOk ? 'PASS' : 'FAIL'}`);
}

console.log(`\n${failures === 0 ? 'ALL CHECKS PASSED' : `${failures} CHECK(S) FAILED`}`);
ws.close();
cleanup();
process.exit(failures === 0 ? 0 : 1);
