# Barfliz V1 Launch Plan

**Date:** 2026-04-28
**Target:** App Store submission within ~72 hours
**Build environment:** Claude Code (direct repo access, full shell, can run npm/supabase/playwright)
**Branching:** Straight to `main`. Solo + time-tight.

---

## Approach

Claude builds everything that's code, config, migrations, and tests. Danish handles anything that requires logging into a third-party dashboard, paying money, or running Xcode. Steve approves every push, every migration, every deploy.

---

## Sequencing (next 72 hours)

| Day | Claude (in this repo) | Danish (manual) |
|-----|----------------------|-----------------|
| Day 1 | Feature 2 (Account Delete), Feature 4 (Demo Mode), Feature 5 (Onboarding/Cold Start) | M1 Twilio prod secrets. M2-M3 RevenueCat signup + 6 SKUs. M4 App Store Connect record. |
| Day 2 | Feature 3 (Report/Block), Feature 6 (Capacitor + Sentry) | M5 Apple cert + provisioning profile. M6 Privacy/ToS URLs verified. M7 Sentry project. M8 1024 icon source. |
| Day 3 | Feature 1 (IAP, requires RevenueCat done), Feature 7 (smoke + release:check) | M10 Xcode archive → TestFlight. M11 Submit for review. |

---

## Features (Claude builds)

| # | Feature | Files | Migrations | Approval gates |
|---|---------|-------|------------|----------------|
| 1 | Apple/Google IAP for Lush Coins | iapService, LushCoinPage, iap-grant-coins edge fn, capacitor.config | iap_transactions | npm install, migration, push |
| 2 | Account Deletion flow (App Store guideline 5.1.1(v)) | DeleteAccountFlow, SettingsView, App.tsx route, delete-account edge fn | none | push |
| 3 | Content Reporting + Blocking (App Store 1.2) | ReportContentModal, BlockedUsersList, profile/message/venue/swarm wiring, ToS page | content_reports, user_blocks | migrations, push |
| 4 | App Store Reviewer Demo Mode | twilio-send-otp + verify-otp edge fns, demo seed SQL | none (data only) | seed run, push |
| 5 | Onboarding tour + cold-start density UX | First-run tour overlay, Home/Map cold-start cues, empty states | none | push |
| 6 | Capacitor iOS polish + Sentry | capacitor.config, ErrorBoundary, statusBarService, main.tsx, .env.example | none | npm install, push |
| 7 | Playwright smoke + release:check | tests/smoke/*, scripts/release-check.mjs, package.json | none | tests run, push |

### Claude WILL

- Run `npm install`, `npm run typecheck`, `npm run build`, `npx playwright test`
- Write migration files
- Make local commits with conventional commit messages
- Match existing patterns rather than invent new ones
- Pause and surface ambiguity rather than guess

### Claude will NOT (per safety guard)

- Push to GitHub without approval
- Run database migrations without approval
- Touch ad campaigns or marketing channels
- Modify `.env` without showing the diff first
- Submit anything to the App Store

---

## Decision points

| Trigger | Question | Default if you don't reply |
|---------|----------|----------------------------|
| Before any `npm install` | "About to install X. OK?" | Hold |
| Before any migration run | "Migration ready, run on Supabase?" | Hold (file stays uncommitted) |
| Before any `git push` | "Branch ready, push to origin?" | Hold (commit stays local) |
| Ambiguous intent | I ask, I don't guess | Hold |
| Bigger problem found mid-feature | I stop, surface it, you decide scope | Hold |

---

## Pre-flight checks before each feature

- Read existing edge fn before patching it (avoid breaking what works)
- Verify migration target table doesn't already exist
- Confirm Capacitor `appId` matches App Store Connect record before any IAP work

---

## Manual work owned by Danish

See `docs/DANISH_MANUAL_TASKS.md` for the full runbook.

Quick index:

| ID | Task | Time |
|----|------|------|
| M1 | Set Twilio prod secrets in Supabase | 5 min |
| M2 | Create RevenueCat account + 6 IAP products | 60 min |
| M3 | Add `REVENUECAT_API_KEY` to Supabase secrets | 2 min |
| M4 | Create App Store Connect record | 90 min |
| M5 | Apple Developer cert + provisioning profile | 30 min |
| M6 | Verify Privacy + ToS URLs are live | 15 min |
| M7 | Create Sentry project, get DSN | 10 min |
| M8 | Generate 1024×1024 app icon source | 30 min |
| M9 | Approve each migration + push as Claude prompts | <1 min each |
| M10 | Xcode archive → upload to TestFlight | 60 min |
| M11 | Submit for App Store Review | 15 min |

---

## Token / time budget

| Feature | Est tokens (Claude Code) | Est wall time |
|---------|--------------------------|---------------|
| 2 Account Delete | ~80K | 30 min |
| 4 Demo Mode | ~100K | 30 min |
| 5 Onboarding/Cold Start | ~200K | 90 min |
| 3 Report/Block | ~250K | 90 min |
| 6 Capacitor + Sentry | ~150K | 60 min |
| 1 IAP | ~250K | 90 min |
| 7 Smoke + release:check | ~150K | 45 min |

**Total: ~1.18M tokens / ~7 hours of focused build time.** Leaves headroom for fixes.

---

## What ships post-launch (NOT in V1)

| Item | Reason deferred |
|------|----------------|
| Subscription tiers (Gold $9.99, VIP $19.99) | Need 30 days of usage data to tune pricing |
| Privy crypto wallet | Feature-flagged off, web-only path |
| Venue dashboard SaaS | Separate B2B sales motion |
| Flutter native parity | Skeleton only |
| iOS push notifications (APNs) | Engagement loop, not blocker |
| Localization beyond US English | Per market brief: US first, then UK/AU/CA |

---

## Source files

- This plan: `docs/V1_LAUNCH_PLAN.md`
- Danish runbook: `docs/DANISH_MANUAL_TASKS.md`
- Market brief: `docs/MARKET_POSITION_BRIEF.md`
- Blog SEO strategy: `docs/BLOG_KEYWORD_STRATEGY.md`
- Twilio deploy: `DEPLOYMENT_CHECKLIST.md`
- Product spec: `EXECUTIVE_PRODUCT_SPEC.md`
