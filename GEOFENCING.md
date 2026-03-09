# Barfliz Geofencing System

## Overview

The Barfliz geofencing system is a **privacy-first, venue-based location tracking system** designed specifically for social drinking apps. Unlike traditional location tracking, this system:

- **Only tracks users when they're inside bar/club venues**
- **Never exposes precise GPS coordinates outside of venues**
- **Uses server-side validation to prevent location spoofing**
- **Implements adaptive precision for battery efficiency**
- **Respects user privacy with granular visibility controls**

## Core Principles

### 1. Privacy by Design
- Users are only "locatable" when inside a venue geofence
- Outside venues, no precise location is tracked or exposed
- All location verification happens server-side via Edge Functions
- Row Level Security (RLS) controls data access at the database level

### 2. Battery Efficiency
- Low-precision monitoring when far from venues
- High-precision only when near venue clusters
- Adaptive update intervals based on proximity

### 3. Anti-Spoofing
- Client sends location, but server verifies
- Minimum dwell time prevents drive-by check-ins
- Exit delay confirms users actually left

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Mobile App Layer                          │
│                                                              │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ GeofenceProvider│  │useGeofencing │  │Location Service│ │
│  │    (Context)    │←─│    (Hook)    │←─│   (Native)     │ │
│  └────────────────┘  └──────────────┘  └────────────────┘ │
│           │                  │                              │
└───────────┼──────────────────┼──────────────────────────────┘
            │                  │
            ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                  Supabase Edge Functions                     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ enter-venue  │  │ leave-venue  │  │ sync-venues  │     │
│  │   (POST)     │  │   (POST)     │  │   (POST)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│           │                  │                  │           │
└───────────┼──────────────────┼──────────────────┼───────────┘
            │                  │                  │
            ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Database                         │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────────────────┐   │
│  │     venues        │  │  user_venue_presence         │   │
│  │  (with geofences)│  │  (presence tracking)         │   │
│  └──────────────────┘  └──────────────────────────────┘   │
│                                                              │
│  ┌──────────────────┐                                       │
│  │ venue_clusters   │                                       │
│  │ (venue grouping) │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

## Database Schema

### `venues` Table
Stores bar/club locations with geofence definitions.

```typescript
{
  id: uuid (PK)
  name: string
  type: 'bar' | 'club' | 'lounge' | 'pub'
  address: string
  city: string
  state: string
  country: string (default: 'US')
  lat: number
  lng: number
  geofence_shape: jsonb // Polygon or circle definition
  geofence_radius_meters: number (default: 50, max: 500)
  google_place_id: string (unique)
  is_active: boolean
  metadata: jsonb
  created_at: timestamp
  updated_at: timestamp
}
```

**Indexes:**
- `idx_venues_lat_lng` - Fast proximity queries
- `idx_venues_city` - City-based filtering
- `idx_venues_active` - Active venue filtering

### `user_venue_presence` Table
Tracks when users are in venues with privacy controls.

```typescript
{
  id: uuid (PK)
  user_id: uuid (FK to users)
  venue_id: uuid (FK to venues)
  status: 'IN_VENUE' | 'LEFT_VENUE'
  entered_at: timestamp
  left_at: timestamp?
  last_seen_at: timestamp
  is_visible_in_venue: boolean
  dwell_seconds: number
  entry_method: 'AUTO_GEOFENCE' | 'MANUAL_CHECKIN'
  metadata: jsonb
  created_at: timestamp
  updated_at: timestamp
}
```

**Row Level Security:**
- Users can view their own presence records
- Users can only see OTHER users if:
  - `is_visible_in_venue = true`
  - `status = 'IN_VENUE'`
  - `left_at IS NULL`
  - Record is less than 24 hours old
- Only Edge Functions can write presence records

### `venue_clusters` Table
Groups nearby venues for efficient monitoring.

```typescript
{
  id: uuid (PK)
  name: string
  city: string
  center_lat: number
  center_lng: number
  radius_meters: number (default: 500, max: 5000)
  venue_ids: uuid[]
  is_active: boolean
  created_at: timestamp
  updated_at: timestamp
}
```

## Edge Functions

### `enter-venue`
**Endpoint:** `POST /functions/v1/enter-venue`

Validates and records when a user enters a venue geofence.

**Request:**
```typescript
{
  venue_id: string
  user_lat: number
  user_lng: number
  is_visible?: boolean // default: true
}
```

**Server-side Validation:**
1. Verify user is authenticated
2. Verify venue exists and is active
3. Calculate distance from user to venue center
4. Verify user is within geofence radius
5. Close any existing presence at other venues
6. Create new presence record

**Response:**
```typescript
{
  success: boolean
  presence_id?: string
  venue?: Venue
  error?: string
}
```

