/**
 * Generate Barfliz Investor Pitch Deck (.pptx)
 * Run: node scripts/generate-pitch-deck.mjs
 */
import PptxGenJS from 'pptxgenjs';

const pptx = new PptxGenJS();

// Brand colors
const PINK = 'E91E63';
const DARK = '1A1A2E';
const DARKER = '0F0F1E';
const WHITE = 'FFFFFF';
const GRAY = 'B0B0B0';
const LIGHT_PINK = 'F8BBD0';
const GREEN = '4CAF50';
const BLUE = '2196F3';
const GOLD = 'FFD700';

pptx.author = 'Barfliz';
pptx.company = 'Barfliz Inc.';
pptx.subject = 'Investor Pitch — LUSH Token Economics';
pptx.title = 'Barfliz — Investor Pitch Deck';
pptx.layout = 'LAYOUT_WIDE'; // 13.33 x 7.5

function addBackground(slide) {
  slide.background = { color: DARK };
}

function titleText(slide, text, opts = {}) {
  slide.addText(text, {
    x: 0.8, y: 0.4, w: 11.7, h: 0.8,
    fontSize: 32, bold: true, color: PINK,
    fontFace: 'Arial',
    ...opts,
  });
}

function bodyText(slide, text, opts = {}) {
  slide.addText(text, {
    x: 0.8, y: 1.5, w: 11.7, h: 5,
    fontSize: 16, color: WHITE,
    fontFace: 'Arial', valign: 'top',
    lineSpacingMultiple: 1.3,
    ...opts,
  });
}

function footerBar(slide) {
  slide.addText('BARFLIZ  |  Confidential', {
    x: 0, y: 6.9, w: 13.33, h: 0.5,
    fontSize: 10, color: GRAY, align: 'center',
    fontFace: 'Arial',
  });
}

// ─── SLIDE 1: Title ───
{
  const s = pptx.addSlide();
  addBackground(s);
  s.addText('BARFLIZ', {
    x: 0, y: 1.5, w: 13.33, h: 1.5,
    fontSize: 72, bold: true, color: PINK,
    fontFace: 'Arial', align: 'center',
  });
  s.addText('Real-Time Nightlife Social App\nPowered by LUSH Token on Solana', {
    x: 0, y: 3.2, w: 13.33, h: 1.2,
    fontSize: 24, color: WHITE,
    fontFace: 'Arial', align: 'center',
    lineSpacingMultiple: 1.4,
  });
  s.addText('Investor Pitch  •  March 2026  •  v1.6.0', {
    x: 0, y: 5, w: 13.33, h: 0.6,
    fontSize: 16, color: GRAY,
    fontFace: 'Arial', align: 'center',
  });
  footerBar(s);
}

// ─── SLIDE 2: The Problem ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'The Problem');
  s.addText('$250B+ global nightlife industry has\nzero social infrastructure.', {
    x: 0.8, y: 1.4, w: 11.7, h: 1,
    fontSize: 22, bold: true, color: LIGHT_PINK,
    fontFace: 'Arial',
  });
  const bullets = [
    'No app tells you which bar is actually popping right now',
    'No way to coordinate a crew without 47 group texts',
    'No loyalty/rewards system spans across venues',
    'Venue owners have zero visibility into their crowd',
    'Instagram & Snapchat show where people were, not where they are',
  ];
  s.addText(bullets.map(b => ({ text: b, options: { bullet: true, color: WHITE } })), {
    x: 1.2, y: 2.6, w: 10.5, h: 4,
    fontSize: 18, fontFace: 'Arial',
    lineSpacingMultiple: 1.6,
    color: WHITE,
  });
  footerBar(s);
}

