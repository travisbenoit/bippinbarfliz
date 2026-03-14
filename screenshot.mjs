import { chromium } from 'playwright';
import { mkdir } from 'fs/promises';

const SUPABASE_URL = 'https://yfucglycufjwmcuadace.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmdWNnbHljdWZqd21jdWFkYWNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyNDc0MTcsImV4cCI6MjA4NzgyMzQxN30.1aC4j5kzZwAi9AJDuEoc55glGsYomOF_JVOkddiWroI';
const VIEWPORT = { width: 430, height: 932 };
const OUT = './screenshots';

await mkdir(OUT, { recursive: true });

const browser = await chromium.launch({ headless: true });
const ctx = await browser.newContext({
  viewport: VIEWPORT,
  deviceScaleFactor: 3,
  userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
  locale: 'en-US',
  geolocation: { latitude: 26.1003, longitude: -80.3882 },
  permissions: ['geolocation'],
});
const page = await ctx.newPage();

await page.goto('http://localhost:5173/', { waitUntil: 'networkidle' });
await page.waitForTimeout(1500);
await page.screenshot({ path: `${OUT}/01_signin.png` });
console.log('✓ 01_signin');

// Auth via browser fetch (uses browser DNS stack)
const session = await page.evaluate(async ({ url, key }) => {
  // Try login first
  try {
    const r = await fetch(`${url}/auth/v1/token?grant_type=password`, {
      method: 'POST',
      headers: { 'apikey': key, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'demo@barfliz.app', password: 'Barfliz2026!' }),
    });
    const data = await r.json();
    if (data.access_token) return data;
  } catch {}

  // Try sign-up (gets token if email confirm is disabled)
  try {
    const r = await fetch(`${url}/auth/v1/signup`, {
      method: 'POST',
      headers: { 'apikey': key, 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'demo@barfliz.app', password: 'Barfliz2026!' }),
    });
    const data = await r.json();
    if (data.access_token) return data;
    return { error: JSON.stringify(data).substring(0, 200) };
  } catch (e) {
    return { error: e.message };
  }
}, { url: SUPABASE_URL, key: ANON_KEY });

console.log('Auth result:', session?.access_token ? 'GOT SESSION' : session?.error || 'no token');

if (session?.access_token) {
  await page.evaluate(({ sess }) => {
    localStorage.setItem('sb-yfucglycufjwmcuadace-auth-token', JSON.stringify({
      access_token: sess.access_token,
      refresh_token: sess.refresh_token,
      expires_at: Math.floor(Date.now() / 1000) + 3600,
      token_type: 'bearer',
      user: sess.user,
    }));
    localStorage.setItem('age_verified', 'true');
    localStorage.setItem('onboarding_complete', 'true');
    localStorage.setItem('location_permission', 'granted');
    localStorage.setItem('userCountryCode', 'US');
  }, { sess: session });

  const routes = [
    ['/', '02_home', 3000],
    ['/map', '03_map', 4000],
    ['/swarms', '04_swarms', 2500],
    ['/messages', '05_messages', 2500],
    ['/friends', '06_friends', 2500],
    ['/profile', '07_profile', 2500],
    ['/payments', '08_payments', 2500],
  ];

  for (const [route, name, wait] of routes) {
    await page.goto(`http://localhost:5173${route}`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(wait);
    await page.screenshot({ path: `${OUT}/${name}.png` });
    console.log(`✓ ${name}`);
  }
} else {
  console.log('Skipping authenticated screens.');
}

await browser.close();
console.log(`\nDone — check ${OUT}/`);
