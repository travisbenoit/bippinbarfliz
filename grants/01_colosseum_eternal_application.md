# Colosseum Eternal — LUSH / Barfliz Application Draft

**Program:** Colosseum Eternal (Perpetual Submission)
**Apply at:** https://colosseum.com/accelerator
**Prize:** $25,000 USDC grant + potential $250,000 accelerator investment

---

## Project Name
Barfliz — LUSH Coin

## One-Line Description
A live nightlife social app with a Solana SPL utility token (LUSH) that rewards real-world venue check-ins verified by GPS geofencing and burns tokens on virtual gift purchases.

## Category
Consumer / Social / DePIN (Decentralized Physical Infrastructure)

## Problem Statement
The $250B global nightlife industry has zero real-time social infrastructure. There is no widely adopted app that tells you which venues are active *right now*, coordinates group outings, or rewards cross-venue loyalty. Existing solutions (Yelp, Google Maps) show where people *were* — not where they *are* or *are going*.

## Solution
Barfliz is a mobile-first social app for nightlife — a live map with real-time venue activity, GPS-gated venue chat rooms ("The Room"), crew coordination ("Swarms"), and a gamified engagement economy powered by LUSH, an SPL token on Solana.

**LUSH is the economic layer:**
- **Earn:** Users mint LUSH by checking into venues (verified by Radar.io GPS geofencing), maintaining streaks, completing challenges, and participating in social features.
- **Spend:** Users burn LUSH by purchasing virtual gifts (29 items across 5 rarity tiers). Burned tokens are permanently removed from circulation.
- **Two-Token Model:** LUSH handles engagement rewards; USDC handles real-money payments (tab splitting, peer-to-peer transfers).

## What Makes This Different
1. **Product-first, token-second.** Barfliz is live in production (v1.6.0) with 15+ features, 70+ database tables, and 25+ Edge Functions — all built and deployed *before* any token was created. The app works without the blockchain.
2. **Verifiable real-world activity.** Every LUSH mint event is tied to a GPS geofence entry at a registered venue. You can't farm tokens from your couch.
3. **Burn-on-spend deflationary model.** LUSH is consumed, not accumulated. This is arcade tokens, not speculation.
4. **Invisible crypto.** Users see "Lush Coins: 47" — never wallet addresses, gas fees, or transaction hashes. Privy embedded wallets are created silently on signup.

## Technical Stack
| Layer | Technology |
|-------|-----------|
| Frontend | Vite + React + TypeScript (PWA + iOS + Android via Capacitor) |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Edge Functions) |
| Blockchain | Solana (SPL Token, 0 decimals) |
| Wallets | Privy embedded wallets (MPC, non-custodial) |
| Geofencing | Radar.io |
| Venue Data | Google Places + OpenStreetMap |
| Payments | USDC on Solana + Venmo/Beem deep-link |
| Feature Flag | `VITE_CRYPTO_ENABLED` — instant fallback to DB-only accounting |

## Current Status
- **App:** Live in production, fully functional
- **Token:** Deployed on Solana devnet; mint/burn Edge Functions deployed
- **Wallets:** Privy integration built
- **USDC:** Payment flow implemented
- **Architecture:** Feature flag allows instant fallback if Solana is unavailable

## 4-Week Sprint Plan (Eternal Submission)

**Week 1: Mainnet Token Deployment**
- Deploy LUSH SPL token to Solana mainnet
- Configure mint authority keypair in production Supabase secrets
- Verify mint/burn Edge Functions against mainnet
- End-to-end testing of earn → mint → spend → burn flow

**Week 2: Wallet & UX Polish**
- Privy embedded wallet production configuration
- LUSH balance display optimization (real-time updates via Solana websocket)
- Gift purchase flow with on-chain burn confirmation
- USDC on-ramp integration for peer-to-peer payments

**Week 3: Launch Market Activation**
- Activate LUSH in target markets (Miami, Austin, Nashville)
- Venue partner onboarding (initial 10-20 venues per city)
- User acquisition campaign targeting nightlife-active demographics
- App Store / Google Play submission with crypto features enabled

**Week 4: Analytics & Iteration**
- Token economics monitoring dashboard (mint rate, burn rate, net supply)
- User engagement analytics (check-in frequency, gift send rate, LUSH velocity)
- Adjust earn/burn ratios based on real data
- Document learnings for Colosseum submission

## Team
- **Travis Benoit** — Founder & Lead Developer, Barfliz, Inc.
- Full-stack development (React, TypeScript, Supabase, Solana)
- Designed and built the entire Barfliz platform

## Funding Use
| Item | Amount |
|------|--------|
| Solana mainnet deployment & transaction costs | $2,000 |
| Privy embedded wallet production tier | $3,000 |
| Radar.io geofencing API (production scale) | $3,000 |
| Venue partner onboarding incentives | $5,000 |
| User acquisition (target markets) | $7,000 |
| Legal review (token classification, compliance) | $3,000 |
| Reserve for infrastructure scaling | $2,000 |
| **Total** | **$25,000** |

## Links
- **GitHub:** https://github.com/travisbenoit/bippinbarliz
- **Whitepaper:** Available in repository (LUSH_Whitepaper.html)
- **Supabase Project:** yfucglycufjwmcuadace

## Why Colosseum Should Pick Barfliz
Most hackathon submissions are prototypes. Barfliz is a **live production application** with a complete feature set, real geofencing infrastructure, and a thoughtful tokenomics model backed by a 16-section whitepaper. LUSH solves the cold-start problem for social apps — it gives users a reason to show up, check in, and engage. The burn-on-spend model ensures the token economy is sustainable without relying on speculation. This is crypto that works because users never know it's crypto.
