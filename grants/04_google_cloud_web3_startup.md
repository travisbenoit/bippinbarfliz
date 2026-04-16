# Google Cloud Web3 Startup Program — Barfliz Application Draft

**Program:** Google Cloud for Web3 Startups
**Apply at:** https://cloud.google.com/startup/web3
**Amount:** Up to $200,000 in Google Cloud credits + up to $1M in Solana Foundation grants (via partnership)

---

## Company Name
Barfliz, Inc.

## Company Website
https://github.com/travisbenoit/bippinbarliz

## Founding Date
2025

## Stage
Pre-Seed / Bootstrapped with live production product

## Blockchain(s) Used
Solana

## One-Line Description
A live nightlife social app with a Solana SPL utility token (LUSH) for gamified engagement rewards and USDC for peer-to-peer payments, powered by GPS geofencing.

## Product Description

### What is Barfliz?
Barfliz is a mobile-first social application for the nightlife industry. It provides real-time venue discovery, GPS-gated social features, crew coordination, and a token-powered engagement economy.

### Core Features (All Live in Production)
- **Live Map:** Real-time venue activity map with GPS-aware hotspot detection
- **The Room:** GPS-gated venue hubs — live chat, vibe polls, photo moments, "who's here"
- **Swarms:** Group night-out coordination with RSVP, venue selection, group chat, tab splitting
- **LUSH Coins:** SPL utility token earned via GPS check-ins, spent on virtual gifts (burn-on-spend)
- **Virtual Gifts:** 29 items across 5 rarity tiers
- **XP & Achievements:** Gamification system with badges, challenges, leaderboards
- **Safety:** Emergency contacts, safe arrival check-in, night route tracking
- **Payments:** USDC on Solana + Venmo/Beem integration

### Technical Architecture
| Component | Technology |
|-----------|-----------|
| Frontend | Vite + React + TypeScript |
| Mobile | PWA + Capacitor (iOS + Android) |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Edge Functions) |
| Blockchain | Solana (SPL Token + USDC) |
| Wallets | Privy embedded wallets (MPC, non-custodial) |
| Geofencing | Radar.io |
| Venue Data | Google Places API + OpenStreetMap |
| Maps | Google Maps / Mapbox |

### Current Scale
- v1.6.0 in production
- 70+ database tables with Row Level Security
- 25+ Supabase Edge Functions
- 15+ user-facing features
- PWA + iOS + Android deployment

## How We Would Use Google Cloud

### Current Infrastructure Needs
| Service | Use Case |
|---------|----------|
| **Cloud Run** | Containerized Edge Functions for token minting/burning at scale |
| **Cloud SQL** | High-availability PostgreSQL for production database migration |
| **BigQuery** | Token economics analytics — mint rate, burn rate, supply tracking |
| **Cloud CDN** | PWA asset delivery for low-latency mobile experience |
| **Vertex AI** | Venue recommendation engine based on user check-in patterns |
| **Cloud Monitoring** | Real-time alerting on token operations, geofence accuracy, API health |

### Growth Infrastructure
| Service | Use Case |
|---------|----------|
| **Firebase Analytics** | User behavior tracking across PWA/iOS/Android |
| **Cloud Functions** | Webhook processors for Radar.io geofence events |
| **Pub/Sub** | Event-driven architecture for real-time venue activity updates |
| **Cloud Storage** | User-generated content (venue photos, profile images) |

## Solana Foundation Grant Pipeline
This application also positions Barfliz for the Solana Foundation grants available through the Google Cloud partnership (up to $1M). Our Solana integration includes:
- SPL token deployment (LUSH — 0 decimals, mint authority server-side)
- USDC peer-to-peer transfers
- Privy embedded wallets (non-custodial)
- Feature flag architecture for blockchain fallback

## Revenue Model
1. **Venue Analytics Dashboard** — Monthly subscription for venue operators ($99-$499/mo)
2. **LUSH Pack Sales** — Users purchase LUSH with USDC (treasury revenue)
3. **Promoted Events** — Venues/users pay LUSH to feature events in discovery
4. **Premium Features** — Cosmetics, VIP features, enhanced profiles

## Target Markets
Miami, Austin, Nashville — crypto-friendly cities with vibrant nightlife scenes

## Team
- **Travis Benoit** — Founder, CEO & Lead Developer

## Cloud Credits Requested
$200,000 over 2 years (Start tier: $100K Year 1, Scale tier: $100K Year 2)

## Links
- **GitHub:** https://github.com/travisbenoit/bippinbarliz
- **Whitepaper:** LUSH_Whitepaper.html
- **Google Places Integration:** Already using Google Places API for venue data
