# BARFLIZ — INTERNAL DOCUMENTATION

> **INTERNAL USE ONLY. DO NOT SHARE PUBLICLY.**

---

## WHAT THIS IS

Barfliz is a real-time nightlife social app. You open it, it knows where you are, shows you what's happening at bars and clubs nearby, lets you see who's out, start or join a crew (Swarm), chat, send drinks, and tracks your night. It is GPS-gated, venue-aware, and built to run on phones as a PWA.

Stack: **Vite + React + TypeScript** | **Supabase (Postgres, Auth, Storage, Realtime, Edge Functions)** | **Radar.io geofencing** | **Google Places**

---

## CURRENT VERSION

```
v1.4.1  —  March 10, 2026
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

## WHAT WAS JUST SHIPPED — v1.4.1

### Capacitor native push + app init
- **`initCapacitor()` wired to `main.tsx`** — StatusBar, SplashScreen, deep links, and native push init on every app start (no-op on web)
- **FCM native push support** — `send-push-notification` Edge Function now queries `native_token` rows (`platform = 'ios' | 'android'`) and sends via FCM Legacy HTTP API alongside existing VAPID web push
- Add `FCM_SERVER_KEY` to Supabase Dashboard → Settings → Edge Functions to activate native push delivery

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
│   └── database.types.ts  # Auto-generated DB types
└── providers/
    └── GeofenceProvider   # Radar geofence ENTER → check-in → XP

supabase/
├── migrations/            # 70+ migrations, all idempotent
└── functions/             # 25 Edge Functions
    ├── radar-webhook           # Geofence ENTER/EXIT events
    ├── send-push-notification  # VAPID Web Push (new)
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

## NEXT — v1.5.0

| Feature | Priority | Notes |
|---|---|---|
| Twilio OTP (phone auth) | 🔴 High | Blocked on API key |
| Swarm chat deep-link from push | 🟡 Medium | `/swarms?id=&tab=chat` deep-link |
| The Room VibeTab redesign | 🟡 Medium | More visual, less list-like |
| Group splits in swarm context | 🟢 Low | Beem/Venmo integration from swarm detail |
| Admin OSMImport auth guard | 🟢 Low | Currently no admin check |
| App store metadata (icons, screenshots, descriptions) | 🔴 High | Required before submission |
| Apple/Google developer account setup | 🔴 High | Capacitor shell needed for native submission |

---

## v1.5.0 — HORIZON

- Public venue profiles (shareable links)
- Promoter / venue owner portal
- Paid Lush Coin packs (in-app purchase)
- Cross-city swarms
- Event RSVP + ticketing integration
- iOS/Android native shell (Capacitor)

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
| GitHub | `travisbenoit/bippinbarliz` |

---

*Last updated: March 10, 2026 — v1.4.0*
