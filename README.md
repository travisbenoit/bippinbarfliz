# BARFLIZ — INTERNAL DOCUMENTATION

> **INTERNAL USE ONLY. DO NOT SHARE PUBLICLY.**

---

## WHAT THIS IS

Barfliz is a real-time nightlife social app. You open it, it knows where you are, shows you what's happening at bars and clubs nearby, lets you see who's out, start or join a crew (Swarm), chat, send drinks, and tracks your night. It is GPS-gated, venue-aware, and built to run on phones as a PWA.

Stack: **Vite + React + TypeScript** | **Supabase (Postgres, Auth, Storage, Realtime, Edge Functions)** | **Radar.io geofencing** | **Google Places**

---

## CURRENT VERSION

```
v1.6.0  —  March 14, 2026
Branch: main
DB: Production (yfucglycufjwmcuadace.supabase.co)
```

---

## SYSTEM STATUS

| System | Status |
|---|---|
| Auth (phone + OTP) | ✅ Live |
| Venue discovery (Google Places + OSM) | ✅ Live |
| Geofencing (Radar.io) | ✅ Live |
| Check-in / presence | ✅ Live |
| Swarms (crew coordination) | ✅ Live |
| DM + Swarm chat (Realtime) | ✅ Live |
| Virtual gifts + Lush Coin economy | ✅ Live |
| Solana blockchain (LUSH SPL token) | ✅ Built — pending Privy account + token deploy |
| USDC payments | ✅ Built — pending Privy account |
| XP + streaks + badges + leaderboard | ✅ Live |
| Vibe Votes (venue mood) | ✅ Live |
| Venue Buzz (ephemeral venue chat) | ✅ Live |
| The Room (geofence-gated venue community) | ✅ Live |
| People Nearby (add friends inline) | ✅ Live |
| History view with XP stats | ✅ Live |
| Avatar upload (Supabase Storage) | ✅ Live |
| Web Push notifications | ✅ Infrastructure live — VAPID secrets needed |
| Music sharing (Spotify search) | ✅ Live |
| Uber ride integration | ✅ Live |
| Safety features + emergency contacts | ✅ Live |
| Group payments (Venmo deep-link) | ✅ Live |
| Swarm post-creation editing | ✅ Live |
| i18n / translation infrastructure | ✅ Live |
| Twilio OTP (phone verify) | ⚠️ Deployed, no API key yet |
| Admin panel (venues, geofences) | ✅ Live (internal only) |

---

## WHAT WAS JUST SHIPPED — v1.6.0

### Solana blockchain integration (LUSH Coin + USDC)
- **Feature flag system** — `VITE_CRYPTO_ENABLED` env var gates all blockchain UI; app works identically with flag off
- **Privy embedded wallets** — Auto-creates Solana wallet on login via Privy SDK; zero-friction, no seed phrases
- **WalletProvider (One-Way Model)** — React Context providing wallet state; strict unidirectional flow: UI → Service → Chain → Context → UI
- **LUSH SPL token** — Earn = on-chain mint via Edge Function; Spend = on-chain burn via Edge Function; 0 decimals (matches existing integer system)
- **xpService on-chain routing** — `earnCoins()` and `spendCoins()` route through `mint-lush-coins` / `burn-lush-coins` Edge Functions when crypto enabled; graceful fallback to DB path
- **USDC payments** — `CryptoPaymentModal` for friend-to-friend USDC transfers; `verify-payment` Edge Function confirms on-chain + records in `payment_transactions`
- **PaymentsView wallet card** — Shows Solana wallet address, LUSH balance, USDC balance when crypto enabled
- **LushCoinPage crypto mode** — Shows on-chain balance, wallet address, updated disclaimer text
- **SendPayment USDC button** — "Pay with USDC" option alongside Venmo/Beem when friend has wallet
- **Token deploy script** — `scripts/deploy-lush-token.ts` creates LUSH SPL token with Metaplex metadata
- **DB migration** — `wallet_address` on users, `tx_signature` + `token_mint` on payment_transactions and user_gifts
- **3 new Edge Functions** — `mint-lush-coins`, `burn-lush-coins`, `verify-payment`
- **Investor pitch** — `PITCH.md` with full token economics, revenue projections, competitive analysis, regulatory positioning

**New packages:** `@privy-io/react-auth`, `@solana/web3.js`, `@solana/spl-token`

---

## WHAT WAS JUST SHIPPED — v1.5.0

