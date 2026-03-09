# Barfliz Geofencing System - Quick Start Guide

## What Was Built

A complete **privacy-first, venue-based geofencing system** for Barfliz that:

✅ **Only tracks users inside bar/club venues** - No GPS tracking outside venues
✅ **Server-side validation** - Prevents location spoofing via Edge Functions
✅ **Adaptive precision** - Battery-efficient location monitoring
✅ **Row Level Security** - Privacy controls at the database level
✅ **Google Places integration** - Easy venue data syncing
✅ **Full TypeScript support** - Type-safe APIs and hooks

## Architecture Overview

```
┌──────────────────────────────────────────────────────┐
│  Mobile App (React/React Native)                     │
│  - GeofenceProvider (Context)                        │
│  - useGeofencing (Hook)                              │
│  - Location Services                                 │
└────────────┬─────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────┐
│  Supabase Edge Functions                             │
│  - enter-venue (POST)                                │
│  - leave-venue (POST)                                │
│  - sync-venues (POST)                                │
└────────────┬─────────────────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────────────────┐
│  Supabase Database                                   │
│  - venues (with geofences)                           │
│  - user_venue_presence (privacy-controlled)          │
│  - venue_clusters (efficient monitoring)             │
└──────────────────────────────────────────────────────┘
```

## What You Get

### 1. Database Schema ✅
- **`venues`** - Bar/club locations with circular geofences (50-500m radius)
- **`user_venue_presence`** - Privacy-controlled presence tracking
- **`venue_clusters`** - Grouped venues for efficient monitoring
- **Helper functions** - Distance calculations, geofence checks

### 2. Edge Functions ✅
- **`enter-venue`** - Server-side venue entry validation
- **`leave-venue`** - Server-side venue exit validation
- **`sync-venues`** - Import venues from Google Places API

### 3. Client SDK ✅
- **`useGeofencing`** - React hook for geofencing
- **`GeofenceProvider`** - Context provider for app-wide state
- **Utility functions** - Distance, geofence checks, formatting
- **TypeScript types** - Full type definitions

### 4. Debug Component ✅
- **`GeofenceDebug`** - Real-time monitoring UI
- Shows current venue, nearby venues, event log
- Perfect for testing and debugging

## Quick Integration

### Step 1: Wrap Your App

```tsx
// In your main App.tsx
import { GeofenceProvider } from './src/geolocation/GeofenceProvider';

function App() {
  return (
    <GeofenceProvider
      config={{
        minDwellTimeSeconds: 30,    // Wait 30s before check-in
        exitDelaySeconds: 120,      // Wait 2min before check-out
        privacyMode: 'visible',     // User visibility setting
      }}
      autoStart={false} // Don't auto-start tracking
    >
      <YourExistingApp />
    </GeofenceProvider>
  );
}
```

### Step 2: Use in Components

```tsx
import { useGeofenceContext } from './src/geolocation/GeofenceProvider';

function VenueChecker() {
  const { state, startTracking, stopTracking } = useGeofenceContext();

  return (
    <div>
      <button onClick={startTracking}>Enable Location</button>

      {state.currentVenue ? (
        <p>You're at {state.currentVenue.name}!</p>
      ) : (
        <p>Not in any venue</p>
      )}

      <ul>
        {state.nearbyVenues.map(v => (
          <li key={v.id}>{v.name} - {v.distance_meters}m</li>
        ))}
      </ul>
    </div>
  );
}
```

### Step 3: Sync Venues

Use the Edge Function to import venues from Google Places:

```typescript
const syncBarsInCity = async (city: string, googleApiKey: string) => {
  const { data: session } = await supabase.auth.getSession();

  const response = await fetch(
    `${process.env.VITE_SUPABASE_URL}/functions/v1/sync-venues`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session?.access_token}`,
      },
      body: JSON.stringify({
        city: city,
        state: 'CA',
        country: 'US',
        google_api_key: googleApiKey,
        types: ['bar', 'night_club'],
        radius_meters: 10000,
      }),
    }
  );

  const result = await response.json();
  console.log(`Synced ${result.venues_added} venues`);
};

