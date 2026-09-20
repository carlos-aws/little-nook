#!/usr/bin/env node
// Real Chromium/WebGL smoke test via CDP. Node 22+, no npm dependencies.
// Run after exporting Web and starting tools/serve.py on port 8081.
import { spawn } from 'node:child_process';
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'tools/out');
await mkdir(out, { recursive: true });
const profile = await mkdtemp(path.join(tmpdir(), 'little-nook-browser-'));
const base = process.env.GAME_URL || 'http://127.0.0.1:8081';
const port = 9337;
const browser = spawn(process.env.CHROMIUM_BIN || 'chromium', [
  '--headless=new', '--no-sandbox', '--disable-dev-shm-usage',
  '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
  '--autoplay-policy=no-user-gesture-required', '--no-first-run',
  '--disable-background-networking', '--disable-component-update',
  `--user-data-dir=${profile}`, `--remote-debugging-port=${port}`,
  '--window-size=1440,900', 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
let browserLog = '';
browser.stderr.on('data', b => { browserLog += b.toString(); });
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
let socket;
const pending = new Map();
let nextId = 0;
const errors = [];
const consoleLines = [];

async function connect() {
  for (let i = 0; i < 80; i++) {
    try {
      const tabs = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
      const tab = tabs.find(t => t.type === 'page');
      if (tab) {
        socket = new WebSocket(tab.webSocketDebuggerUrl);
        await new Promise((resolve, reject) => {
          socket.addEventListener('open', resolve, { once: true });
          socket.addEventListener('error', reject, { once: true });
        });
        socket.addEventListener('message', event => {
          const data = JSON.parse(event.data);
          if (data.id) {
            const p = pending.get(data.id);
            pending.delete(data.id);
            if (data.error) p?.reject(new Error(JSON.stringify(data.error)));
            else p?.resolve(data.result);
          } else if (data.method === 'Runtime.consoleAPICalled') {
            const text = data.params.args.map(a => a.value ?? a.description ?? '').join(' ');
            consoleLines.push(text);
            if (data.params.type === 'error' && !text.includes('WebGL')) errors.push(text);
          } else if (data.method === 'Runtime.exceptionThrown') {
            errors.push(JSON.stringify(data.params.exceptionDetails));
          }
        });
        return;
      }
    } catch {}
    await pause(100);
  }
  throw new Error('Chromium did not start: ' + browserLog);
}
function send(method, params = {}) {
  const id = ++nextId;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`CDP timeout: ${method}`)); }, 20000);
    pending.set(id, {
      resolve: r => { clearTimeout(timer); resolve(r); },
      reject: e => { clearTimeout(timer); reject(e); },
    });
    socket.send(JSON.stringify({ id, method, params }));
  });
}
async function evaluate(expression) {
  const { result, exceptionDetails } = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (exceptionDetails) throw new Error(JSON.stringify(exceptionDetails));
  return result.value;
}
async function waitForGame() {
  for (let i = 0; i < 120; i++) {
    if (await evaluate("!document.getElementById('status') && document.querySelector('canvas')?.width > 0")) {
      await pause(900);
      return;
    }
    await pause(250);
  }
  throw new Error('Game did not finish booting: ' + (await evaluate('document.body.innerText')));
}
async function click(x, y) {
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  await pause(200);
}
async function screenshot(name) {
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  await writeFile(path.join(out, name), Buffer.from(data, 'base64'));
}
async function savedProgress() {
  return evaluate(`(async () => {
    for (const info of await indexedDB.databases()) {
      const db = await new Promise((resolve, reject) => {
        const request = indexedDB.open(info.name);
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      try {
        for (const store of db.objectStoreNames) {
          const records = await new Promise((resolve, reject) => {
            const request = db.transaction(store).objectStore(store).getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
          });
          for (const record of records) {
            try {
              const value = JSON.parse(new TextDecoder().decode(record.contents));
              if (value.version === 1 && value.needs && value.skills) return value;
            } catch {}
          }
        }
      } finally { db.close(); }
    }
    return null;
  })()`);
}

