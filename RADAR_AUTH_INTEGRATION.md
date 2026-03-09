# Radar Authentication Integration

## Overview

The Radar SDK is now automatically integrated with Supabase Authentication. When users sign in, their Supabase user ID is automatically set as the Radar external user ID.

## How It Works

### Automatic User ID Mapping

The `AuthContext` automatically syncs authentication state with Radar:

1. **On Sign In**: `Radar.setUserId(user.id)` is called with the Supabase auth user ID
2. **On Sign Out**: `Radar.setUserId(null)` clears the user association
3. **On App Load**: If a session exists, the user ID is automatically set

### Webhook Integration

The Radar webhook receives events with the user ID in the `user.externalId` field:

```typescript
const userId = event.user?.externalId || event.user?.userId;
```

This maps directly to your Supabase `auth.users.id`, allowing seamless integration between:
- Radar geofence events
- User venue presence tracking
- Location-based features

## Testing the Integration

### 1. Client-Side (Browser Console)

```javascript
// Check if Radar user is set
Radar.getUser().then(result => {
  console.log('Radar User ID:', result.user.userId);
  console.log('External ID:', result.user.externalId);
});
```

### 2. Generate Test Geofence Event

Use Radar's testing tools or simulate location events to trigger webhooks.

### 3. Verify in Database

Check the `location_events` table:

```sql
SELECT
  user_id,
  event_type,
  place_name,
  latitude,
  longitude,
  created_at
FROM location_events
ORDER BY created_at DESC
LIMIT 10;
```

Check `user_venue_presence` for active sessions:

```sql
SELECT
  u.name,
  v.name as venue_name,
  uvp.status,
  uvp.entered_at,
  uvp.dwell_seconds
FROM user_venue_presence uvp
JOIN users u ON u.id = uvp.user_id
JOIN venues v ON v.id = uvp.venue_id
WHERE uvp.status = 'IN_VENUE'
ORDER BY uvp.entered_at DESC;
```

## Environment Variables

Required for webhook processing:

```env
# Radar Authentication
RADAR_TEST_SECRET_KEY=prj_test_sk_...
RADAR_ENV=test

# Darwin Geographic Bounds
DARWIN_NORTH=-12.35
DARWIN_SOUTH=-12.55
DARWIN_WEST=130.75
DARWIN_EAST=131.05
```

## Webhook URL

```
https://knfoinehzqtadssunkba.supabase.co/functions/v1/radar-webhook
```

Configure this in your Radar Dashboard under Webhooks.

## Event Flow

1. User signs in → `Radar.setUserId(auth_user_id)`
2. User enters Darwin venue → Radar detects geofence
3. Radar sends webhook to your Edge Function
4. Webhook validates signature & Darwin bounds
5. Event written to `location_events` table
6. Session created in `user_venue_presence` table
7. User's friends see them at the venue in real-time

## Security Features

- HMAC-SHA256 signature verification
- 5-minute replay attack protection
- Geographic bounds checking (Darwin only)
- Service role authentication for database writes
- Automatic deduplication using event IDs

## Monitoring

Check Edge Function logs:

```bash
supabase functions logs radar-webhook
```

In test mode (`RADAR_ENV=test`), debug logs are enabled.
