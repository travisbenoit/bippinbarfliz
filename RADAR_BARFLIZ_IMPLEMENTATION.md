# Radar Barfliz Implementation - Darwin, Australia

This document describes the complete Radar presence system for Barfliz in Darwin, Australia.

## Database Schema

### Table: `bars`

Stores bar/venue information for Darwin locations only.

```sql
CREATE TABLE bars (
  bar_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  lat double precision NOT NULL,
  lng double precision NOT NULL,
  city text DEFAULT 'Darwin',
  state text DEFAULT 'NT',
  country text DEFAULT 'AU',
  radar_place_id text,
  google_place_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT darwin_bounds_check CHECK (
    lat BETWEEN -12.55 AND -12.35 AND
    lng BETWEEN 130.75 AND 131.05
  )
);
```

**Indexes:**
- `idx_bars_radar_place_id` on `radar_place_id`
- `idx_bars_location` on `(lat, lng)`

### Table: `venue_sessions`

Tracks user check-ins and sessions at bars.

```sql
CREATE TABLE venue_sessions (
  session_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bar_id uuid NOT NULL REFERENCES bars(bar_id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('open', 'closed', 'invalid', 'closed_timeout')),
  checkin_method text NOT NULL DEFAULT 'radar_auto',
  confidence double precision,
  start_at timestamptz NOT NULL,
  end_at timestamptz,
  last_event_at timestamptz NOT NULL,
  dedupe_key text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
```

**Status Values:**
- `open` - User is currently at the bar
- `closed` - User left the bar (normal exit)
- `closed_timeout` - Session timed out after 25 minutes of inactivity
- `invalid` - Invalid session (reserved for future use)

**Indexes:**
- `idx_venue_sessions_bar_status` on `(bar_id, status)`
- `idx_venue_sessions_user_status` on `(user_id, status)`
- `idx_venue_sessions_bar_last_event` on `(bar_id, last_event_at DESC)`
- `idx_venue_sessions_user_last_event` on `(user_id, last_event_at DESC)`

### Table: `location_events`

Append-only audit log of all Radar events.

```sql
CREATE TABLE location_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bar_id uuid REFERENCES bars(bar_id) ON DELETE SET NULL,
  radar_place_id text,
  event_type text NOT NULL CHECK (event_type IN ('enter', 'exit', 'dwell')),
  occurred_at timestamptz NOT NULL,
  lat double precision,
  lng double precision,
  accuracy_m double precision,
  confidence double precision,
  raw_payload jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);
```

**Event Types:**
- `enter` - User entered a bar
- `exit` - User exited a bar
- `dwell` - User is dwelling at a bar (periodic update)

**Indexes:**
- `idx_location_events_user_occurred` on `(user_id, occurred_at DESC)`
- `idx_location_events_bar_occurred` on `(bar_id, occurred_at DESC)`
- `idx_location_events_radar_place` on `radar_place_id`

## Edge Functions

### 1. `radar-webhook`

**Endpoint:** `POST /functions/v1/radar-webhook`

**Purpose:** Receives Radar webhooks and processes bar entry/exit events.

**Authentication:** No JWT verification (webhook signature verified instead)

**Flow:**

1. **Verify Signature** - Validates HMAC-SHA256 signature using `RADAR_TEST_SECRET_KEY`
2. **Parse Event** - Extracts user ID, coordinates, confidence, accuracy, event type
3. **Darwin Bounds Check** - Returns 200 and ignores if outside Darwin bounds
4. **Quality Filters:**
   - Accuracy > 50m → Ignore (GPS bounce)
   - Confidence < 0.6 (or < 2 on 1-3 scale) → Ignore
5. **Bar Matching:**
   - First try: Match by `radar_place_id`
   - Second try: Find nearest bar within 120m using haversine distance
   - If no match → Return 200 and ignore
6. **Audit Log** - Write full event to `location_events`
7. **Deduplication** - Generate `dedupe_key` = `userId|barId|eventType|5minBucket`
8. **Session State Machine:**
   - **Enter:** Open new session or update existing
   - **Dwell:** Update `last_event_at` on open session
   - **Exit:** Close open session

**Session State Machine Logic:**

```
ENTER event:
  IF user has open session at SAME bar:
    → Update last_event_at only
  ELSE IF user has open session at DIFFERENT bar:
    → Close old session
    → Open new session at new bar
  ELSE:
    → Open new session

DWELL event:
  IF user has open session at this bar:
    → Update last_event_at

EXIT event:
  IF user has open session at this bar:
    → Close session (set end_at, status='closed')
```

### 2. `cleanup-stale-sessions`

**Endpoint:** `POST /functions/v1/cleanup-stale-sessions`

**Purpose:** Closes sessions where `last_event_at` < now() - 25 minutes.

**Authentication:** Requires JWT