// Example usage
await syncBarsInCity('San Francisco', 'your-google-api-key');
```

## Testing the System

### Option 1: Use the Debug Component

Add the debug component to your app:

```tsx
import GeofenceDebug from './src/components/Geofence/GeofenceDebug';

// In your router or navigation
<Route path="/debug/geofence" element={<GeofenceDebug />} />
```

Navigate to `/debug/geofence` to see:
- Real-time tracking status
- Current venue check-in
- Nearby venues with distances
- Event log

### Option 2: Manual Testing

```tsx
import { useGeofenceContext } from './src/geolocation/GeofenceProvider';

function TestControls() {
  const { updateLocation } = useGeofenceContext();

  // Coordinates of a test bar
  const testBar = { lat: 37.7749, lng: -122.4194 };

  return (
    <button onClick={() => updateLocation(testBar)}>
      Simulate Check-In
    </button>
  );
}
```

## Privacy Features

### What Gets Tracked

**INSIDE a venue geofence:**
- ✅ Which venue you're in
- ✅ Entry/exit times
- ✅ Dwell duration
- ✅ Visibility preference

**OUTSIDE venue geofences:**
- ❌ NO precise GPS coordinates exposed
- ❌ NO user-visible location data
- ✅ Low-precision proximity detection only

### User Visibility Control

Users can control their visibility:

```typescript
// Visible to all users in the venue
privacyMode: 'visible'

// Invisible (ghost mode)
privacyMode: 'invisible'

// Future: friends only
privacyMode: 'friends_only'
```

## How It Works

### 1. Location Monitoring

```
User Opens App
     ↓
Requests Location Permission
     ↓
Low-Precision Monitoring (60s intervals)
     ↓
Detects Proximity to Venue Cluster (< 500m)
     ↓
Switches to High-Precision (5s intervals)
     ↓
User Enters Geofence
     ↓
Waits 30s (min dwell time)
     ↓
Calls enter-venue Edge Function
     ↓
Server Validates Location
     ↓
Creates Presence Record
     ↓
User Now Visible in Venue
```

### 2. Server-Side Validation

Every check-in is verified server-side:

```typescript
// Client sends:
{
  venue_id: "abc-123",
  user_lat: 37.7749,
  user_lng: -122.4194
}

// Server verifies:
1. User is authenticated ✓
2. Venue exists and is active ✓
3. Calculate distance to venue ✓
4. User is within geofence radius ✓
5. Close other active presences ✓
6. Create new presence record ✓
```

### 3. Privacy Enforcement

Row Level Security ensures privacy:

```sql
-- Users can ONLY see other users if:
-- 1. They have is_visible_in_venue = true
-- 2. Their status is IN_VENUE
-- 3. They haven't left (left_at IS NULL)
-- 4. Record is less than 24 hours old

CREATE POLICY "Users can view visible presence of others"
  ON user_venue_presence FOR SELECT
  TO authenticated
  USING (
    is_visible_in_venue = true
    AND status = 'IN_VENUE'
    AND left_at IS NULL
    AND last_seen_at > now() - interval '24 hours'
  );
```

## Configuration Options

```typescript
interface GeofenceConfig {
  // Wait 30s before confirming check-in
  minDwellTimeSeconds: 30;

  // Wait 2 minutes before check-out
  exitDelaySeconds: 120;

  // Switch to high precision within 300m
  highPrecisionThresholdMeters: 300;

  // Detect venue clusters within 500m
  clusterProximityMeters: 500;

  // Update every 60s when far from venues
  updateIntervalLowPrecision: 60000;

  // Update every 5s when near venues
  updateIntervalHighPrecision: 5000;

  // Extra buffer around geofence
  venueGeofenceBufferMeters: 20;

