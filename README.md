# BARFLIZ — INTERNAL DOCUMENTATION

> **INTERNAL USE ONLY. DO NOT SHARE PUBLICLY.**

---

## WHAT THIS IS

Barfliz is a real-time nightlife social app. You open it, it knows where you are, shows you what's happening at bars and clubs nearby, lets you see who's out, start or join a crew (Swarm), chat, send drinks, and tracks your night. It is GPS-gated, venue-aware, and built to run on phones as a PWA.

Stack: **Vite + React + TypeScript** | **Supabase (Postgres, Auth, Storage, Realtime, Edge Functions)** | **Radar.io geofencing** | **Google Places**

---

## CURRENT VERSION

```
v1.2.0  —  March 10, 2026
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

## WHAT WAS JUST SHIPPED — v1.2.0

### Web Push Notifications
- `push_subscriptions` table — stores PushSubscription per user per device
- Service worker updated — `push` event listener + `notificationclick` handler
- `pushService.ts` — subscribe, unsubscribe, send helpers
- `send-push-notification` Edge Function — VAPID-signed push, no external libs, stale subscription auto-cleanup
- DM sends now fire a push to the recipient automatically
- NotificationsPermission screen subscribes to push after browser permission is granted

**One manual step required** — set these 3 secrets in Supabase Dashboard → Settings → Edge Functions:
```
VAPID_PUBLIC_KEY  = BB5LYqFhfJo3M8LwrCTYEmh_WAH3yy2bAs9v7j-pOMlwKFceFDJ3fz-NyisU-1Mw7KPuwLo5IB5naP4LS7v2low
VAPID_PRIVATE_KEY = q2e1jvb_ssiEqQJhQuOOivjEKnYeJMyWcPYXlPyBpp0
VAPID_SUBJECT     = mailto:hello@barfliz.com
```

### Gamification System (shipped v1.1.0)
- XP service — check-in XP, streak bonuses, event XP, coin earning
- Night streaks — consecutive night tracking, 7/30-day streak badges
- Lush Coins — earn on check-ins and streaks, spend on virtual gifts
- `increment_lush_coins` SQL RPC — atomic balance updates
- Badges system — 12+ badge types with unlock conditions
- Daily challenges — randomized per user, refresh at midnight
- Leaderboard — weekly XP rankings
- CheckinRewardToast — animated reward on venue entry
- CatalogView — live coin balance, affordability dimming per item

### Swarm Post-Creation Editing (shipped v1.1.0)
- Hosts can edit title, description, start/end time, venue, vibe tags after creation
- Add/remove invited members from an active swarm
- Accessible from SwarmDetailsModal via Edit button (host only)

### Security + DB Fixes (shipped v1.1.0)
- Fixed `user_blocks` column names across 4 migrations and messagesService (`blocking_user_id` → `blocker_id`)
- Fixed swarms RLS `is_public = true` → `join_mode = 'open'`
- Made all new migrations fully idempotent (safe to re-run on prod)
- Block enforcement moved to DB level for DM inserts
- Notifications INSERT locked to actor only (no fake notifications)
- Swarm join policy checks `join_mode` before allowing self-insert

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

## NEXT — v1.3.0

| Feature | Priority | Notes |
|---|---|---|
| Twilio OTP (phone auth) | 🔴 High | Blocked on API key |
| Push for all event types | 🔴 High | Currently DM only. Add: swarm invite, gift received, friend nearby |
| Swarm invite push notification | 🟡 Medium | Wire swarm invite flow to pushService |
| Story-style Moments viewer | 🟡 Medium | The Room moments as swipeable story UI |
| Image compression on avatar upload | 🟡 Medium | Client-side before upload |
| Venue check-in leaderboard | 🟡 Medium | Per-venue regular rankings |
| The Room UI polish | 🟡 Medium | Vibe tab, moments tab, full chat experience |
| Deep-link routing from push tap | 🟢 Low | `/messages`, `/swarms/:id` from notification `data.url` |
| Admin: venue analytics | 🟢 Low | Check-in counts, vibe votes, buzz volume per venue |

---

## v1.4.0 — HORIZON

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

*Last updated: March 10, 2026 — v1.2.0*
