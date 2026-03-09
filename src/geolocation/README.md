# Geofencing Module

This directory contains the complete geofencing and location privacy system for Barfliz.

## Quick Start

### 1. Setup Provider

Wrap your app with `GeofenceProvider`:

```tsx
import { GeofenceProvider } from './src/geolocation/GeofenceProvider';

function App() {
  return (
    <GeofenceProvider
      config={{
        minDwellTimeSeconds: 30,
        privacyMode: 'visible',
      }}
      autoStart={true}
    >
      <YourApp />
    </GeofenceProvider>
  );
}
```

### 2. Use in Components

```tsx
import { useGeofenceContext } from './src/geolocation/GeofenceProvider';

function VenueStatus() {
  const { state, startTracking } = useGeofenceContext();

  if (!state.isTracking) {
    return <button onClick={startTracking}>Enable Location</button>;
  }

  if (state.currentVenue) {
    return <p>You're at {state.currentVenue.name}!</p>;
  }

  return <p>Not in any venue</p>;
}
```

### 3. Listen for Events

```tsx
import { useEffect } from 'react';
import { useGeofenceContext } from './src/geolocation/GeofenceProvider';

function EventLogger() {
  const { addEventListener } = useGeofenceContext();

  useEffect(() => {
    const unsubscribe = addEventListener((event) => {
      console.log('Geofence event:', event.type, event.venue?.name);
    });

    return unsubscribe;
  }, [addEventListener]);

  return null;
}
```

## Files

- **`types.ts`** - TypeScript type definitions for all geofencing entities
- **`utils.ts`** - Distance calculations, geofence checks, and utility functions
- **`useGeofencing.ts`** - React hook for geofencing logic
- **`GeofenceProvider.tsx`** - React Context provider for app-wide geofencing

## Key Features

### Privacy-First Design
- Only tracks users inside venue geofences
- No precise GPS outside venues
- Server-side validation prevents spoofing

### Battery Efficient
- Adaptive precision based on proximity
- Low-frequency updates when far from venues
- High-frequency only when near venues

### Robust
- Handles overlapping geofences
- Minimum dwell time prevents accidental check-ins
- Exit delay confirms users left the venue

## Configuration

```typescript
interface GeofenceConfig {
  minDwellTimeSeconds: number;           // Default: 30
  exitDelaySeconds: number;             // Default: 120
  highPrecisionThresholdMeters: number; // Default: 300
  clusterProximityMeters: number;       // Default: 500
  updateIntervalLowPrecision: number;   // Default: 60000 (1 min)
  updateIntervalHighPrecision: number;  // Default: 5000 (5 sec)
  venueGeofenceBufferMeters: number;    // Default: 20
  privacyMode: 'visible' | 'invisible' | 'friends_only'; // Default: 'visible'
}
```

## React Native Adaptation

For mobile apps, replace browser Geolocation API with:

### Expo Location

```bash
npx expo install expo-location
```

```typescript
import * as Location from 'expo-location';

// Request permissions
await Location.requestForegroundPermissionsAsync();
await Location.requestBackgroundPermissionsAsync();

// Watch position
const subscription = await Location.watchPositionAsync(
  {
    accuracy: Location.Accuracy.High,
    distanceInterval: 50,
  },
  (location) => {
    updateLocation({
      lat: location.coords.latitude,
      lng: location.coords.longitude,
    });
  }
);
```

### react-native-geolocation-service

```bash
npm install react-native-geolocation-service
```

```typescript
import Geolocation from 'react-native-geolocation-service';

// Request permissions (iOS/Android)
import { request, PERMISSIONS } from 'react-native-permissions';

// Watch position
const watchId = Geolocation.watchPosition(
  (position) => {
    updateLocation({
      lat: position.coords.latitude,
      lng: position.coords.longitude,
    });
  },
  (error) => console.error(error),
  {
    enableHighAccuracy: true,
    distanceFilter: 50,
    interval: 5000,
    fastestInterval: 2000,
  }
);
```

## API Reference

See [GEOFENCING.md](../GEOFENCING.md) for complete documentation.

## Examples

### Show Nearby Venues

```tsx
function NearbyVenues() {
  const { state } = useGeofenceContext();

  return (
    <div>
      <h3>Nearby Venues</h3>
      {state.nearbyVenues.map((venue) => (
        <div key={venue.id}>
          <p>{venue.name}</p>
          <p>{Math.round(venue.distance_meters)}m away</p>
          {venue.is_in_geofence && <span>Inside geofence!</span>}
        </div>
      ))}
    </div>
  );
}
```

### Current Presence Info

```tsx
function PresenceInfo() {
  const { state } = useGeofenceContext();

  if (!state.currentPresence) {
    return <p>Not checked in anywhere</p>;
  }

  const dwellMinutes = Math.floor(state.currentPresence.dwell_seconds / 60);

  return (
    <div>
      <p>You've been at {state.currentVenue?.name}</p>
      <p>for {dwellMinutes} minutes</p>
    </div>
  );
}
```

### Manual Location Update

```tsx
function ManualCheckIn() {
  const { updateLocation } = useGeofenceContext();

  const handleManualCheckIn = () => {
    navigator.geolocation.getCurrentPosition((position) => {
      updateLocation({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      });
    });
  };

  return <button onClick={handleManualCheckIn}>Check In</button>;
}
```

## Testing

### Mock Location Updates

```typescript
import { useGeofenceContext } from './src/geolocation/GeofenceProvider';

function TestControls() {
  const { updateLocation } = useGeofenceContext();

  const testLocations = {
    insideBar: { lat: 37.7749, lng: -122.4194 },
    outsideBar: { lat: 37.7750, lng: -122.4200 },
  };

  return (
    <div>
      <button onClick={() => updateLocation(testLocations.insideBar)}>
        Simulate Inside Bar
      </button>
      <button onClick={() => updateLocation(testLocations.outsideBar)}>
        Simulate Outside Bar
      </button>
    </div>
  );
}
```

## Troubleshooting

### Location permissions not working
- Ensure HTTPS (required for browser geolocation)
- Check browser settings for location permissions
- For React Native, verify Info.plist / AndroidManifest.xml

### Can't enter venue
- Verify you're within the geofence radius
- Check minimum dwell time hasn't passed yet
- Ensure venue `is_active = true`

### Events not firing
- Check `addEventListener` is called
- Verify tracking is started with `startTracking()`
- Check console for errors

## Security Notes

1. **Never expose raw GPS outside venues** - The system enforces this by design
2. **Always validate server-side** - Edge Functions verify all location claims
3. **Use RLS policies** - Database enforces privacy rules
4. **Rate limit check-ins** - Prevent abuse on the Edge Function level

## Performance Tips

1. **Cache venue data locally** - Reduce database queries
2. **Use venue clusters** - Efficiently detect proximity to venue groups
3. **Batch updates** - Don't call `updateLocation` on every GPS tick
4. **Adaptive intervals** - Increase update frequency only when near venues
