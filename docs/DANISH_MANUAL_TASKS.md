# Barfliz V1 Launch — Manual Runbook (Danish)

**For:** Danish (Barfliz dev)
**From:** Steve / Claude
**Goal:** Get Barfliz V1 submitted to the Apple App Store within 72 hours.
**Scope:** Everything in this doc requires logging into a third-party dashboard, paying money, or running Xcode. Claude is handling all the code and migration work in parallel. You don't touch source code unless asked.

When you finish a task, reply to Steve with: task ID, what you did, and any output (URLs, IDs, screenshots).

---

## Task M1 — Set Twilio production secrets in Supabase

**Why:** Without this, no user can sign up via SMS. The edge functions can't send OTP messages.

**Time:** 5 minutes

**Steps:**

1. Open a terminal on a machine that has the Supabase CLI authenticated to the Barfliz project. If not authenticated:
   ```
   npx supabase login
   ```
2. Run this exact command (the values are already in `DEPLOYMENT_CHECKLIST.md` in the repo):
   ```
   npx supabase secrets set TWILIO_ACCOUNT_SID=AC55a0061f7b574ff96bb37ec19e0f9ed7 TWILIO_AUTH_TOKEN=9f67aae1fc66f2b94b0e2fbb2c0b3a7e TWILIO_PHONE_NUMBER=+61488829851
   ```
3. Verify with:
   ```
   npx supabase secrets list
   ```
   You should see all three keys.
4. Test signup with the live app from a real phone number that is NOT one of the demo numbers (+15550000001, +61400000001).

**Deliver back:** Confirmation of `secrets list` output (redact values) + screenshot of a test SMS arriving.

---

## Task M1B — Deploy updated Supabase Edge Functions

**Why:** Several edge functions changed in V1 work (demo mode, account deletion). These changes are committed to the repo but Supabase runs whatever was last deployed, not whatever is in `main`. Without this step, demo numbers won't bypass Twilio and account deletion won't return the deletion summary.

**Time:** 3 minutes

**One-liner (run from the repo root after `git pull`):**
```
npx supabase functions deploy twilio-send-otp twilio-verify-otp delete-account
```

That's it. The CLI auto-bundles the `_shared/demoNumbers.ts` module that the OTP functions import.

**Verify:**
1. After deploy, test with the primary demo number `+15550000001` and code `0001`. You should sign in instantly without an SMS.
2. Test a real phone number too. It should still receive an actual SMS via Twilio.
3. From a test account: Settings → Danger Zone → Delete Account → type DELETE → confirm. The account row in `auth.users` and `public.users` should both disappear.

**When to run again:** any time we ship more edge function changes. The pre-flight before submission (Task M11) should re-run this to make sure the deployed functions match `main`.

**Deliver back:** Confirmation deploy succeeded + screenshot of demo bypass working.

---

## Task M2 — RevenueCat account + 6 IAP products

**Why:** Apple guideline 3.1.1 requires virtual currency (Lush Coins) to be sold through Apple IAP, not crypto/Solana. RevenueCat is the standard tool to manage Apple + Google IAP receipts in one place.

**Time:** 60 minutes

**Steps:**

1. Go to https://www.revenuecat.com/. Sign up using `steve@gtmvp.com` (or whichever email Steve gives you). Use the free tier — paid tier is not needed until $10K MTR.
2. Create a project named "Barfliz".
3. Add the iOS app:
   - Bundle ID: confirm with Steve (likely `com.barfliz.app` — check `capacitor.config.ts` in the repo for the actual value).
   - Upload the App Store Connect shared secret (Steve will provide once App Store Connect is set up — see Task M4).