### App store readiness batch (minus Twilio key)
- **Capacitor native restored** — `capacitorService.ts` restored with full Capacitor integration (StatusBar, SplashScreen, deep link `appUrlOpen`); was stubbed to no-ops in previous push
- **Admin OSMImport auth guard** — `AdminOSMImport` now checks `is_admin` on mount and redirects to `/` if not admin; matches pattern used by all other admin pages
- **Swarm chat deep-link** — `/swarms?id=X&tab=chat` now navigates directly to swarm chat in MessagesView; `MessagesView` handles `location.state.openSwarmChat` to auto-open the right conversation
- **Group splits on map Swarm** — `SwarmDetailsModal` (map view) now has "Split the Tab" button for hosts and members; wired to existing `GroupSplit` component
- **VibeTab visual redesign** — Polls redesigned from list-with-progress-bars to emoji grid; winner shown as a hero card with trophy; vote % shown per tile; check-in gate updated with location pin

---

## WHAT WAS JUST SHIPPED — v1.4.3

### Bug fixes from debug session (March 12, 2026)
- **Directions dropdown click-outside** — `VenueDetailsModal` directions menu now closes when tapping/clicking anywhere outside it (was stuck open until a menu item was clicked)
- **`geocodingService.reverseGeocode` broken RPC** — Replaced non-existent `reverse_geocode` Supabase RPC call with Nominatim (OpenStreetMap) API; no key required, results cached in-memory 24h

---

## WHAT WAS JUST SHIPPED — v1.4.2

### Map overhaul batch
- **Search this area** — Pin map center, fetch venues/users from that location instead of GPS; shows active "Searching this area ✕" pill to cancel
- **Walking + driving directions** — Venue detail sheet Directions button now opens a mode picker (Walking/Driving) using platform-detected deep links (Apple Maps on iOS, Google Maps on Android/web)
- **Swarm host editing from map** — Swarm hosts see an "Edit Swarm" button directly in SwarmDetailsModal on the map; loads EditSwarm modal inline
- **Tonight Status in bottom sheet** — Status pill moved into MapBottomSheet tab bar (removed floating button from map overlay)
- **Birthday date picker redesign** — Replaced masked text input with dropdowns (Month / Day / Year); dynamic day count per month
- **Music sharing consolidation** — `musicSharingService.ts` deleted; `shareMusic`, `getReceivedMusic`, `getSentMusic`, `getSwarmMusic` methods merged into `musicService.ts`; `ChatView` migrated to use `musicService`
- **Location accuracy** — Real-time location update interval tightened to 3s / 5m threshold (was 10s / 10m); map data refresh reduced to 10s (was 30s)
- **Venue coordinate validation** — New `validateVenueCoordinates` utility + migration `20260312_validate_venue_coordinates.sql`
- **Geocoding service** — New `geocodingService.ts` with platform-aware directions URLs, address validation, and reverse geocoding via Nominatim
- **Capacitor stubbed for web** — `capacitorService.ts` simplified to no-ops for web builds; native Capacitor plugins remain in `package.json` for future native shell

### Remove push notifications (v1.4.2)
- Stripped all push notification code — imports, call sites, and service logic removed from friendsService, giftsService, messagesService, GeofenceProvider, CreateSwarm, EditSwarm, NotificationsPermission, and capacitorService
- `pushService.ts` left in place but unused (safe to delete later)
- Push can be re-added cleanly when ready (Flutter-native, Pushy, or direct APNS)

---

## WHAT WAS JUST SHIPPED — v1.4.1

### Capacitor native push + app init
- **`initCapacitor()` wired to `main.tsx`** — StatusBar, SplashScreen, deep links, and native push init on every app start (no-op on web)
- **Direct APNS for iOS** — `send-push-notification` Edge Function sends to iOS devices via Apple's APNS HTTP/2 API (JWT p8 auth, no Firebase/FCM)
- Android native push not used (no FCM); Android users receive web push via browser engine
- Add `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_PRIVATE_KEY` to Supabase Dashboard → Edge Functions env vars to activate iOS push

---

## WHAT WAS JUST SHIPPED — v1.4.0

### App store readiness batch
- **Friend search** — Search by name or @username in FriendsView; debounced live results with Add/Sent/Friends state
- **Privacy Policy** — Full page at `/privacy`, accessible logged in and out
- **Terms of Service** — Full page at `/terms`, accessible logged in and out
- **Legal links** — HelpCenter now has a Legal section linking both pages
- **Profile completeness bar** — 8-field progress bar in ProfileView with gradient bar and next-step nudge; hides at 100%
- **@username display** — Shows under name in ProfileView and UserProfileModal
- **Friends' activity feed on Home** — ActivityFeed (compact, 5 items) at top of HomeDashboardTab
- **Moments photo upload** — File picker + client-side compression (1200px/JPEG 82%) in MomentsTab post form
- **Notification preferences persist to DB** — Saves to `users.notification_preferences` JSONB column; localStorage as fallback
- **Migration** — `20260310000003_add_notification_preferences.sql`