// ─── SLIDE 3: The Product ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'The Product — v1.5.0 (Live)');
  const rows = [
    [
      { text: 'Feature', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Description', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Live Map', 'Radar.io geofenced venues with real-time occupancy'],
    ['The Room', 'GPS-gated venue hub: live chat, vibe polls, photo moments'],
    ['Swarms', 'Crew coordination: plan nights, RSVP, group chat, split tabs'],
    ['Lush Coins', 'Virtual currency earned via check-ins, streaks, challenges'],
    ['Virtual Gifts', '29 items across 5 rarity tiers — beer to diamonds'],
    ['XP & Streaks', '9 badges, 5 daily challenges, leaderboards'],
    ['Safety', 'Emergency contacts, safe arrival check-in, night routes'],
    ['Payments', 'Venmo/Beem integration, group tab splitting'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 1.4, w: 11.7,
    fontSize: 14, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.5,
    colW: [2.5, 9.2],
    autoPage: false,
  });
  s.addText('Stack: Vite + React + TypeScript  •  Supabase  •  Radar.io  •  Capacitor (iOS/Android)', {
    x: 0.8, y: 6.2, w: 11.7, h: 0.5,
    fontSize: 13, color: GRAY, fontFace: 'Arial',
  });
  footerBar(s);
}

// ─── SLIDE 4: Token Overview ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'LUSH Token Overview');
  const rows = [
    [
      { text: 'Property', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Value', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Name', 'Lush Coin'],
    ['Symbol', 'LUSH'],
    ['Blockchain', 'Solana'],
    ['Standard', 'SPL Token'],
    ['Decimals', '0 (whole coins only)'],
    ['Mint Authority', 'Server-side (Edge Functions)'],
    ['Wallet Provider', 'Privy embedded wallets (email/phone login)'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 1.4, w: 11.7,
    fontSize: 15, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.55,
    colW: [4, 7.7],
  });
  s.addText('Controlled Inflation + Deflationary Burns\nNo fixed supply cap — tokens minted on earn, burned on spend.', {
    x: 0.8, y: 5.8, w: 11.7, h: 0.9,
    fontSize: 15, color: LIGHT_PINK, fontFace: 'Arial', bold: true,
    lineSpacingMultiple: 1.3,
  });
  footerBar(s);
}

// ─── SLIDE 5: Earn Events ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Earn Events (Minting)');
  const rows = [
    [
      { text: 'Event', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'LUSH', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Frequency', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Venue check-in', '10', 'Per venue entry (geofence)'],
    ['First check-in of night', '25', 'Once per night'],
    ['7-night streak', '50', 'Per streak cycle'],
    ['14-night streak', '100', 'Per streak cycle'],
    ['30-night streak', '250', 'Per streak cycle'],
    ['60-night streak', '500', 'Per streak cycle'],
    ['100-night streak', '1,000', 'Per streak cycle'],
    ['Swarm created (3+)', '15', 'Per swarm'],
    ['Cheer sent', '5', 'Per cheer'],
    ['Challenge completed', '25–75', '5 active, 7-day rotation'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 1.3, w: 11.7,
    fontSize: 13, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.45,
    colW: [4, 1.5, 6.2],
  });
  s.addText('Avg user: ~50–80 LUSH/night  •  Power user: ~200–400 LUSH/week', {
    x: 0.8, y: 6.2, w: 11.7, h: 0.5,
    fontSize: 14, color: GOLD, fontFace: 'Arial', bold: true,
  });
  footerBar(s);
}

// ─── SLIDE 6: Spend Events ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Spend Events (Burning)');
  const rows = [
    [
      { text: 'Category', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'LUSH Cost', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Examples', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Common', '10–75', 'Beer (50), Balloon (25), Confetti (50)'],
    ['Rare', '75–150', 'Cocktail (100), Rose (100), Fireworks (150)'],
    ['Epic', '200–250', 'Champagne (200), Bouquet (250), Trophy (200)'],
    ['Legendary', '500–1,000', 'Crown (500), Diamond (1,000)'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 1.4, w: 11.7,
    fontSize: 15, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.6,
    colW: [3, 2.5, 6.2],
  });
  s.addText('29 items total (8 free emoji reactions + 21 paid gifts)\nAvg gift costs ~100 LUSH = 1–2 nights of earning consumed per gift sent', {
    x: 0.8, y: 4.2, w: 11.7, h: 1,
    fontSize: 15, color: LIGHT_PINK, fontFace: 'Arial',
    lineSpacingMultiple: 1.4,
  });
  footerBar(s);
}

