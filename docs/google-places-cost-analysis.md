# Google Places API Cost Analysis — 10,000 MAU

**Date:** March 14, 2026
**Barfliz Version:** v1.7.0

---

## How Barfliz Uses Google Places API

### User-Facing Calls (Per-Session, Recurring)

| What | API Endpoint | Trigger | Caching |
|------|-------------|---------|---------|
| **Venue photos** | Place Photo (`/place/photo`) | Every `<img>` load of a venue card/detail | Browser-only (no server cache) |

**This is the ONLY Google API call that scales with users.** Venue photo URLs are stored in the `venues.photo_url` column as direct Google API URLs (with API key embedded), and every browser render of a venue image hits the Google Photo endpoint.

### DB-Only Flows (Zero Google API Cost)

| Flow | What it calls | Cost |
|------|--------------|------|
| Map venue loading (`useMapData.ts`) | `locationService.fetchNearbyVenues()` → Supabase query | $0 |
| Home dashboard venues (`Home.tsx`) | `loadData()` → Supabase query | $0 |
| Geofence venue lookup | `bars-nearby` Edge Function → DB query | $0 |
| Venue detail view | Reads from `venues` table directly | $0 |

### Admin-Only Calls (One-Time Per Market)

| Operation | APIs Hit | When |
|-----------|---------|------|
| `populate-google-venues` | Nearby Search + Place Details + Place Photo | Initial market setup |
| `enrich-venues` | Text Search + Place Details + Place Photo | Enriching imported venues |
| `link-google-place` | Text Search | Manual venue linking |

---

## Google Maps Platform Pricing (2025–2026)

| API | 0–100K requests | 100K–500K | 500K+ |
|-----|----------------|-----------|-------|
| **Place Photo** | **$7.00 / 1,000** | $5.60 / 1,000 | $4.20 / 1,000 |
| Nearby Search | $32.00 / 1,000 | $25.60 / 1,000 | $19.20 / 1,000 |
| Text Search | $32.00 / 1,000 | $25.60 / 1,000 | $19.20 / 1,000 |
| Place Details (Atmosphere) | $5.00 / 1,000 | $4.00 / 1,000 | $3.00 / 1,000 |
| Place Details (Contact) | $3.00 / 1,000 | $2.40 / 1,000 | $1.80 / 1,000 |

**Free credit:** $200/month across all Google Maps Platform usage.

---

## Cost Model: 10,000 MAU

### Assumptions

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Sessions per user per month | 7 | Nightlife app, ~2x/week (weekend-heavy) |
| Total sessions/month | 70,000 | 10K × 7 |
| Venue photos rendered per session | 10 | Home feed cards + venue detail taps |
| Raw photo requests/month | 700,000 | 70K sessions × 10 photos |
| Browser cache hit rate | 50–70% | Same device + same venues within cache TTL |
| Unique venues in market | ~500 | 3 target cities (Miami, Austin, Nashville) |

### Scenario Breakdown

#### Conservative (70% cache hit rate)

```
Raw photo requests:          700,000
Cache hits (70%):           -490,000
Billable API calls:          210,000

Place Photo cost:
  100,000 × $7.00/1K  =       $700
  110,000 × $5.60/1K  =       $616
                          ----------
Subtotal:                    $1,316
Google free credit:           -$200
                          ----------
MONTHLY COST:                $1,116
```

#### Moderate (55% cache hit rate)

```
Raw photo requests:          700,000
Cache hits (55%):           -385,000
Billable API calls:          315,000

Place Photo cost:
  100,000 × $7.00/1K  =       $700
  215,000 × $5.60/1K  =     $1,204
                          ----------
Subtotal:                    $1,904
Google free credit:           -$200
                          ----------
MONTHLY COST:                $1,704
```

#### Aggressive (40% cache hit rate — worst case)

```
Raw photo requests:          700,000
Cache hits (40%):           -280,000
Billable API calls:          420,000

Place Photo cost:
  100,000 × $7.00/1K  =       $700
  320,000 × $5.60/1K  =     $1,792
                          ----------
Subtotal:                    $2,492
Google free credit:           -$200
                          ----------
MONTHLY COST:                $2,292
```

### Admin/Setup Costs (One-Time Per Market)

