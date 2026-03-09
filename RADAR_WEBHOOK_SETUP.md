# Radar Webhook Setup Guide

## Overview

Secure Edge Function endpoint to receive and process Radar location events with signature verification, geographic validation, and automatic venue session management.

## Webhook URL

```
https://knfoinehzqtadssunkba.supabase.co/functions/v1/radar-webhook
```

## Features

### 1. Security
- **HMAC-SHA256 signature verification** using `RADAR_TEST_SECRET_KEY`
- **Timestamp validation** - rejects events older than 5 minutes (replay attack prevention)
- **Public endpoint** - no JWT required (webhook uses signature instead)

### 2. Geographic Validation
- **Darwin bounding box enforcement**:
  - North: -12.35
  - South: -12.55
  - West: 130.75
  - East: 131.05
- Events outside this area are rejected with 400 status

### 3. Deduplication
- **5-minute time buckets** prevent duplicate processing
- **Unique constraint** on: `user_id + place_id + event_type + time_bucket`
- Duplicate events return 200 status with "duplicate" message

### 4. Event Processing

#### Stored in `location_events` table:
- Raw event payload (JSONB)
- Parsed location data (lat/lng)
- Event metadata (type, confidence, accuracy)
- Time bucket for deduplication
- Processing status flag

#### Automatic Venue Session Management:

**When `user.entered_place` or `user.entered_geofence`:**
- Creates record in `user_venue_presence` table
- Sets status to `IN_VENUE`
- Records entry timestamp and coordinates
- Marks entry method as `RADAR_WEBHOOK`

**When `user.exited_place` or `user.exited_geofence`:**
- Updates existing presence record
- Sets status to `LEFT_VENUE`
- Calculates and stores dwell time in seconds
- Records exit timestamp

## Configuring Radar Dashboard

### Step 1: Add Webhook URL

1. Go to [Radar Dashboard](https://radar.com/dashboard)
2. Navigate to **Settings** → **Webhooks**
3. Click **Add Webhook**
4. Enter webhook URL:
   ```
   https://knfoinehzqtadssunkba.supabase.co/functions/v1/radar-webhook
   ```

### Step 2: Select Events

Enable these event types:
- ✅ `user.entered_place`
- ✅ `user.exited_place`
- ✅ `user.entered_geofence`
- ✅ `user.exited_geofence`

Optional (for debugging):
- ⬜ `user.updated_location`
- ⬜ `user.dwelled_in_geofence`

### Step 3: Configure Signature

Radar will automatically sign webhooks using your secret key. The signature is sent in the `Radar-Signature` header.

**Format:** `t=timestamp,v1=signature`

The function automatically verifies this signature using `RADAR_TEST_SECRET_KEY` from environment variables.

### Step 4: Test the Webhook

Use Radar's "Send Test Event" button in the webhook configuration to verify:
1. Signature verification works
2. Event is processed successfully
3. Returns 200 status code

## Testing Locally

### Test with curl (requires signature):

```bash
# This will be rejected without valid signature
curl -X POST https://knfoinehzqtadssunkba.supabase.co/functions/v1/radar-webhook \
  -H "Content-Type: application/json" \
  -d '{
    "_id": "test_event_123",
    "type": "user.entered_place",
    "createdAt": "2026-02-14T10:30:00.000Z",
    "user": {
      "userId": "your-user-id-here"
    },
    "location": {
      "coordinates": [130.85, -12.45],
      "accuracy": 10
    },
    "place": {
      "_id": "venue-id-123",
      "name": "Test Venue Darwin"
    },
    "confidence": 3
  }'
```

### Check Event Logs

Query the database to see processed events:

```sql
-- View recent location events
SELECT
  event_type,
  place_name,
  latitude,
  longitude,
  confidence,
  created_at
FROM location_events
ORDER BY created_at DESC
LIMIT 10;

-- Check venue sessions
SELECT
  u.name,
  v.name as venue_name,
  p.status,
  p.entered_at,
  p.left_at,
  p.dwell_seconds
FROM user_venue_presence p
JOIN users u ON u.id = p.user_id
JOIN venues v ON v.id = p.venue_id
ORDER BY p.created_at DESC
LIMIT 10;
```

## Response Codes

| Code | Description |
|------|-------------|
| 200 | Success - event processed |
| 200 | Success - duplicate event (already processed) |
| 400 | Invalid location coordinates |
| 400 | Location outside Darwin bounds |
| 400 | No user ID in event |
| 401 | Invalid webhook signature |
| 500 | Server error |

## Event Flow

```
Radar Event → Webhook Endpoint
              ↓
       Verify Signature
              ↓
    Validate Darwin Bounds
              ↓
       Check Duplication
              ↓
    Insert location_events
              ↓
    Process Venue Session
              ↓
   Update user_venue_presence
              ↓
       Return 200 Success
```

## Environment Variables

These are automatically configured in Supabase:

- `RADAR_TEST_SECRET_KEY` - For signature verification
- `SUPABASE_URL` - Database URL
- `SUPABASE_SERVICE_ROLE_KEY` - Admin access for writing presence records

## Troubleshooting

### "Invalid signature" error
- Verify `RADAR_TEST_SECRET_KEY` matches your Radar dashboard secret key
- Check that webhook is configured in Radar dashboard
- Ensure timestamp is current (within 5 minutes)

### "Location outside Darwin area" error
- Verify test coordinates are within bounds:
  - Latitude: -12.55 to -12.35
  - Longitude: 130.75 to 131.05
- Darwin city center: `-12.4634, 130.8456`

### Events not creating venue sessions
- Check that `venue_id` in database matches Radar `place._id` or `geofence.externalId`
- Verify event type is `user.entered_place` or `user.entered_geofence`
- Check Edge Function logs in Supabase dashboard

## Monitoring

View real-time logs:
1. Go to Supabase Dashboard
2. Navigate to **Edge Functions** → **radar-webhook**
3. Click **Logs** tab
4. See all webhook invocations and errors

## Security Notes

1. **Signature verification** prevents unauthorized webhook calls
2. **Timestamp validation** prevents replay attacks
3. **Geographic bounds** ensure only Darwin events are processed
4. **Deduplication** prevents duplicate processing
5. **Service role access** ensures proper RLS bypass for system operations

## Next Steps

1. Configure webhook in Radar dashboard
2. Sync venues to Radar geofences (via Radar Settings in app)
3. Test with real location events
4. Monitor logs for any issues
5. Set up alerts for webhook failures (optional)