### `leave-venue`
**Endpoint:** `POST /functions/v1/leave-venue`

Records when a user leaves a venue geofence.

**Request:**
```typescript
{
  venue_id?: string
  presence_id?: string
  user_lat?: number
  user_lng?: number
}
```

**Server-side Validation:**
1. Verify user is authenticated
2. Find active presence record
3. If location provided, verify user is outside geofence
4. Calculate dwell time
5. Update presence status to LEFT_VENUE

**Response:**
```typescript
{
  success: boolean
  dwell_seconds?: number
  error?: string
}
```

### `sync-venues`
**Endpoint:** `POST /functions/v1/sync-venues`

Syncs venues from Google Places API.

**Request:**
```typescript
{
  city: string
  state?: string
  country?: string // default: 'US'
  lat?: number
  lng?: number
  radius_meters?: number // default: 5000
  types?: string[] // default: ['bar', 'night_club']
  google_api_key: string
}
```

**Process:**
1. Geocode city if lat/lng not provided
2. Search Google Places API for each type
3. For each place:
   - Check if venue exists by `google_place_id`
   - Update existing or insert new venue
   - Set geofence radius based on venue type

**Response:**
```typescript
{
  success: boolean
  venues_added: number
  venues_updated: number
  errors: number
  details: {
    added: string[]
    updated: string[]
    errors: string[]
  }
}
```

## Client-Side API

### `useGeofencing` Hook

```typescript
const {
  state,              // Current geofencing state
  isLoading,          // Loading indicator
  error,              // Error message
  startTracking,      // Start geofence monitoring
  stopTracking,       // Stop geofence monitoring
  updateLocation,     // Manually update location
  getCurrentPresence, // Get current presence record
  getCurrentVenue,    // Get current venue
  addEventListener,   // Listen for geofence events
} = useGeofencing(config);
```

**Configuration Options:**
```typescript
{
  minDwellTimeSeconds: 30,           // Min time before check-in
  exitDelaySeconds: 120,             // Delay before check-out
  highPrecisionThresholdMeters: 300, // Switch to high precision
  clusterProximityMeters: 500,       // Cluster detection radius
  updateIntervalLowPrecision: 60000, // 1 minute
  updateIntervalHighPrecision: 5000, // 5 seconds
  venueGeofenceBufferMeters: 20,     // Extra buffer
  privacyMode: 'visible',            // 'visible' | 'invisible' | 'friends_only'
}
```

**State Object:**
```typescript
{
  currentVenue?: Venue
  currentPresence?: UserVenuePresence
  nearbyVenues: NearbyVenue[]
  nearbyClusters: VenueCluster[]
  isTracking: boolean
  lastLocation?: Coordinates
  lastUpdateTime?: number
}
```

**Events:**
```typescript
addEventListener((event: GeofenceEvent) => {
  switch (event.type) {
    case 'ENTER':
      console.log('Entered venue:', event.venue);
      break;
    case 'EXIT':
      console.log('Left venue:', event.venue);
      break;
    case 'DWELL':
      console.log('Still in venue');
      break;
    case 'NEARBY':
      console.log('Near venues');
      break;
  }
});
```

### `GeofenceProvider` Component

Wrap your app to provide geofencing capabilities:

```tsx
import { GeofenceProvider } from './geolocation/GeofenceProvider';

function App() {
  return (
    <GeofenceProvider
      config={{
        privacyMode: 'visible',
        minDwellTimeSeconds: 30,
      }}
      autoStart={false}
    >
      <YourApp />
    </GeofenceProvider>
  );
}
```

Use the context:

```tsx
import { useGeofenceContext } from './geolocation/GeofenceProvider';

function MyComponent() {
  const {
    state,
    startTracking,
    stopTracking,
    isLocationEnabled,
  } = useGeofenceContext();

  return (
    <div>
      {state.currentVenue ? (
        <p>You're at {state.currentVenue.name}</p>
      ) : (
        <p>Not in any venue</p>
      )}

      <button onClick={startTracking}>
        Start Tracking
      </button>
    </div>
  );
}
```

## Usage Examples

### Basic Setup

```tsx
import { GeofenceProvider } from './geolocation/GeofenceProvider';

<GeofenceProvider autoStart={true}>
  <App />
</GeofenceProvider>
```

### Manual Control