| Operation | Calls per market | Cost |
|-----------|-----------------|------|
| Nearby Search (5 keyword searches × 3 locations) | ~15 | $0.48 |
| Place Details (per venue discovered) | ~200 | $1.00 |
| Place Photo (per venue with photos) | ~200 | $1.40 |
| **Total per market launch** | | **~$3** |

Admin costs are negligible. This is a one-time setup cost per city.

---

## Summary

| Scenario | Monthly Cost | Annual Cost |
|----------|-------------|-------------|
| **Conservative** | **$1,116** | **$13,392** |
| **Moderate** | **$1,704** | **$20,448** |
| **Aggressive** | **$2,292** | **$27,504** |

**The only meaningful cost is Place Photo API calls from venue images loading in users' browsers.**

---

## Scaling Projections

| MAU | Monthly (Moderate) | Annual |
|-----|-------------------|--------|
| 1,000 | ~$100 | ~$1,200 |
| 5,000 | ~$800 | ~$9,600 |
| **10,000** | **~$1,700** | **~$20,400** |
| 25,000 | ~$3,800 | ~$45,600 |
| 50,000 | ~$6,900 | ~$82,800 |
| 100,000 | ~$11,500 | ~$138,000 |

Cost scales roughly linearly, with slight discount at higher volumes from Google's tiered pricing.

---

## Issues Found During Analysis

### 1. API Key Exposed in Client HTML (CRITICAL)

The `photo_url` column stores URLs like:
```
https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=...&key=YOUR_API_KEY
```

This API key is visible in the browser DOM, network tab, and page source. Anyone can extract it and use it to make billable API calls against your account.

**Impact:** Unlimited financial exposure. A malicious actor could run up your Google bill.

### 2. No Server-Side Photo Caching

The `google-place-photo` Edge Function exists as a proxy with rate limiting (60/min) and 24-hour cache headers, but venue photos in the DB bypass it entirely — they point directly to Google.

### 3. Dead Code in Home.tsx

`fetchNearbyVenues()` (lines 136–178) calls the `fetch-venues` edge function (which hits Google Nearby Search) but is never invoked. This is dead code. If accidentally wired up, it would add ~$2,240/month at 10K MAU (70K Nearby Search calls × $32/1K).

---

## Recommendations to Reduce Cost

### Option A: Proxy Photos Through Edge Function (Easy — 60–80% cost reduction)

Route all photo URLs through the existing `google-place-photo` edge function instead of direct Google URLs. The function already has:
- Rate limiting (60 requests/minute per IP)
- 24-hour immutable cache headers
- Server-side response that can be cached by CDN

**Implementation:** Run a migration to rewrite all `photo_url` values:
```
FROM: https://maps.googleapis.com/maps/api/place/photo?...&key=KEY
TO:   /functions/v1/google-place-photo?ref=PHOTO_REF&w=800
```

**Estimated cost at 10K MAU:** ~$200–400/month (500 unique venues × 30 daily cache refreshes = 15,000 API calls)

### Option B: Download Photos to Supabase Storage (Best — 95%+ cost reduction)

During enrichment, download the Google photo and upload to Supabase Storage. Store the Supabase Storage URL in `photo_url` instead.

**Estimated cost at 10K MAU:** ~$3/month (one-time photo download during enrichment only)
**Supabase Storage cost:** Included in plan (1GB free tier, ~500 photos × 100KB = 50MB)

### Option C: Use Google's Static Maps / CDN URLs (Moderate)

Google Place Photos accessed via `places.googleapis.com` (new API) can return CDN-cached URLs that don't count as API calls on subsequent browser loads.

---

## Recommendation

**Implement Option B (Supabase Storage)** during the next enrichment cycle. This eliminates per-user Google API costs entirely and fixes the API key exposure vulnerability.

**Immediate:** At minimum, restrict the Google API key in the GCP Console to only your Edge Function server IPs (not browser referrers), and switch to the proxy pattern (Option A) as a quick fix.

---

## Bottom Line

| | Current Architecture | With Option B Fix |
|---|---|---|
| **10K MAU monthly cost** | **$1,100 – $2,300** | **~$3** |
| **10K MAU annual cost** | **$13,400 – $27,500** | **~$36** |
| API key security | Exposed in HTML | Not exposed |