// ─── SLIDE 7: Equilibrium Economics ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Equilibrium Economics');
  const metrics = [
    ['Daily mint per active user', '~60 LUSH'],
    ['Daily burn per active user', '~30 LUSH'],
    ['Net daily inflation per user', '~30 LUSH'],
  ];
  metrics.forEach((m, i) => {
    s.addText(m[0], {
      x: 1.5, y: 1.5 + i * 0.8, w: 5, h: 0.6,
      fontSize: 18, color: WHITE, fontFace: 'Arial',
    });
    s.addText(m[1], {
      x: 7, y: 1.5 + i * 0.8, w: 4, h: 0.6,
      fontSize: 18, color: GOLD, fontFace: 'Arial', bold: true,
    });
  });

  s.addShape(pptx.ShapeType.rect, {
    x: 1.2, y: 4, w: 10.9, h: 0.02, fill: { color: '444466' },
  });

  const scale = [
    ['10,000 DAU', '300K minted/day', '150K burned/day'],
    ['100,000 DAU', '3M minted/day', '1.5M burned/day'],
  ];
  scale.forEach((row, i) => {
    s.addText(row[0], {
      x: 1.5, y: 4.4 + i * 0.7, w: 3, h: 0.6,
      fontSize: 16, color: PINK, fontFace: 'Arial', bold: true,
    });
    s.addText(row[1], {
      x: 5, y: 4.4 + i * 0.7, w: 3.5, h: 0.6,
      fontSize: 16, color: GREEN, fontFace: 'Arial',
    });
    s.addText(row[2], {
      x: 9, y: 4.4 + i * 0.7, w: 3.5, h: 0.6,
      fontSize: 16, color: 'FF5722', fontFace: 'Arial',
    });
  });

  s.addText('Key insight: As friend networks grow, gift-sending increases,\napproaching equilibrium. Power users become net deflationary.', {
    x: 0.8, y: 5.9, w: 11.7, h: 0.8,
    fontSize: 14, color: GRAY, fontFace: 'Arial', italic: true,
    lineSpacingMultiple: 1.3,
  });
  footerBar(s);
}

// ─── SLIDE 8: USDC Integration ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'USDC Integration — Two-Token Model');
  s.addText('LUSH = Engagement Token  •  USDC = Payment Token', {
    x: 0.8, y: 1.3, w: 11.7, h: 0.6,
    fontSize: 20, color: GOLD, fontFace: 'Arial', bold: true,
  });
  const rows = [
    [
      { text: 'Use Case', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Token', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Earn via check-ins/streaks', 'LUSH (minted)'],
    ['Send virtual gifts', 'LUSH (burned)'],
    ['Pay friends for drinks', 'USDC (transferred)'],
    ['Split tabs', 'USDC (transferred)'],
    ['Future: Buy LUSH packs', 'USDC → LUSH (treasury)'],
    ['Future: Venue drink redemption', 'LUSH → Venue (settled in USDC)'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 2.1, w: 11.7,
    fontSize: 15, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.55,
    colW: [6, 5.7],
  });
  s.addText('Why USDC? Stablecoin eliminates volatility for real payments.\nUSDC on Solana backed by Visa settlement infrastructure.', {
    x: 0.8, y: 5.8, w: 11.7, h: 0.8,
    fontSize: 14, color: GRAY, fontFace: 'Arial', italic: true,
    lineSpacingMultiple: 1.3,
  });
  footerBar(s);
}