```tsx
function VenueTracker() {
  const { state, startTracking, stopTracking, addEventListener } = useGeofenceContext();

  useEffect(() => {
    const unsubscribe = addEventListener((event) => {
      if (event.type === 'ENTER') {
        console.log(`Checked into ${event.venue?.name}`);
      }
    });

    return unsubscribe;
  }, []);

  return (
    <div>
      <button onClick={startTracking}>Enable Location</button>
      <button onClick={stopTracking}>Disable Location</button>

      {state.currentVenue && (
        <div>
          <h3>Currently at:</h3>
          <p>{state.currentVenue.name}</p>
          <p>{state.currentPresence?.dwell_seconds}s</p>
        </div>
      )}

      <h3>Nearby Venues:</h3>
      <ul>
        {state.nearbyVenues.map((venue) => (
          <li key={venue.id}>
            {venue.name} - {venue.distance_meters}m away
          </li>
        ))}
      </ul>
    </div>
  );
}
```

### Syncing Venues from Google Places

```typescript
const syncVenues = async (city: string, apiKey: string) => {
  const { data: session } = await supabase.auth.getSession();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/sync-venues`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session?.access_token}`,
      },
      body: JSON.stringify({
        city,
        state: 'CA',
        google_api_key: apiKey,
        types: ['bar', 'night_club'],
        radius_meters: 10000,
      }),
    }
  );

  const result = await response.json();
  console.log(`Added ${result.venues_added} venues`);
};
```

## Privacy Considerations

### What Gets Tracked

**INSIDE a venue geofence:**
- High-precision location (up to 10m accuracy)
- Venue association (which bar you're in)
- Entry/exit times
- Dwell duration

**OUTSIDE venue geofences:**
- **NO precise GPS coordinates**
- Low-precision location only for proximity detection
- No user-facing location data

### Visibility Control

Users control their visibility via `is_visible_in_venue`:

```typescript
// User is visible to others in the venue
is_visible_in_venue: true

// User is invisible (ghost mode)
is_visible_in_venue: false
```

Future enhancements:
- `friends_only` - Only visible to friends
- `friends_of_friends` - Extended visibility
- `venue_only` - Only visible in current venue

### Data Retention

- Active presence: Visible while `status = 'IN_VENUE'`
- Recent exits: Can show "left 5m ago" for configurable duration
- Historical presence: Kept for analytics but not exposed to users

## React Native Adaptation

This implementation uses the browser's Geolocation API. For React Native:

### Install Dependencies

```bash
npm install expo-location
# or
npm install react-native-geolocation-service
```

### Update GeofenceProvider

Replace browser API with Expo Location:

```typescript
import * as Location from 'expo-location';

// Request permissions
const { status } = await Location.requestForegroundPermissionsAsync();
const bgStatus = await Location.requestBackgroundPermissionsAsync();

// Start watching
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

// Stop watching
subscription.remove();
```

### Background Tracking

For iOS and Android background tracking:

```typescript
import * as TaskManager from 'expo-task-manager';

const LOCATION_TASK_NAME = 'background-location-task';

TaskManager.defineTask(LOCATION_TASK_NAME, async ({ data, error }) => {
  if (error) {
    console.error(error);
    return;
  }
  if (data) {
    const { locations } = data;
    // Process location updates
  }
});

await Location.startLocationUpdatesAsync(LOCATION_TASK_NAME, {
  accuracy: Location.Accuracy.Balanced,
  distanceInterval: 100,
  foregroundService: {
    notificationTitle: 'Barfliz',
    notificationBody: 'Tracking your location for venue check-ins',
  },
});
```

## Troubleshooting

### Location not updating
- Check browser/device permissions
- Verify geolocation is enabled
- Check console for errors
- Ensure HTTPS (required for geolocation)

### Can't enter venue
- Verify within geofence radius
- Check minimum dwell time
- Ensure venue is active
- Check server logs

### Can't see other users
- Verify they have `is_visible_in_venue = true`
- Check they're in the same venue
- Verify RLS policies are correct

## Security Best Practices

1. **Never trust client location** - Always verify server-side
2. **Use HTTPS** - Required for geolocation API
3. **Validate inputs** - Lat/lng bounds, venue IDs
4. **Rate limit** - Prevent spam check-ins
5. **Audit logs** - Track suspicious patterns
6. **Encrypt sensitive data** - Use Supabase encryption at rest

## Performance Optimization

1. **Index properly** - Lat/lng indexes for fast queries
2. **Cache venue data** - Client-side caching for nearby venues
3. **Batch updates** - Don't update on every GPS ping
4. **Use clusters** - Group venues to reduce queries
5. **Adaptive precision** - Low precision when far from venues

## Future Enhancements

- [ ] Machine learning for fraud detection
- [ ] Custom geofence shapes (polygons)
- [ ] Multiple venue check-ins (bar crawls)
- [ ] Friend proximity notifications
- [ ] Venue heatmaps
- [ ] Check-in streaks and gamification
- [ ] Integration with venue POS systems
- [ ] Automatic playlist syncing with venue music

## License

This geofencing system is part of the Barfliz application and subject to its license terms.