---

## WHAT WAS JUST SHIPPED — v1.3.0

### Push for all event types
- Gifts: push to recipient on `sendGift` — "Someone sent you a gift 🎁"
- Friend requests: push to recipient on `sendFriendRequest` — "X wants to be friends"
- Swarm invites: push to each invitee on create and edit — "X invited you to a Swarm"
- Friend nearby: push to all friends on geofence ENTER — "X is out tonight 📍 at [venue]"
- Swarm push URLs include `?id=` param for direct deep-link to the right swarm
- Fix `friendsService` `user_blocks` column names (`blocker_id`/`blocked_id`)

### Story-style Moments viewer (The Room)
- Story strip at top of Moments tab — avatar circles, one per moment
- Tap any circle or card to open fullscreen story viewer
- Auto-advances every 5s with animated progress bars
- Left/right tap zones to navigate, like/delete/report from inside

### Image compression on avatar upload
- Client-side Canvas compression before upload — max 800px, JPEG 85%
- Raw file size limit raised to 10MB (compressed before sending)
- Faster uploads, lower storage cost

### Venue check-in leaderboard (The Room — Regulars tab)
- New 5th tab in TheRoom: Regulars
- Shows top users by visit count at that specific venue
- Gold/silver/bronze podium + ranked list with "you" highlighted

### The Room UI polish
- WhoIsHere Gift button now actually sends a beer to the user instantly (was a dead button)
- Regulars tab added to TheRoom tab bar

### Deep-link routing from push tap
- Swarm invite notifications open `/swarms?id={swarm-id}`
- `SwarmsView` reads `?id=` on mount and auto-opens the correct swarm modal
- DM push taps open `/messages`, gift push opens `/gifts`, friend request opens `/friends`

### Admin: Venue analytics
- New page at `/settings/admin/venue-analytics`
- Check-in count, buzz message count, vibe vote count per venue
- Sortable by any metric, searchable, activity proportion bar per row
- Admin-gated (`is_admin` check on users table)

### v1.2.0 — Web Push Infrastructure
- `push_subscriptions` table, service worker push+click handlers, `pushService.ts`
- `send-push-notification` Edge Function (VAPID, no external deps), deployed

**VAPID secrets still needed in Supabase Dashboard → Settings → Edge Functions:**
```
VAPID_PUBLIC_KEY  = BB5LYqFhfJo3M8LwrCTYEmh_WAH3yy2bAs9v7j-pOMlwKFceFDJ3fz-NyisU-1Mw7KPuwLo5IB5naP4LS7v2low
VAPID_PRIVATE_KEY = q2e1jvb_ssiEqQJhQuOOivjEKnYeJMyWcPYXlPyBpp0
VAPID_SUBJECT     = mailto:hello@barfliz.com
```

### v1.1.0 — Gamification, Swarm Editing, Security
- XP, streaks, Lush Coins, badges, daily challenges, leaderboard
- Swarm post-creation editing for hosts
- Comprehensive security audit: block enforcement at DB, notifications locked to actor, swarm join_mode policy

---

## ARCHITECTURE

```
src/
├── components/
│   ├── Auth/              # Phone OTP login
│   ├── Gamification/      # XP toasts, The Room, vibe tab, moments
│   ├── Gifts/             # GiftsInbox, VirtualItems catalog
│   ├── Home/              # Main feed, venue cards, check-in
│   ├── Map/               # Leaflet map with venue clusters
│   ├── Messages/          # DM + Swarm chat (Realtime)
│   ├── People/            # PeopleNearbyView + friend requests
│   ├── Permissions/       # Push + location permission screens
│   ├── Settings/          # Profile, notifications, safety
│   ├── Swarms/            # Create, details, edit, join
│   └── ...
├── services/
│   ├── xpService.ts       # XP, streaks, badges, challenges, leaderboard
│   ├── giftsService.ts    # Virtual gift send/receive
│   ├── messagesService.ts # DM + Swarm messaging + Realtime
│   ├── pushService.ts     # Web Push subscribe/send
│   ├── vibeService.ts     # Venue mood votes
│   ├── buzzService.ts     # Ephemeral venue chat
│   ├── roomService.ts     # The Room (geofenced venue community)
│   └── ...
├── lib/
│   ├── supabase.ts        # Supabase client
│   ├── featureFlags.ts    # CRYPTO_ENABLED and future flags
│   ├── privy.ts           # Privy SDK config
│   └── database.types.ts  # Auto-generated DB types
└── providers/
    ├── GeofenceProvider   # Radar geofence ENTER → check-in → XP
    ├── WalletProvider.tsx # Solana wallet state (One-Way Model)
    └── CryptoProviders.tsx# Privy + Wallet bundle (lazy-loaded)

supabase/
├── migrations/            # 70+ migrations, all idempotent
└── functions/             # 28 Edge Functions
    ├── mint-lush-coins         # Mint LUSH SPL token (v1.6.0)
    ├── burn-lush-coins         # Burn LUSH on gift purchase (v1.6.0)
    ├── verify-payment          # Verify USDC payment on-chain (v1.6.0)
    ├── radar-webhook           # Geofence ENTER/EXIT events
    ├── send-push-notification  # VAPID Web Push
    ├── twilio-send-otp         # Phone auth
    ├── uber-rides              # Ride integration
    ├── spotify-search          # Music sharing
    └── ...

public/
└── service-worker.js      # Caching + push notification handler
```

