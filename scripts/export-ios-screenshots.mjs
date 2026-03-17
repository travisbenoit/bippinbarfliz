import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import { dirname, join, resolve } from 'path';
import { existsSync, mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '..');
const htmlFile = join(projectRoot, 'public', 'ios-screenshots.html');
const outputDir = join(projectRoot, 'store-assets', 'ios');

if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

const SCREENS = [
  { id: 'ss-1', name: '01-home.png',    label: 'Home Dashboard' },
  { id: 'ss-2', name: '02-map.png',     label: 'Live Map' },
  { id: 'ss-3', name: '03-swarms.png',  label: 'Swarms' },
  { id: 'ss-4', name: '04-chat.png',    label: 'Chat' },
  { id: 'ss-5', name: '05-profile.png', label: 'Profile & XP' },
];

const TARGET_W = 1320;
const TARGET_H = 2868;
const DPR      = 4;
const VP_W     = TARGET_W / DPR;   // 330
const VP_H     = TARGET_H / DPR;   // 717

console.log('\n=== Barfliz — iOS App Store Screenshot Export ===');
console.log(`Target: ${TARGET_W} × ${TARGET_H} px (DPR ${DPR})`);
console.log(`Output: ${outputDir}\n`);

const browser = await puppeteer.launch({
  headless: 'new',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--font-render-hinting=none',
  ],
});

const page = await browser.newPage();

await page.setViewport({ width: VP_W, height: VP_H, deviceScaleFactor: DPR });

const fileUrl = `file://${htmlFile}`;
await page.goto(fileUrl, { waitUntil: 'networkidle0' });

await page.evaluate(() => new Promise(resolve => {
  if (document.readyState === 'complete') { resolve(); }
  else { window.addEventListener('load', resolve); }
}));

await new Promise(r => setTimeout(r, 600));

for (const screen of SCREENS) {
  const el = await page.$(`#${screen.id}`);
  if (!el) {
    console.error(`  SKIP  — element #${screen.id} not found`);
    continue;
  }
  const outPath = join(outputDir, screen.name);
  await el.screenshot({ path: outPath, type: 'png' });

  const box = await el.boundingBox();
  const actualW = Math.round((box?.width  ?? 0) * DPR);
  const actualH = Math.round((box?.height ?? 0) * DPR);

  const sizeOk = actualW === TARGET_W && actualH === TARGET_H;
  console.log(
    `  ${sizeOk ? 'OK ' : 'WARN'} — ${screen.label.padEnd(20)} → ${screen.name}  (${actualW} × ${actualH})`
  );
}

await browser.close();

console.log('\nDone! Upload these files to App Store Connect:');
for (const s of SCREENS) {
  console.log(`  store-assets/ios/${s.name}`);
}
console.log('\nRequirements checklist:');
console.log('  Format  : PNG');
console.log('  Size    : 1320 × 2868 px (iPhone 6.9" required)');
console.log('  Color   : RGB — no alpha');
console.log('  Max     : 10 MB per file');
console.log('  Quantity: 5 screenshots (1–10 allowed)\n');