  // User visibility setting
  privacyMode: 'visible' | 'invisible' | 'friends_only';
}
```

## React Native Adaptation

The current implementation uses browser Geolocation API. For React Native:

### Install Dependencies

```bash
npx expo install expo-location
```

### Update GeofenceProvider

```typescript
import * as Location from 'expo-location';

// Request permissions
const { status } = await Location.requestForegroundPermissionsAsync();
const bgStatus = await Location.requestBackgroundPermissionsAsync();

// Watch position
const subscription = await Location.watchPositionAsync(
  {
    accuracy: Location.Accuracy.High,
    distanceInterval: 50,
    timeInterval: 5000,
  },
  (location) => {
    updateLocation({
      lat: location.coords.latitude,
      lng: location.coords.longitude,
    });
  }
);
```

See `src/geolocation/README.md` for complete React Native integration guide.

## Files Created

### Database
- `supabase/migrations/add_geofencing_to_venues.sql` - Database schema

### Edge Functions
- `supabase/functions/enter-venue/index.ts` - Enter venue function
- `supabase/functions/leave-venue/index.ts` - Leave venue function
- `supabase/functions/sync-venues/index.ts` - Sync from Google Places

### Client SDK
- `src/geolocation/types.ts` - TypeScript type definitions
- `src/geolocation/utils.ts` - Utility functions
- `src/geolocation/useGeofencing.ts` - Geofencing hook
- `src/geolocation/GeofenceProvider.tsx` - Context provider
- `src/geolocation/index.ts` - Barrel exports

### Components
- `src/components/Geofence/GeofenceDebug.tsx` - Debug UI

### Documentation
- `GEOFENCING.md` - Complete system documentation
- `GEOFENCING_QUICKSTART.md` - This file
- `src/geolocation/README.md` - SDK documentation

## Next Steps

### 1. Get a Google Places API Key
Visit https://console.cloud.google.com/apis/credentials
- Create a new project
- Enable Places API
- Create API key
- Restrict to Places API and your domains

### 2. Sync Initial Venue Data

```typescript
await syncBarsInCity('San Francisco', 'YOUR_GOOGLE_API_KEY');
await syncBarsInCity('Los Angeles', 'YOUR_GOOGLE_API_KEY');
await syncBarsInCity('New York', 'YOUR_GOOGLE_API_KEY');
```

### 3. Test with Debug Component

Navigate to your debug route and:
1. Click "Start Tracking"
2. Grant location permissions
3. Watch nearby venues appear
4. Simulate or physically enter a venue
5. Observe check-in after 30 seconds

### 4. Integrate into Your App

Add geofencing to your existing features:
- Show "Friends at this venue" lists
- Enable venue-based chat
- Display live venue crowds
- Send proximity notifications

## Troubleshooting

### Can't get location permissions
- Ensure HTTPS (required for browser geolocation)
- Check browser settings
- For mobile, verify Info.plist / AndroidManifest.xml

### Venues not appearing
- Verify `is_active = true` in database
- Check distance calculations
- Ensure venues were synced for your area

### Can't check in
- Verify you're within geofence radius (default 50m)
- Wait for minimum dwell time (30s)
- Check console for Edge Function errors

### Not seeing other users
- Verify they have `is_visible_in_venue = true`
- Check they're in the same venue
- Ensure RLS policies are applied

## Security Checklist

✅ Location verification happens server-side
✅ RLS policies prevent unauthorized data access
✅ No raw GPS exposed outside venues
✅ JWT authentication on all Edge Functions
✅ Input validation on all coordinates
✅ Rate limiting recommended for production

## Performance Optimization

✅ Adaptive precision reduces battery drain
✅ Venue clustering reduces database queries
✅ Indexes on lat/lng for fast proximity searches
✅ Client-side caching of nearby venues
✅ Debounced location updates

## Support

For detailed documentation, see:
- `GEOFENCING.md` - Complete system documentation
- `src/geolocation/README.md` - Client SDK documentation

For issues or questions:
- Check console logs for errors
- Use GeofenceDebug component for testing
- Verify database migrations applied correctly

## License

This geofencing system is part of the Barfliz application.
