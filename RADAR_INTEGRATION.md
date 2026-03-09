# Radar Integration Guide

## Overview

Barfliz now uses [Radar](https://radar.io) for production-ready geofencing and location tracking. Radar provides:

- **Battery-efficient location tracking**
- **Accurate geofencing with fraud detection**
- **Places API for venue discovery**
- **Background tracking support**
- **Cross-platform SDKs (Web, iOS, Android)**

## Setup

### Environment Variables

Your Radar credentials are already configured in `.env`:

```bash
VITE_RADAR_PUBLISHABLE_KEY=prj_test_pk_ea7c8d502a34cdc2601ee8f2ee2946d36aaa0876
RADAR_TEST_SECRET_KEY=prj_test_sk_ea7c8d502a34cdc2601ee8f2ee2946d36aaa0876
RADAR_ENV=test
```

**Important:** These are test keys. For production:
1. Go to [Radar Dashboard](https://radar.com/dashboard)
2. Switch to Live mode
3. Get production keys
4. Update `.env` with live keys

### Installation

Radar SDK is already installed:

```bash
npm install radar-sdk-js
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     React App Layer                          │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │RadarService  │←─│GeofenceProvider│←─│ Components  │     │
│  │   (Wrapper)  │  │   (Context)   │  │             │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                                                   │
└─────────┼───────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                      Radar SDK                               │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Tracking     │  │ Geofences    │  │ Places API   │     │
│  │              │  │              │  │              │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                  │                  │            │
└─────────┼──────────────────┼──────────────────┼────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   Radar Cloud API                            │
│                                                              │
│  • Fraud Detection                                          │
│  • Event Processing                                         │
│  • Geofence Management                                      │
│  • Places Database                                          │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│               Supabase Edge Functions                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ enter-venue  │  │ leave-venue  │                        │
│  │              │  │              │                        │
│  └──────────────┘  └──────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Initialize Radar

```typescript
import { radarService } from './services/radarService';

// Initialize (done automatically on first use)
await radarService.initialize();

// Set user ID (syncs with Supabase auth)
radarService.setUserId(userId);
```

### Track User Location

```typescript
// One-time location update
const location = await radarService.trackOnce();

// Track with specific coordinates
const location = await radarService.trackOnce({
  lat: 37.7749,
  lng: -122.4194,
});

// Start continuous tracking
radarService.startTracking({
  desiredStoppedUpdateInterval: 60,    // seconds when stopped
  desiredMovingUpdateInterval: 30,     // seconds when moving
  desiredSyncInterval: 60,             // sync to server interval
});

// Stop tracking
radarService.stopTracking();
```

### Create Geofences for Venues

```typescript
// Create a single geofence
const venue = {
  id: 'venue-123',
  name: 'The Mission Bar',
  lat: 37.7749,
  lng: -122.4194,
  geofence_radius_meters: 50,
  type: 'bar',
  city: 'San Francisco',
  state: 'CA',
};

await radarService.createGeofenceForVenue(venue);

// Sync multiple venues to Radar
const venues = [...]; // Array of venues
const result = await radarService.syncVenuesToRadar(venues);
console.log(`Synced ${result.success} venues, ${result.failed} failed`);
```

### Listen for Geofence Events

```typescript
// Listen for entry events
const unsubscribeEntry = radarService.onGeofenceEvent('enter', (event) => {
  console.log('Entered venue:', event.geofence?.description);
  console.log('Confidence:', event.confidence);
});

// Listen for exit events
const unsubscribeExit = radarService.onGeofenceEvent('exit', (event) => {
  console.log('Exited venue:', event.geofence?.description);
});

// Listen for dwell events
const unsubscribeDwell = radarService.onGeofenceEvent('dwell', (event) => {
  console.log('Dwelling in venue:', event.geofence?.description);
});

// Cleanup
unsubscribeEntry();
unsubscribeExit();
unsubscribeDwell();
```

### Search for Places

```typescript
// Search for bars/clubs near a location
const places = await radarService.searchPlaces(
  { lat: 37.7749, lng: -122.4194 },
  1000, // radius in meters
  ['bar', 'nightclub'] // optional chains filter
);

places.forEach(place => {
  console.log(place.name, place.location);
});
```

### Get Current Location

```typescript
const location = await radarService.getUserLocation();
if (location) {
  console.log(`User at: ${location.lat}, ${location.lng}`);
}
```

## Integration with Existing Geofencing

The Radar service works seamlessly with your existing geofencing system:

1. **Automatic venue entry/exit** - Radar events trigger your `enter-venue` and `leave-venue` edge functions
2. **Fraud detection** - Radar's ML detects fake locations
3. **Battery optimization** - Radar handles tracking efficiency
4. **Dual system** - You can use both custom geofencing and Radar simultaneously

### Example: Using Both Systems

```typescript
import { useGeofencing } from './geolocation/useGeofencing';
import { radarService } from './services/radarService';

function VenueTracker() {
  const { state, startTracking } = useGeofencing();

  useEffect(() => {
    // Initialize Radar
    radarService.initialize();

    // Listen for Radar events
    const unsubscribe = radarService.onGeofenceEvent('enter', (event) => {
      console.log('Radar detected entry:', event);
    });

    // Start custom geofencing
    startTracking();

    return () => {
      unsubscribe();
      radarService.stopTracking();
    };
  }, []);

  return <div>...</div>;
}
```

## Webhooks (Optional)

Configure Radar webhooks to receive events server-side:

1. Create a Supabase Edge Function to handle webhooks
2. Add webhook URL in Radar Dashboard: `https://your-project.supabase.co/functions/v1/radar-webhook`
3. Process events:

```typescript
// supabase/functions/radar-webhook/index.ts
Deno.serve(async (req) => {
  const event = await req.json();

  if (event.type === 'user.entered_geofence') {
    // Handle entry
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

## Testing

### Test Geofence Events

Use Radar Dashboard's simulator:
1. Go to [Radar Dashboard](https://radar.com/dashboard)
2. Click on "Users"
3. Find your user (by ID)
4. Use "Simulate location" to test geofence triggers

### Local Testing

```typescript
// Track with test location
await radarService.trackOnce({
  lat: 37.7749,
  lng: -122.4194,
});

// Check if geofences exist
const geofences = await radarService.getGeofences();
console.log('Active geofences:', geofences.length);
```

## Mobile App Integration

### React Native

```bash
npm install react-native-radar
```

```typescript
import Radar from 'react-native-radar';

// Initialize
Radar.initialize('YOUR_PUBLISHABLE_KEY');
Radar.setUserId(userId);

// Request permissions
await Radar.requestPermissions(true); // true = background

// Start tracking
Radar.startTrackingEfficient();

// Listen for events
Radar.on('location', (result) => {
  console.log('Location:', result.location);
});

Radar.on('events', (result) => {
  console.log('Events:', result.events);
});
```

### Flutter

```yaml
dependencies:
  flutter_radar: ^3.9.0
```

```dart
import 'package:flutter_radar/flutter_radar.dart';

// Initialize
await Radar.initialize('YOUR_PUBLISHABLE_KEY');
await Radar.setUserId(userId);

// Start tracking
await Radar.startTrackingEfficient();

// Listen for events
Radar.onEvents.listen((result) {
  print('Events: ${result.events}');
});
```

## Production Checklist

Before going live:

- [ ] Replace test keys with live keys
- [ ] Set up Radar webhooks (optional but recommended)
- [ ] Configure geofence metadata
- [ ] Test on physical devices
- [ ] Monitor usage in Radar Dashboard
- [ ] Set up alerts for API errors
- [ ] Review pricing and limits

## Pricing

Radar offers:
- **Free tier**: 100,000 API calls/month
- **Growth**: $99/month for 1M calls
- **Enterprise**: Custom pricing

Current usage:
- Each location update = 1 API call
- Creating geofence = 1 API call
- Places search = 1 API call per request

## Best Practices

1. **Initialize once** - Call `initialize()` on app start
2. **Stop tracking when not needed** - Save battery and API calls
3. **Use appropriate update intervals** - Balance accuracy vs battery
4. **Cache geofences** - Don't recreate on every venue update
5. **Handle errors gracefully** - Network issues can occur
6. **Test on real devices** - Simulators have limited GPS accuracy
7. **Monitor API usage** - Check Radar Dashboard regularly

## Troubleshooting

### Location not updating
- Check browser permissions
- Verify HTTPS (required for geolocation)
- Check Radar Dashboard for API errors
- Ensure publishable key is correct

### Geofences not triggering
- Verify geofence exists in Radar Dashboard
- Check geofence radius (min 100m recommended)
- Ensure tracking is started
- Verify user location is accurate

### API errors
- Check Radar API status
- Verify keys are correct
- Check rate limits in dashboard
- Review error logs in browser console

## Resources

- [Radar Documentation](https://radar.io/documentation)
- [Radar Dashboard](https://radar.com/dashboard)
- [Radar SDK Reference](https://radar.io/documentation/sdk)
- [Radar API Reference](https://radar.io/documentation/api)

## Support

For Radar-specific issues:
- Email: support@radar.io
- Slack: Join Radar Community
- Docs: https://radar.io/documentation
