# Circle Developer Grant — LUSH / Barfliz Application Draft

**Program:** Circle Developer Grants
**Apply at:** https://www.circle.com/grant (watch for 2026 reopening)
**Amount:** $5,000 – $100,000 in USDC

---

## Project Name
Barfliz — Two-Token Nightlife Economy (LUSH + USDC)

## One-Line Pitch
A live nightlife social app using USDC on Solana for peer-to-peer payments and tab splitting alongside a custom SPL utility token (LUSH) for gamified engagement rewards.

## How We Use USDC

### Current USDC Integration
| Feature | USDC Role |
|---------|-----------|
| **Friend-to-friend payments** | User A sends USDC directly to User B's embedded wallet (Privy) |
| **Tab splitting** | Group splits a bar tab — each member's share is transferred in USDC |
| **Peer-to-peer transfers** | Direct USDC transfers between any two Barfliz users |

### Planned USDC Integration
| Feature | USDC Role |
|---------|-----------|
| **LUSH pack purchases** | Users pay USDC to receive LUSH from the treasury (in-app currency purchase) |
| **Venue drink redemption** | Users burn LUSH at partner venues; venue settles in USDC via treasury |
| **Venue subscription payments** | Venue operators pay monthly USDC subscription for analytics dashboard |

### Why USDC (Not Fiat Rails)
- **Sub-second settlement** (~400ms on Solana) vs. 2-3 business days for ACH
- **Near-zero fees** (~$0.003/tx) vs. 2.9% + $0.30 for card processors
- **No chargebacks** — critical for nightlife transactions where disputes are common
- **Global** — works for international tourists visiting US nightlife markets
- **Programmable** — tab splitting logic executes on-chain without intermediaries
- **Visa settlement support** — Circle's Visa integration (launched Dec 2025) enables USDC ↔ fiat off-ramps

## Two-Token Architecture

Barfliz deliberately separates engagement from payments:

```
LUSH (Utility Token)          USDC (Stablecoin)
├─ Earned via GPS check-ins   ├─ Loaded via card/bank
├─ Spent on virtual gifts     ├─ Sent peer-to-peer
├─ Burned on spend            ├─ Used for tab splitting
├─ No fixed $ value           ├─ 1:1 USD peg
└─ Gamification layer         └─ Payment layer
```

**Why two tokens?** Real-money payments require a stable unit of account. You shouldn't pay for a $12 cocktail with a token whose value fluctuates. USDC provides price stability for real payments. LUSH provides engagement incentives without the regulatory burden of a payment instrument.

## USDC Transaction Volume Projections

| Scale | Monthly USDC Volume | Source |
|-------|-------------------|--------|
| 1,000 MAU | $15,000 – $30,000 | Tab splits, peer payments |
| 10,000 MAU | $150,000 – $300,000 | + LUSH pack purchases |
| 100,000 MAU | $1.5M – $5M | + Venue drink redemptions, subscriptions |

Average nightlife spend per person per night: $50-$100. Even capturing 10-20% of that through USDC creates meaningful on-chain volume.

## Technical Implementation

- **Blockchain:** Solana (USDC SPL token)
- **Wallets:** Privy embedded wallets (non-custodial, MPC key sharding)
- **On-ramp:** Card/bank → USDC via Privy/MoonPay
- **Service layer:** `src/services/usdcPaymentService.ts` handles all USDC operations
- **Architecture:** Unidirectional data flow — UI → Service → Blockchain → WalletProvider → UI
- **No custody:** Barfliz never holds user USDC. All transfers are wallet-to-wallet.

## The Application: Barfliz

Barfliz is a mobile-first nightlife social app — live in production (v1.6.0):
- **Live Map** with real-time venue activity
- **The Room** — GPS-gated venue chat and social features
- **Swarms** — Crew coordination with RSVP and tab splitting
- **Virtual Gifts** — 29 items across 5 rarity tiers (purchased with LUSH)
- **Safety** — Emergency contacts, safe arrival check-ins
- **Platforms:** PWA, iOS, Android (Capacitor)
- **Backend:** Supabase (PostgreSQL, Auth, Realtime, 25+ Edge Functions)

## Team
- **Travis Benoit** — Founder & Lead Developer, Barfliz, Inc.

## Grant Amount Requested: $50,000 USDC

### Use of Funds
| Item | Amount |
|------|--------|
| USDC on-ramp integration (MoonPay/Privy production tier) | $10,000 |
| Tab splitting smart contract development & audit | $10,000 |
| LUSH pack purchase flow (USDC → LUSH treasury swap) | $5,000 |
| Venue drink redemption pilot (USDC settlement) | $8,000 |
| User acquisition in launch markets (Miami, Austin, Nashville) | $10,000 |
| Legal review (money transmitter analysis for USDC flows) | $5,000 |
| Reserve | $2,000 |
| **Total** | **$50,000** |

## Why Circle Should Fund This
1. **Real USDC utility** — not DeFi yield farming, but real-world payments at bars and restaurants
2. **Novel vertical** — nightlife is an untapped market for USDC adoption
3. **Volume driver** — average nightlife consumer spends $50-100/night; capturing even a fraction drives meaningful USDC volume on Solana
4. **Two-token model showcase** — demonstrates the Circle thesis that USDC is the settlement layer for all crypto-native applications
5. **Live product** — not a prototype; a production app with complete infrastructure
6. **Target markets** — Miami, Austin, Nashville are crypto-friendly cities with active nightlife scenes

## Links
- **GitHub:** https://github.com/travisbenoit/bippinbarliz
- **Whitepaper:** LUSH_Whitepaper.html (Section 7: USDC Integration details the two-token model)