**Usage:** Call this function periodically (e.g., via cron job or on-demand) to clean up stale sessions.

## Radar Event Mapping

### Example Radar Webhook Payload

```json
{
  "_id": "64a1b2c3d4e5f6g7h8i9j0k1",
  "type": "user.entered_place",
  "createdAt": "2026-02-14T12:30:00.000Z",
  "occurredAt": "2026-02-14T12:29:55.000Z",
  "user": {
    "userId": "radar_user_123",
    "externalId": "auth_uuid_from_bolt",
    "deviceId": "device_abc123"
  },
  "location": {
    "coordinates": [130.85, -12.45],
    "accuracy": 25
  },
  "place": {
    "_id": "radar_place_xyz789",
    "name": "The Darwin Hotel",
    "categories": ["bar", "restaurant"]
  },
  "confidence": 2,
  "duration": null
}
```

### Mapping to Barfliz Schema

| Radar Field | Barfliz Field | Notes |
|-------------|---------------|-------|
| `user.externalId` | `user_id` | Must match Bolt auth user_id |
| `type` | `event_type` | Mapped: `user.entered_place` → `enter` |
| `location.coordinates[0]` | `lng` | GeoJSON format (longitude first) |
| `location.coordinates[1]` | `lat` | GeoJSON format (latitude second) |
| `location.accuracy` | `accuracy_m` | GPS accuracy in meters |
| `confidence` | `confidence` | Radar confidence score |
| `occurredAt` | `occurred_at` | Event timestamp |
| `place._id` | `radar_place_id` | Used for bar matching |
| Full payload | `raw_payload` | Stored as JSONB |

### Event Type Mapping

| Radar Event Type | Barfliz Event Type |
|------------------|-------------------|
| `user.entered_place` | `enter` |
| `user.entered_geofence` | `enter` |
| `user.exited_place` | `exit` |
| `user.exited_geofence` | `exit` |
| `user.dwelling_at_place` | `dwell` |

## Environment Variables

Already configured:
- `RADAR_TEST_SECRET_KEY` - Radar webhook signing secret
- `DARWIN_NORTH=-12.35` - Northern boundary
- `DARWIN_SOUTH=-12.55` - Southern boundary
- `DARWIN_WEST=130.75` - Western boundary
- `DARWIN_EAST=131.05` - Eastern boundary
- `RADAR_ENV=test` - Test mode (enables debug logging)

## Testing the Webhook

### 1. Configure Radar Dashboard

In your Radar dashboard:
1. Go to Settings → Webhooks
2. Add webhook URL: `https://[your-project].supabase.co/functions/v1/radar-webhook`
3. Select events: `user.entered_place`, `user.exited_place`, `user.dwelling_at_place`
4. Secret key should match `RADAR_TEST_SECRET_KEY`

### 2. Test with Sample Data

```bash
curl -X POST https://[your-project].supabase.co/functions/v1/radar-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "test_event_123",
    "type": "user.entered_place",
    "createdAt": "2026-02-14T12:00:00.000Z",
    "occurredAt": "2026-02-14T12:00:00.000Z",
    "user": {
      "externalId": "your_user_uuid_here"
    },
    "location": {
      "coordinates": [130.85, -12.45],
      "accuracy": 25
    },
    "place": {
      "_id": "test_place_123",
      "name": "Test Bar"
    },
    "confidence": 2
  }'
```

### 3. Query Active Sessions

```sql
-- Get all users currently at bars
SELECT
  vs.session_id,
  vs.user_id,
  b.name as bar_name,
  vs.start_at,
  vs.last_event_at,
  EXTRACT(EPOCH FROM (NOW() - vs.start_at))/60 as minutes_at_bar
FROM venue_sessions vs
JOIN bars b ON b.bar_id = vs.bar_id
WHERE vs.status = 'open'
ORDER BY vs.last_event_at DESC;

-- Get bar population counts
SELECT
  b.bar_id,
  b.name,
  COUNT(*) as current_population
FROM venue_sessions vs
JOIN bars b ON b.bar_id = vs.bar_id
WHERE vs.status = 'open'
  AND vs.last_event_at > NOW() - INTERVAL '25 minutes'
GROUP BY b.bar_id, b.name
ORDER BY current_population DESC;
```

## Security

All tables have RLS enabled:
- **bars:** Authenticated users can view all bars
- **venue_sessions:** Users can view their own sessions and sessions at bars they're currently at
- **location_events:** Users can view their own location events
- Service role has full access for webhook processing

## Next Steps

1. **Add bars to database** - Populate the `bars` table with Darwin venues
2. **Configure Radar geofences** - Set up geofences in Radar for each bar
3. **Set up cron job** - Schedule `cleanup-stale-sessions` to run every 5-10 minutes
4. **Monitor logs** - Check edge function logs for webhook processing
5. **Build UI** - Create Flutter screens to display bar populations and user sessions
