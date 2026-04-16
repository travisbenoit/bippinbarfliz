# Solana Mobile Builder Grant — LUSH / Barfliz Application Draft

**Program:** Solana Mobile Builder Grants
**Apply at:** https://solanamobile.com/grants | https://docs.solanamobile.com/grants
**Amount:** Up to $10,000
**Bonus:** dApp Store placement, co-marketing, technical support

---

## Project Name
Barfliz — Mobile Nightlife App with LUSH Token

## Category
Consumer Social / Location-Based / Mobile-First

## One-Line Description
A GPS-powered nightlife social app that mints Solana SPL tokens when users physically check into venues and burns them on virtual gift purchases — built mobile-first with invisible crypto UX.

## Why This Is a Mobile App

Barfliz is fundamentally a mobile experience. Every core feature depends on the user being out in the real world with their phone:

1. **GPS Geofencing** — The primary earn mechanic (LUSH minting) requires the user to be physically present at a venue, verified by Radar.io geofencing on their mobile device.
2. **Real-Time Social** — "The Room" (venue chat), Swarm coordination, and virtual gifts are used in the moment, at venues, on phones.
3. **Camera Integration** — Photo moments, profile pictures, and venue photos are captured on-device.
4. **Push Notifications** — Gift receipts, Swarm invitations, venue activity alerts.
5. **Offline Resilience** — PWA with service worker for intermittent connectivity in crowded venues.

### Mobile Deployment
| Platform | Technology |
|----------|-----------|
| **PWA** | Vite + React + TypeScript with service worker |
| **iOS** | Capacitor native shell |
| **Android** | Capacitor native shell |
| **Mobile Wallets** | Privy embedded wallets (created on signup, invisible to user) |

The app does not have a desktop version. It is designed for phones, used at venues, at night.

## Solana Integration

### LUSH Token (SPL)
- **Standard:** SPL Token, 0 decimals (whole coins only)
- **Mint:** Server-side via Supabase Edge Functions when GPS check-in is verified
- **Burn:** Server-side when user purchases virtual gift
- **Wallet:** Privy embedded wallet (MPC, non-custodial) — created silently on signup
- **UX:** User sees "Lush Coins: 47" — never sees wallet address, gas, or chain name

### USDC on Solana
- Peer-to-peer payments between friends
- Tab splitting for groups
- Future: LUSH pack purchases, venue drink redemptions

### Feature Flag
`VITE_CRYPTO_ENABLED` — when disabled, the app falls back to database-only accounting with identical UX. This ensures the app works even if Solana has network issues.

## dApp Store Opportunity

Barfliz is an ideal dApp Store listing because:
1. **Consumer-facing** — targets 21-35 year olds going out at night, not crypto natives
2. **Location-based** — unique among dApp Store listings (most are DeFi/NFT)
3. **Invisible crypto** — demonstrates that Solana apps can look and feel like normal apps
4. **Social** — network effects drive organic growth and dApp Store engagement
5. **Nightlife vertical** — completely uncontested category in the dApp Store

## Current Status
- **App:** v1.6.0 live in production
- **Features:** 15+ features, 70+ database tables, 25+ Edge Functions
- **Token:** Deployed on Solana devnet, mint/burn tested
- **Wallets:** Privy integration built
- **Platforms:** PWA + iOS + Android via Capacitor

## Use of Funds ($10,000)
| Item | Cost |
|------|------|
| Solana mainnet token deployment | $500 |
| Privy production tier (mobile wallet optimization) | $2,000 |
| Mobile performance optimization (Solana SDK bundle size, lazy loading) | $1,500 |
| Capacitor native plugin development (push notifications for on-chain events) | $1,500 |
| dApp Store listing preparation and optimization | $1,000 |
| User acquisition in launch market (Miami) | $2,500 |
| Reserve | $1,000 |
| **Total** | **$10,000** |

## Team
- **Travis Benoit** — Founder & Lead Developer, Barfliz, Inc.

## Links
- **GitHub:** https://github.com/travisbenoit/bippinbarliz
- **Whitepaper:** LUSH_Whitepaper.html

## Why Solana Mobile Should Fund This
The Solana Mobile vision is crypto apps that feel like normal apps on your phone. Barfliz is that. Users check into bars, earn coins, send gifts — and never know they're using Solana. A nightlife app in the dApp Store would be a category-defining listing that showcases Solana Mobile's thesis: crypto belongs on phones, in the real world, for real people.