// ─── SLIDE 9: Token Distribution ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Token Distribution at Genesis');
  s.addText('Initial Genesis Mint: 10,000,000 LUSH', {
    x: 0.8, y: 1.3, w: 11.7, h: 0.5,
    fontSize: 18, color: GOLD, fontFace: 'Arial', bold: true,
  });
  const allocs = [
    ['Community Rewards Pool', '40%', 'Ongoing mint for earn events', GREEN],
    ['Team & Founders', '20%', '1-year cliff, 36-month vest', BLUE],
    ['Strategic Partners', '15%', 'Venue onboarding incentives', 'FF9800'],
    ['Treasury Reserve', '15%', 'Market stability, emergencies', 'AB47BC'],
    ['Early Investors', '10%', '6-month cliff, 24-month vest', PINK],
  ];
  allocs.forEach((a, i) => {
    const y = 2.1 + i * 0.9;
    // Color bar
    s.addShape(pptx.ShapeType.rect, {
      x: 0.8, y: y + 0.05, w: 0.3, h: 0.5, fill: { color: a[3] },
    });
    s.addText(a[0], {
      x: 1.4, y, w: 4, h: 0.6,
      fontSize: 16, color: WHITE, fontFace: 'Arial', bold: true,
    });
    s.addText(a[1], {
      x: 5.5, y, w: 1.5, h: 0.6,
      fontSize: 20, color: a[3], fontFace: 'Arial', bold: true,
    });
    s.addText(a[2], {
      x: 7.2, y, w: 5.5, h: 0.6,
      fontSize: 14, color: GRAY, fontFace: 'Arial',
    });
  });
  footerBar(s);
}

// ─── SLIDE 10: User Experience ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Zero-Friction Wallet UX');
  s.addText('"The blockchain is infrastructure, not interface."', {
    x: 0.8, y: 1.3, w: 11.7, h: 0.6,
    fontSize: 18, color: GOLD, fontFace: 'Arial', italic: true,
  });
  const steps = [
    '1. User signs up with phone number (existing auth)',
    '2. Privy auto-creates a Solana wallet (invisible)',
    '3. User sees "Lush Coins: 47" — not "SPL balance: 47"',
    '4. First check-in mints 10 LUSH (they don\'t know it\'s on-chain)',
    '5. Send a gift → burns LUSH → friend sees gift',
    '6. Pay a friend → USDC via card → send in-app',
  ];
  steps.forEach((step, i) => {
    s.addText(step, {
      x: 1.5, y: 2.2 + i * 0.65, w: 10, h: 0.55,
      fontSize: 17, color: WHITE, fontFace: 'Arial',
    });
  });
  s.addText('Users never see wallet addresses, transaction hashes, or gas fees.\nThey see coins, gifts, and payments.', {
    x: 0.8, y: 6, w: 11.7, h: 0.7,
    fontSize: 14, color: LIGHT_PINK, fontFace: 'Arial',
    lineSpacingMultiple: 1.3,
  });
  footerBar(s);
}

// ─── SLIDE 11: Why Solana ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Why Solana');
  const rows = [
    [
      { text: 'Factor', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Solana', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Ethereum', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Base/L2', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Tx Cost', '~$0.003', '$2–15', '$0.01–0.10'],
    ['Confirmation', '400ms', '12s', '2s'],
    ['Token Deploy', '~$2', '$50–200', '$10–50'],
    ['USDC Liquidity', '$8.1B', '$25B', '$3B'],
    ['Mobile UX', 'Best', 'Good', 'Good'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 1.4, w: 11.7,
    fontSize: 15, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.6,
    colW: [3, 2.9, 2.9, 2.9],
  });
  s.addText('Sub-second finality + near-zero fees = invisible to users.\nNo "waiting for confirmation" screens. No $5 gas on a $2 gift.', {
    x: 0.8, y: 5, w: 11.7, h: 0.8,
    fontSize: 15, color: LIGHT_PINK, fontFace: 'Arial',
    lineSpacingMultiple: 1.3,
  });
  footerBar(s);
}

// ─── SLIDE 12: Revenue Model ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Revenue Model');
  const phases = [
    { phase: 'Phase 1 — Free Growth', rev: '$0', desc: 'All features free, LUSH earned organically', color: GRAY },
    { phase: 'Phase 2 — USDC Launch', rev: '$4.5K/mo', desc: '1.5% fee on USDC friend payments (10K DAU)', color: BLUE },
    { phase: 'Phase 3 — Venue Partners', rev: '$74.5K/mo', desc: 'Analytics subscriptions, promoted events (500 venues)', color: GREEN },
    { phase: 'Phase 4 — LUSH Packs', rev: '$149.7K/mo', desc: 'Purchase LUSH with USDC ($0.99–$9.99 packs, 100K DAU)', color: GOLD },
  ];
  phases.forEach((p, i) => {
    const y = 1.4 + i * 1.3;
    s.addText(p.phase, {
      x: 0.8, y, w: 5, h: 0.5,
      fontSize: 17, color: p.color, fontFace: 'Arial', bold: true,
    });
    s.addText(p.rev, {
      x: 6, y, w: 3, h: 0.5,
      fontSize: 22, color: PINK, fontFace: 'Arial', bold: true,
    });
    s.addText(p.desc, {
      x: 0.8, y: y + 0.5, w: 11.7, h: 0.5,
      fontSize: 14, color: GRAY, fontFace: 'Arial',
    });
  });
  footerBar(s);
}