---

## LOCAL DEV

```bash
npm install
npm run dev
npm run build

# Push DB migrations to prod
npx supabase db push

# Deploy an Edge Function
npx supabase functions deploy <function-name>
```

`.env` vars:
```
VITE_SUPABASE_URL=https://yfucglycufjwmcuadace.supabase.co
VITE_SUPABASE_ANON_KEY=...
VITE_VAPID_PUBLIC_KEY=BB5LYqFhfJo3M8LwrCTYEmh_WAH3yy2bAs9v7j-pOMlwKFceFDJ3fz-NyisU-1Mw7KPuwLo5IB5naP4LS7v2low

# Blockchain (optional — set CRYPTO_ENABLED=true to activate)
VITE_CRYPTO_ENABLED=false
VITE_PRIVY_APP_ID=
VITE_SOLANA_RPC_URL=https://api.devnet.solana.com
VITE_SOLANA_NETWORK=devnet
VITE_LUSH_MINT_ADDRESS=
VITE_USDC_MINT_ADDRESS=EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
```

---

## MIGRATION RULES

All migrations must be idempotent. Pattern:

```sql
-- Tables
CREATE TABLE IF NOT EXISTS ...

-- Indexes
CREATE INDEX IF NOT EXISTS ...

-- Policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = '...' AND policyname = '...') THEN
    CREATE POLICY "..." ON ... ;
  END IF;
END $$;
```

Never use `now()` or non-immutable expressions in index predicates.
Column names in `user_blocks`: `blocker_id` / `blocked_id` (not `blocking_user_id`).
Swarm visibility: `join_mode` column (not `is_public`).

---

## NEXT — v1.7.0

| Feature | Priority | Notes |
|---|---|---|
| Privy account setup | 🔴 High | Create account at privy.io, get App ID, add to .env |
| Deploy LUSH token to devnet | 🔴 High | Run `npx tsx scripts/deploy-lush-token.ts`, add mint address to env |
| Twilio OTP (phone auth) | 🔴 High | Blocked on API key — need to add to Supabase env vars |
| App Store + Google Play submission | 🔴 High | Bundle ID `com.barfliz.app` set — needs account enrollment |
| Push LUSH Edge Function secrets | 🟡 Medium | MINT_AUTHORITY_KEYPAIR, LUSH_MINT_ADDRESS, SOLANA_RPC_URL to Supabase |
| Token migration (existing balances) | 🟡 Medium | One-time script to mint existing lush_coin_balance to user wallets |
| Paid LUSH Coin packs | 🟡 Medium | USDC → LUSH via treasury (in-app purchase alternative) |

---

## v1.7.0 — HORIZON

- Privy wallet activation + LUSH token mainnet launch
- Paid Lush Coin packs (USDC → LUSH)
- Venue partnerships (LUSH drink redemption)
- Public venue profiles (shareable links)
- Promoter / venue owner portal
- Cross-city swarms
- Event RSVP + ticketing integration
- PostHog analytics integration

---

## CREDENTIALS LOCATION

> Actual secrets live in 1Password, not here.

| Thing | Where |
|---|---|
| Supabase project | `yfucglycufjwmcuadace` — supabase.com |
| Radar.io | Radar dashboard |
| Google Places API | GCP console |
| Twilio | Pending — no key yet |
| VAPID keys | Supabase → Edge Function secrets |
| Privy | Pending — need account at privy.io |
| Solana RPC | Helius / QuickNode (devnet free tier for now) |
| GitHub | `travisbenoit/bippinbarliz` |

---

*Last updated: March 14, 2026 — v1.6.0*