try {
  await connect();
  await send('Page.enable');
  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: base });
  await waitForGame();
  const manifest = await evaluate("fetch('index.manifest.json').then(r => r.json())");
  assert.equal(manifest.orientation, 'landscape');
  assert.equal(manifest.display, 'standalone');
  await screenshot('home.png');
  await click(118, 265); // Lessons.
  await screenshot('lessons.png');
  await click(448, 641); // Begin maths.
  await screenshot('lesson.png');
  // Exercise both retries and the correct answer without hardcoding random content.
  for (let question = 0; question < 3; question++) {
    for (const x of [493, 848, 1203]) await click(x, 658);
    await click(1266, 762);
  }
  await screenshot('reward.png');
  await click(720, 618); // Reward's back-to-home button.
  await click(122, 387); // Shop.
  await click(465, 469); // Starter coins buy a plant.
  await screenshot('shop.png');
  await click(103, 202); // Home shows decoration.
  await screenshot('decorated.png');
  await click(109, 326); // Tidy.
  await screenshot('tidy.png');
  // Exercise the native Godot drag system across the canvas.
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 420, y: 453 });
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 420, y: 453, button: 'left', clickCount: 1 });
  for (let i = 1; i <= 12; i++) {
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 420+i*4, y: 453+i*18, button: 'left', buttons: 1 });
    await pause(20);
  }
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 468, y: 669, button: 'left', clickCount: 1 });
  // Complete tidy using tap selection; each object has exactly one destination.
  for (const x of [420, 591, 762, 933, 1104, 1275]) {
    await click(x, 453);
    for (const bx of [490, 846, 1203]) await click(bx, 685);
  }
  await screenshot('tidy-reward.png');
  await click(720, 618);
  await click(110, 449); // Journal.
  await screenshot('journal.png');
  let saved;
  for (let i = 0; i < 40; i++) {
    saved = await savedProgress();
    if (saved?.completed === 2 && saved?.tidy_count === 1) break;
    await pause(250);
  }
  assert.equal(saved?.completed, 2, 'Both real browser activities finished and saved');
  assert.equal(saved?.tidy_count, 1, 'Tidying completion persisted');
  assert.equal(saved?.stars, 2, 'Each completed activity awarded exactly one star');
  assert(saved.owned.includes('plant'), 'Purchased decoration persisted');
  await click(1389, 46); // Parent gate.
  await click(600, 480);
  for (const digit of ['4', '2']) {
    await send('Input.dispatchKeyEvent', { type: 'keyDown', key: digit, text: digit, code: `Digit${digit}`, windowsVirtualKeyCode: digit.charCodeAt(0) });
    await send('Input.dispatchKeyEvent', { type: 'keyUp', key: digit, code: `Digit${digit}`, windowsVirtualKeyCode: digit.charCodeAt(0) });
  }
  await click(830, 560);
  await screenshot('settings.png');
  await click(802, 692); // Save preferences.
  // Check persistence survives reloading the real WebAssembly game.
  await send('Page.reload');
  await waitForGame();
  await screenshot('reloaded.png');
  assert.deepEqual((await savedProgress()).owned, saved.owned, 'Inventory survives browser reload');
  assert.equal(await evaluate('document.querySelector("canvas").width'), 1440);
  await send('Emulation.setDeviceMetricsOverride', { width: 1024, height: 768, deviceScaleFactor: 1, mobile: true });
  await pause(500);
  await screenshot('tablet.png');
  // Touch event reaches the same home control (logical coordinate transform).
  await send('Emulation.setTouchEmulationEnabled', { enabled: true });
  await send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 85, y: 252 }] });
  await send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await pause(300);
  await screenshot('tablet-touch.png');
  await evaluate("navigator.serviceWorker.ready.then(r => r.active?.state)");
  const cachedGame = await evaluate("(async () => { for (const key of await caches.keys()) { const cache = await caches.open(key); if (await cache.match('index.wasm')) return true; } return false; })()");
  assert(cachedGame, 'Engine is cached before testing offline reload');
  await send('Network.enable');
  await send('Network.emulateNetworkConditions', { offline: true, latency: 0, downloadThroughput: 0, uploadThroughput: 0 });
  await send('Page.reload');
  await waitForGame();
  await screenshot('offline.png');
  await writeFile(path.join(out, 'browser-console.log'), consoleLines.join('\n') + '\n');
  assert.equal(errors.length, 0, 'Browser runtime errors:\n' + errors.join('\n'));
  console.log(`Browser boot, interaction, resize, reload and offline checks passed. Screenshots: ${out}`);
} finally {
  socket?.close();
  browser.kill('SIGTERM');
  await pause(500);
  await rm(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 200 });
}