4. Add the Android app (do this even though we're submitting iOS first):
   - Package name: same as iOS
   - Upload the Google Play service account JSON when ready (post-V1 OK).
5. Create 6 consumable products in this exact spec. Use these exact product identifiers — Claude wires the client to these strings:

| Product ID | Display Name | Coin Amount | Price (USD) |
|------------|--------------|-------------|-------------|
| `lush_coins_starter` | Starter Pack | 100 | $0.99 |
| `lush_coins_popular` | Popular Pack | 550 | $4.99 |
| `lush_coins_best_value` | Best Value | 1,200 | $9.99 |
| `lush_coins_party` | Party Pack | 2,800 | $19.99 |
| `lush_coins_whale` | Whale Pack | 7,500 | $49.99 |
| `lush_coins_legend` | Legend | 16,500 | $99.99 |

6. Create the SAME products in App Store Connect (Apps → Barfliz → In-App Purchases → +) and Google Play Console with the SAME product IDs. RevenueCat reads receipts from both stores.
7. In RevenueCat, group all 6 products into an "Offering" called `default`.
8. Get two API keys:
   - Public key (starts with `appl_` for iOS, `goog_` for Android) — for the client.
   - Server-side secret key — for the Supabase edge function.

**Deliver back:** Both API keys (paste in a 1Password / secure DM to Steve, never email). Confirm all 6 products show "Ready to Submit" in App Store Connect.

---

## Task M3 — Add `REVENUECAT_API_KEY` to Supabase secrets

**Why:** The IAP-validation edge function calls RevenueCat's REST API to validate receipts server-side.

**Time:** 2 minutes

**Steps:**

1. Take the **server-side secret** from RevenueCat (Task M2 step 8, NOT the public key).
2. Set it on Supabase:
   ```
   npx supabase secrets set REVENUECAT_API_KEY=<paste-the-secret>
   ```
3. Verify with `npx supabase secrets list`.

**Deliver back:** Confirmation it's set.

---

## Task M4 — Create App Store Connect record

**Why:** Apple's record for Barfliz. Without this you can't upload an iOS build or submit for review.

**Time:** 90 minutes

**Steps:**

1. Go to https://appstoreconnect.apple.com/. Sign in with the team account Steve gives you.
2. My Apps → + → New App.
3. Fill in:
   - Platforms: iOS
   - Name: `Barfliz: Nightlife Social App` (29 chars — matches market brief)
   - Primary language: English (U.S.)
   - Bundle ID: select the one matching `capacitor.config.ts` (likely `com.barfliz.app`)
   - SKU: `barfliz-ios-v1`
   - User access: Full Access
4. Once created, go to App Information:
   - Subtitle: `See Who's Out. Go Together.` (27 chars)
   - Category: Primary `Social Networking`, Secondary `Navigation`
   - Content Rights: check "no third-party content" unless we're embedding music
5. Pricing: Free
6. App Privacy: Steve will fill this together with you. Required disclosures: Location (precise + approximate), Contacts (optional), Phone Number, Photos, Identifiers (Device ID for IAP).
7. Age Rating: 17+ (Frequent/Intense Mature/Suggestive Themes due to alcohol context).
8. Version 1.0.0 page:
   - Description: copy from `EXECUTIVE_PRODUCT_SPEC.md` section "Core Product Vision" (Steve will polish)
   - Keywords (100 char limit): `bars,nightlife,bar finder,nightclub,going out,bar crawl,pub crawl,swarm,venue,drinks,friends,nearby`
   - Support URL: confirm with Steve (likely barfliz.com/support)
   - Marketing URL: barfliz.com
   - Screenshots: upload the 9 in `screenshots/` folder of the repo (1290×2796 for 6.7" iPhone). The iOS export script is `npm run export:ios` if you need to regenerate.
9. App Review Information section:
   - Demo account user: `+15550000001`
   - Demo account password: `0001` (this is the OTP code, not a password — explain in notes)
   - Notes for reviewer: paste contents of `docs/APP_STORE_REVIEW_NOTES.md` once Claude generates that file (Feature 4 deliverable).

**Deliver back:** Apple App ID number. Screenshot of "Ready to Submit" status. Shared Secret from App Information → App-Specific Shared Secret (paste into RevenueCat from Task M2).

---

## Task M5 — Apple Developer certificate + provisioning profile

**Why:** Required to archive and upload an iOS build from Xcode.

**Time:** 30 minutes

**Steps:**

1. Go to https://developer.apple.com/account/. Sign in.
2. Certificates, Identifiers & Profiles:
   - Identifiers → + → App IDs → App. Bundle ID matches Task M4 (`com.barfliz.app`). Capabilities: Push Notifications, In-App Purchase, Sign in with Apple (if used), Associated Domains (for deep links).
   - Certificates → + → Apple Distribution. Follow the prompts (CSR generated from Keychain Access on the Mac you'll archive from).
   - Provisioning Profiles → + → App Store. Select the App ID and the new Distribution certificate.
3. Download the provisioning profile, double-click to install in Xcode.

**Deliver back:** Confirmation Xcode shows the App ID + provisioning profile correctly under Signing & Capabilities.

---

## Task M6 — Verify Privacy Policy + ToS URLs are live

**Why:** App Store Connect requires public URLs for both. Apple reviewers will click them.

**Time:** 15 minutes

**Steps:**

1. Open the Privacy Policy URL Steve gives you (likely `barfliz.com/privacy` or `https://barfliz.com/privacy-policy`).
2. Open the Terms of Service URL.
3. Confirm both load on mobile and desktop, are HTTPS, no 404, no auth wall.
4. Confirm the Privacy Policy mentions: location data, phone number, contacts (if used), camera/photos, device identifiers.
5. Confirm the ToS mentions: zero tolerance for objectionable content + abusive users (Apple guideline 1.2). Claude is adding this language to the in-app ToS in Feature 3 — make sure the public URL matches.

**Deliver back:** Both URLs + screenshot of each loading.

---

## Task M7 — Create Sentry project, get DSN

**Why:** Error monitoring. Without this we have no visibility into iOS crashes post-launch.

**Time:** 10 minutes

**Steps:**

1. Go to https://sentry.io/. Sign in with the team account.
2. Create new project:
   - Platform: React (we use Sentry for the web layer of the Capacitor build)
   - Project name: `barfliz-ios`
   - Team: default
3. Copy the DSN URL (looks like `https://abc123@o12345.ingest.sentry.io/67890`).
4. Optional: also create a `barfliz-edge-functions` project for the Supabase edge functions if Steve wants edge fn monitoring (skip for V1 if short on time).

**Deliver back:** The DSN URL. Steve adds it to Supabase secrets and the local `.env` (Claude will use it).

---

## Task M8 — Generate 1024×1024 app icon source

**Why:** Apple requires a 1024×1024 lossless icon for the App Store listing. The Capacitor asset generator builds all other iOS icon sizes from this one source.

**Time:** 30 minutes

**Steps:**

1. Find the latest Barfliz logo source (likely in the repo or a Google Drive folder Steve will share).
2. Export at 1024×1024, sRGB, no transparency, no rounded corners (Apple rounds them).
3. Save to `resources/icon.png` in the repo root (Capacitor assets convention).
4. Save a 2732×2732 splash source to `resources/splash.png` (used for the launch screen).

**Deliver back:** Confirm both files committed. Claude will run the Capacitor assets generator next.

---

## Task M9 — Approve migrations + pushes as Claude prompts

**Why:** Per Steve's safety guard, Claude pauses before any database migration run or `git push`. You're the second pair of eyes on each one.

**Time:** <1 minute each, ~5 times across the 72-hour window

**Steps:**

1. When Claude posts in Slack/chat: "Migration X ready, OK to run?" — review the SQL file Claude generated (it will name the file path), reply "Yes" or "No".
2. Same for pushes: Claude posts "Branch ready, push to origin/main?" — confirm.

**Deliver back:** Approve or reject. If reject, give the reason.

---

## Task M10 — Xcode archive → upload to TestFlight

**Why:** This is how the iOS binary gets to Apple. Must be done from a Mac with Xcode 15+.

**Time:** 60 minutes

**Prerequisites:** M1-M8 complete.

**Steps:**

1. Pull the latest from `main`:
   ```
   git pull origin main
   npm install
   npm run cap:sync
   ```
2. Open Xcode:
   ```
   npx cap open ios
   ```
3. In Xcode:
   - Select the Barfliz scheme.
   - Set destination to "Any iOS Device (arm64)".
   - Verify Signing & Capabilities uses the Distribution cert from M5.
   - Verify the version (CFBundleShortVersionString) is `1.0.0` and the build number (CFBundleVersion) is `1`.
4. Product → Archive. This takes 5-15 minutes.
5. Once archived, the Organizer window opens. Click "Distribute App".
6. Choose "App Store Connect" → "Upload" → Next through the prompts.
7. Wait 5-30 minutes for Apple to process the build. Refresh App Store Connect → My Apps → Barfliz → TestFlight tab. The build should appear.
8. Apple emails you when processing is complete (or done with concerns). Address any concerns (usually missing privacy descriptions in Info.plist).

**Deliver back:** Build number that processed successfully, screenshot of TestFlight tab showing the build.

---

## Task M11 — Submit for App Store Review

**Why:** Final step. After review (24-72 hours typical), Barfliz is live.

**Time:** 15 minutes

**Prerequisites:** M10 complete, all of Claude's features merged to `main`, smoke tests passing.

**Steps:**

1. App Store Connect → My Apps → Barfliz → 1.0.0 (Prepare for Submission).
2. Confirm everything from Task M4 is filled in (description, keywords, screenshots, support URL, marketing URL, privacy URL).
3. Build section: select the build uploaded in Task M10.
4. App Review Information: confirm demo account credentials are correct (Task M4 step 9).
5. Version Release: choose "Manually release this version" (so we can sync the launch with marketing).
6. Click "Add for Review" → "Submit for Review".

**Deliver back:** Confirmation submitted. Apple sends an email when status changes (In Review → Pending Developer Release → Ready for Sale).

---

## Sequence dependency graph

```
M1 (Twilio) ──┐
              ├──► M1B (deploy edge fns) ──► Claude Feature 4 (Demo Mode) ──► Test signup
M2 (RevenueCat) ──┐
                   ├──► M3 ──► Claude Feature 1 (IAP) ──► IAP sandbox test
M4 (App Store Connect) ──► provides: bundle ID, shared secret
M5 (cert + profile) ──► M10 (Xcode archive)
M6 (Privacy/ToS URLs) ──► M4 metadata
M7 (Sentry) ──► Claude Feature 6
M8 (icon source) ──► Claude Feature 6 (asset generation)
M9 (approvals) ──► continuous
M10 (Xcode → TestFlight) ──► M11
M11 (submit) ──► Apple review (24-72h) ──► live
```

**Critical path:** M1, M2, M4 must start TODAY. M5 and M8 can happen in parallel. M10 and M11 are last.

---

## Contact

Anything blocking, unclear, or surprising — message Steve immediately. Don't burn hours on a problem worth a 30-second clarification.