// ─── SLIDE 13: Competitive Landscape ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Competitive Landscape');
  const rows = [
    [
      { text: 'App', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Category', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Token', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Gap', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['Yelp', 'Discovery', 'No', 'No real-time, no social'],
    ['Snap Map', 'Location', 'No', 'Passive — shows history'],
    ['Fever', 'Events', 'No', 'Ticketing only'],
    ['Partiful', 'Events', 'No', 'Invites only, no discovery'],
    ['Rally', 'Social tokens', 'RLY', 'Creator economy, not nightlife'],
    ['FWB', 'Token community', 'FWB', 'Exclusive DAO, not mass-market'],
    [
      { text: 'Barfliz', options: { bold: true, color: PINK } },
      { text: 'Nightlife social', options: { bold: true, color: PINK } },
      { text: 'LUSH', options: { bold: true, color: PINK } },
      { text: 'Real-time + gamification + token + venues', options: { bold: true, color: PINK } },
    ],
  ];
  s.addTable(rows, {
    x: 0.5, y: 1.4, w: 12.3,
    fontSize: 13, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.55,
    colW: [1.8, 2.5, 1.5, 6.5],
  });
  footerBar(s);
}

// ─── SLIDE 14: Traction ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Traction & Metrics (Pre-Launch)');
  const metrics = [
    ['Product', 'v1.5.0 shipped, production DB live'],
    ['Features', '15+ major features, 25+ Edge Functions'],
    ['Database', '70+ tables, full RLS security'],
    ['Platforms', 'PWA + iOS + Android (Capacitor)'],
    ['Geofencing', 'Radar.io integration live'],
    ['Venue Data', 'Google Places + OSM bulk import'],
    ['Auth', 'Phone OTP (Twilio integration ready)'],
    ['Economy', '29 gift items, XP, streaks, badges, challenges, leaderboards'],
  ];
  metrics.forEach((m, i) => {
    const y = 1.4 + i * 0.6;
    s.addText(m[0], {
      x: 0.8, y, w: 2.5, h: 0.5,
      fontSize: 15, color: PINK, fontFace: 'Arial', bold: true,
    });
    s.addText(m[1], {
      x: 3.5, y, w: 9, h: 0.5,
      fontSize: 15, color: WHITE, fontFace: 'Arial',
    });
  });
  footerBar(s);
}

// ─── SLIDE 15: Regulatory ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Regulatory Positioning');
  s.addText('LUSH is a utility token, not a security.', {
    x: 0.8, y: 1.3, w: 11.7, h: 0.6,
    fontSize: 20, color: GOLD, fontFace: 'Arial', bold: true,
  });
  const points = [
    ['No investment of money', 'Users earn LUSH for free by using the app'],
    ['No expectation of profit', 'Earned and spent in-app, not traded on exchanges'],
    ['No common enterprise', 'Value driven by individual engagement'],
    ['Functional utility', 'Immediate use: virtual gifts, features'],
  ];
  points.forEach((p, i) => {
    const y = 2.2 + i * 0.9;
    s.addText(p[0], {
      x: 1.2, y, w: 5, h: 0.5,
      fontSize: 16, color: GREEN, fontFace: 'Arial', bold: true,
    });
    s.addText(p[1], {
      x: 1.2, y: y + 0.4, w: 10, h: 0.4,
      fontSize: 14, color: GRAY, fontFace: 'Arial',
    });
  });
  s.addText('Howey mitigations: No ICO, no exchange listing at launch, burn-on-spend,\nutility-first rollout, Wyoming DUNA consideration for future governance.', {
    x: 0.8, y: 5.8, w: 11.7, h: 0.8,
    fontSize: 13, color: GRAY, fontFace: 'Arial', italic: true,
    lineSpacingMultiple: 1.3,
  });
  footerBar(s);
}

