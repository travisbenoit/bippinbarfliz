# Superteam USA Grant — LUSH / Barfliz Application Draft

**Program:** Superteam Earn / Solana Foundation USA Grants
**Apply at:** https://earn.superteam.fun/grants/ | https://us.superteam.fun/
**Amount:** $200 – $15,000+ (equity-free microgrants)
**Turnaround:** 48-72 hours

---

## Project Name
Barfliz — LUSH Coin

## Category
Consumer App / Social / Token Launch

## What are you building?
A nightlife social app with an SPL utility token (LUSH) that rewards GPS-verified venue check-ins and burns tokens on virtual gift purchases. The app is live in production. We need funding to deploy LUSH to Solana mainnet and launch in our first three markets.

## What stage is your project?
**Live in production** — v1.6.0 deployed with 70+ database tables, 25+ Edge Functions, 15+ features. LUSH token is deployed on devnet with mint/burn Edge Functions tested. Ready for mainnet deployment.

## How does it use Solana?
1. **LUSH SPL Token** — Custom SPL token (0 decimals) minted server-side when users check into venues via GPS geofencing. Burned when users purchase virtual gifts.
2. **USDC Transfers** — Peer-to-peer USDC payments for tab splitting and friend-to-friend payments.
3. **Privy Embedded Wallets** — Non-custodial Solana wallets created silently on user signup. Users never see wallet addresses or gas fees.
4. **Feature Flag** — Entire blockchain layer gated by `VITE_CRYPTO_ENABLED`. App works identically with or without Solana.

## What makes this a consumer app?
- Users see "Lush Coins: 47" — never "SPL Token Balance"
- No seed phrases, no wallet setup, no blockchain terminology
- GPS check-in is the primary interaction — same as checking in on Yelp, except you earn tokens
- Virtual gifts are social expression (like Twitch gifts) — earned through engagement, not purchased
- Target audience: 21-35 year olds who go out 2-4 nights per week — they don't need to know what Solana is

## Tech Stack
- Vite + React + TypeScript
- Supabase (PostgreSQL, Auth, Realtime, Edge Functions)
- Solana (SPL Token + USDC)
- Privy (embedded wallets)
- Radar.io (GPS geofencing)
- Google Places + OpenStreetMap
- Capacitor (iOS + Android)

## What will you use the grant for?

### Option A: Microgrant ($5,000) — Mainnet Deployment
| Item | Cost |
|------|------|
| Solana mainnet deployment (token creation, ATA funding) | $500 |
| Privy production tier (first 3 months) | $1,500 |
| Radar.io API costs (production geofencing) | $1,000 |
| Security review of mint/burn Edge Functions | $1,500 |
| Documentation and developer onboarding materials | $500 |
| **Total** | **$5,000** |

### Option B: Standard Grant ($15,000) — Mainnet + Market Launch
| Item | Cost |
|------|------|
| Everything in Option A | $5,000 |
| User acquisition in Miami (first target market) | $4,000 |
| Venue partner onboarding incentives (10-20 venues) | $3,000 |
| Legal review (token classification confirmation) | $2,000 |
| Reserve for infrastructure scaling | $1,000 |
| **Total** | **$15,000** |

## Team
- **Travis Benoit** — Solo founder, designed and built the entire platform
- Full-stack: React, TypeScript, Node.js, PostgreSQL, Solana

## Links
- **GitHub:** https://github.com/travisbenoit/bippinbarliz
- **Whitepaper:** LUSH_Whitepaper.html (16 sections covering tokenomics, legal, architecture)

## Why fund this?
Superteam USA's mission is consumer apps on Solana. Barfliz is exactly that — a live app where crypto is invisible to users. The nightlife vertical is untapped. GPS-verified minting is novel. The product is already built. We just need to flip the switch to mainnet.
