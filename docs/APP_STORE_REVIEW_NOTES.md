# Notes for App Store / Play Store Reviewers

Welcome. This page contains everything you need to fully evaluate Barfliz. If anything is unclear, contact us at the support URL listed in the App Store metadata.

---

## Demo Account (no SMS required)

To skip the live phone verification flow, use one of the demo numbers below. The verification code is always `0001`.

| Phone | Region | Notes |
|-------|--------|-------|
| `+15550000001` | US (Florida) | Primary demo. Recommended starting point. |
| `+15550000002` | US | Secondary demo (use to test friend interactions with primary). |
| `+15550000003` | US | Tertiary demo (third party for swarms). |
| `+61400000001` | AU (Darwin) | Use to verify international flows. |

**Verification code (all demos):** `0001`

These numbers are server-allowlisted in the OTP edge functions. They bypass Twilio entirely and accept the static code. Real-user numbers continue to receive SMS through Twilio normally.

---

## What you can test on a fresh demo account

When you first sign in with a demo number, you'll go through the standard onboarding (age gate, name, profile). The demo account starts as a "new user" with these populated parts of the experience:

| Feature | Available immediately |
|---------|----------------------|
| Live venue map (real Google Places data, ~680+ bars in Fort Lauderdale, Miami, and other cities) | Yes |
| Venue check-in flow | Yes |
| Friend search and friend request | Yes (search for "Steve" or "Travis" to find founders' test accounts, or sign in on a second device with `+15550000002` to friend yourself) |
| Create a Swarm (group plan) | Yes |
| Direct messaging | Yes (after friending) |
| Lush Coin balance (in-app currency) | Starts at 0; earn 5 coins per check-in. Top-ups via Apple IAP. |
| Account deletion (Settings → Danger Zone) | Yes |
| Block / Report content | Yes |
| Ghost Mode (privacy) | Yes (Settings → Privacy) |

To exercise the social features in one session, we recommend opening the app on two devices and signing in with `+15550000001` and `+15550000002`. They can friend each other, message, and join a swarm together.

---

## Critical guideline alignment

| Apple guideline | How Barfliz complies |
|-----------------|---------------------|
| 3.1.1 (in-app purchase for digital content) | All Lush Coin packages purchased through Apple IAP via RevenueCat. No external payment URLs for in-app currency. The web build includes a separate Solana code path that is hidden on iOS via `Capacitor.isNativePlatform()`. |
| 5.1.1(v) (account deletion in-app) | Settings → Danger Zone → Delete Account. Three-step flow with explicit "DELETE" typed confirmation. Cascades all user-owned data via PostgreSQL `ON DELETE CASCADE` constraints on every user-referencing table. |
| 1.2 (objectionable content) | Report and Block actions on profiles, messages, venues, and swarms. Blocked Users list in Settings. Zero-tolerance language in Terms of Service. |
| 4.0 (location data) | Location is used for venue proximity, geofence check-ins, and people-nearby. Foreground only. Ghost Mode lets users hide their location at any time. Permissions requested with clear copy. |
| 17+ age rating | Birthday gate at signup. Country-specific drinking age enforced (21 US, 18 most others). Account creation blocked if under the local age. |

---

## Privacy & Terms

- **Privacy Policy:** see App Store metadata for the live URL.
- **Terms of Service:** see App Store metadata for the live URL. Includes zero-tolerance clause for objectionable content (Apple guideline 1.2).

---

## Architecture (in case it helps the review)

- **Client:** Capacitor 8 wrapping a React 19 + TypeScript + Vite PWA.
- **Backend:** Supabase (PostgreSQL with RLS, Edge Functions for serverless logic).
- **Maps:** Leaflet on the client, Google Places for venue data (server-side only), Radar.io for geofencing.
- **Identity:** Phone OTP via Twilio. Demo numbers are server-allowlisted as documented above.
- **Payments:** Venmo (US, P2P), Apple/Google IAP for Lush Coins (RevenueCat).
- **Crash & analytics:** Sentry (errors), PostHog (product analytics, anonymized).

---

## Known limitations on a fresh demo account

| Limitation | Why | Workaround |
|-----------|-----|------------|
| Empty friends list on first login | No pre-seeded relationships | Use the demo number on a second device to friend yourself, or search for active users in the live DB |
| No prior check-in history | Demo accounts start fresh | Tap a venue on the map and check in to populate history |
| No prior messages | Demo accounts start fresh | Friend another demo and send a DM |

If you would like a primary demo account pre-populated with friends, swarms, check-ins, and messages, please contact support and we will provision one. We left the default demo as a clean account so reviewers can verify the full first-run experience.

---

## Contact

If anything blocks your review, please email the support address in the App Store metadata. We respond within a few hours.

Thank you for reviewing Barfliz.
