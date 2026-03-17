import puppeteer from 'puppeteer';
import { fileURLToPath } from 'url';
import { dirname, join, resolve } from 'path';
import { existsSync, mkdirSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, '..');
const htmlFile = join(projectRoot, 'public', 'chrome-store-assets.html');
const outputDir = join(projectRoot, 'store-assets', 'chrome');

if (!existsSync(outputDir)) mkdirSync(outputDir, { recursive: true });

const ASSETS = [
  {
    id: 'css-1',    name: 'screenshot-01-live-map.png',
    label: 'Screenshot 1 — Live Map',
    vpW: 640,  vpH: 400, dpr: 2,
    expW: 1280, expH: 800,
  },
  {
    id: 'css-2',    name: 'screenshot-02-home.png',
    label: 'Screenshot 2 — Home Dashboard',
    vpW: 640,  vpH: 400, dpr: 2,
    expW: 1280, expH: 800,
  },
  {
    id: 'css-3',    name: 'screenshot-03-swarms.png',
    label: 'Screenshot 3 — Swarms',
    vpW: 640,  vpH: 400, dpr: 2,
    expW: 1280, expH: 800,
  },
  {
    id: 'css-4',    name: 'screenshot-04-profile-xp.png',
    label: 'Screenshot 4 — Profile & XP',
    vpW: 640,  vpH: 400, dpr: 2,
    expW: 1280, expH: 800,
  },
  {
    id: 'css-5',    name: 'screenshot-05-chat.png',
    label: 'Screenshot 5 — Chat',
    vpW: 640,  vpH: 400, dpr: 2,
    expW: 1280, expH: 800,
  },
  {
    id: 'promo-sm', name: 'promo-small-440x280.png',
    label: 'Small Promo Image',
    vpW: 440,  vpH: 280, dpr: 1,
    expW: 440,  expH: 280,
  },
  {
    id: 'promo-lg', name: 'promo-marquee-1400x560.png',
    label: 'Marquee Promo Image',
    vpW: 700,  vpH: 280, dpr: 2,
    expW: 1400, expH: 560,
  },
  {
    id: 'icon-128', name: 'icon-128x128.png',
    label: 'Extension Icon',
    vpW: 128,  vpH: 128, dpr: 1,
    expW: 128,  expH: 128,
  },
];

console.log('\n=== Barfliz — Chrome Web Store Asset Export ===');
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

let lastDpr = null;
let page = null;

async function getPage(dpr) {
  if (!page || lastDpr !== dpr) {
    if (page) await page.close();
    page = await browser.newPage();
    const maxVpW = Math.max(...ASSETS.map(a => a.vpW));
    const maxVpH = Math.max(...ASSETS.map(a => a.vpH));
    await page.setViewport({ width: maxVpW, height: maxVpH, deviceScaleFactor: dpr });
    const fileUrl = `file://${htmlFile}`;
    await page.goto(fileUrl, { waitUntil: 'networkidle0' });
    await new Promise(r => setTimeout(r, 500));
    lastDpr = dpr;
  }
  return page;
}

for (const asset of ASSETS) {
  const pg = await getPage(asset.dpr);

  const el = await pg.$(`#${asset.id}`);
  if (!el) {
    console.error(`  SKIP  — #${asset.id} not found`);
    continue;
  }

  const outPath = join(outputDir, asset.name);
  await el.screenshot({ path: outPath, type: 'png' });

  const box = await el.boundingBox();
  const actualW = Math.round((box?.width  ?? 0) * asset.dpr);
  const actualH = Math.round((box?.height ?? 0) * asset.dpr);
  const sizeOk = actualW === asset.expW && actualH === asset.expH;

  console.log(
    `  ${sizeOk ? 'OK ' : 'WARN'} — ${asset.label.padEnd(32)} → ${asset.name}  (${actualW} × ${actualH})`
  );
}

if (page) await page.close();
await browser.close();

console.log('\nDone! Files ready for Chrome Web Store upload:');
console.log('\n  Screenshots (1280×800):');
for (const a of ASSETS.filter(a => a.expW === 1280)) {
  console.log(`    store-assets/chrome/${a.name}`);
}
console.log('\n  Promotional Images:');
for (const a of ASSETS.filter(a => a.id.startsWith('promo'))) {
  console.log(`    store-assets/chrome/${a.name}  (${a.expW}×${a.expH})`);
}
console.log('\n  Icon:');
for (const a of ASSETS.filter(a => a.id === 'icon-128')) {
  console.log(`    store-assets/chrome/${a.name}  (${a.expW}×${a.expH})`);
}

console.log('\nRequirements checklist:');
console.log('  Screenshots  : PNG 24-bit, no alpha, 1280×800 (min 1, max 5)');
console.log('  Small promo  : PNG or JPEG, no alpha, 440×280 (required)');
console.log('  Marquee promo: PNG or JPEG, no alpha, 1400×560 (for featured placement)');
console.log('  Icon         : PNG with alpha, 128×128 (96×96 art + 16px padding)\n');