// ─── SLIDE 16: Risks ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'Risks & Mitigations');
  const rows = [
    [
      { text: 'Risk', options: { bold: true, color: DARK, fill: { color: PINK } } },
      { text: 'Mitigation', options: { bold: true, color: DARK, fill: { color: PINK } } },
    ],
    ['SEC token classification', 'Utility-first design, no ICO, no exchange listing'],
    ['Crypto friction (users)', 'Privy embedded wallets — zero crypto UI'],
    ['Token inflation', 'Burn-on-spend model, expanding gift catalog'],
    ['Competition', 'Network effects from social graph + venue community'],
    ['Solana network issues', 'Feature flag — instant fallback to DB-only economy'],
  ];
  s.addTable(rows, {
    x: 0.8, y: 1.4, w: 11.7,
    fontSize: 14, fontFace: 'Arial',
    color: WHITE,
    border: { type: 'solid', pt: 0.5, color: '444466' },
    rowH: 0.7,
    colW: [4, 7.7],
  });
  footerBar(s);
}

// ─── SLIDE 17: The Ask ───
{
  const s = pptx.addSlide();
  addBackground(s);
  titleText(s, 'The Ask');
  s.addText('Seeking seed round to fund:', {
    x: 0.8, y: 1.3, w: 11.7, h: 0.6,
    fontSize: 20, color: WHITE, fontFace: 'Arial',
  });
  const items = [
    ['40%', 'Engineering', 'Solana integration, native app polish, analytics'],
    ['25%', 'Growth', 'City launches, venue partnerships, influencer marketing'],
    ['20%', 'Operations', 'Privy, Solana RPC, Supabase scaling, legal'],
    ['15%', 'Reserve', 'Runway buffer'],
  ];
  items.forEach((item, i) => {
    const y = 2.3 + i * 1;
    s.addText(item[0], {
      x: 1.5, y, w: 1.5, h: 0.6,
      fontSize: 28, color: PINK, fontFace: 'Arial', bold: true,
    });
    s.addText(item[1], {
      x: 3.2, y, w: 3, h: 0.6,
      fontSize: 18, color: WHITE, fontFace: 'Arial', bold: true,
    });
    s.addText(item[2], {
      x: 3.2, y: y + 0.45, w: 8, h: 0.4,
      fontSize: 14, color: GRAY, fontFace: 'Arial',
    });
  });
  s.addText('Target markets: Miami  •  Austin  •  Nashville', {
    x: 0.8, y: 6.2, w: 11.7, h: 0.5,
    fontSize: 16, color: GOLD, fontFace: 'Arial', bold: true,
  });
  footerBar(s);
}

// ─── SLIDE 18: Closing ───
{
  const s = pptx.addSlide();
  addBackground(s);
  s.addText('BARFLIZ', {
    x: 0, y: 1.5, w: 13.33, h: 1,
    fontSize: 60, bold: true, color: PINK,
    fontFace: 'Arial', align: 'center',
  });
  s.addText('The nightlife industry has no social infrastructure.\nWe\'re building it.', {
    x: 0, y: 3, w: 13.33, h: 1.2,
    fontSize: 24, color: WHITE,
    fontFace: 'Arial', align: 'center',
    lineSpacingMultiple: 1.5,
  });
  s.addText('LUSH Coin — earned by showing up, spent on social expression.\nUSDC — real payments. Privy — invisible wallets. Solana — instant and free.', {
    x: 0, y: 4.8, w: 13.33, h: 1,
    fontSize: 16, color: GRAY,
    fontFace: 'Arial', align: 'center',
    lineSpacingMultiple: 1.5,
  });
  footerBar(s);
}

// Write file
const outPath = 'C:/Users/User/Projects/bippinbarliz-main/Barfliz_Investor_Pitch.pptx';
await pptx.writeFile({ fileName: outPath });
console.log(`Pitch deck saved to: ${outPath}`);
