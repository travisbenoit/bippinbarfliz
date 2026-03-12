# Directions Integration Guide

## Overview

The `geocodingService` provides a unified way to generate directions URLs that work across web, iOS, and Android platforms. This guide shows how to integrate directions into any component.

## Basic Usage

### Import the Service

```typescript
import geocodingService from '../../services/geocodingService';
```

### Generate a Directions URL

```typescript
// For walking directions from user's location to venue
const walkUrl = geocodingService.getWalkingDirectionsUrl(
  userLat,      // User's latitude
  userLng,      // User's longitude
  venueLat,     // Venue's latitude
  venueLng,     // Venue's longitude
  'web'         // or 'ios' or 'android', auto-detected if omitted
);

// For driving directions
const driveUrl = geocodingService.getDrivingDirectionsUrl(
  userLat,
  userLng,
  venueLat,
  venueLng,
  'web'
);

// Open in new window/app
window.open(walkUrl, '_blank');
```

## Platform Detection

The service automatically detects the platform:

```typescript
const platform = geocodingService.detectPlatform();
// Returns: 'web' | 'ios' | 'android'

// Use detected platform automatically
const url = geocodingService.getWalkingDirectionsUrl(
  fromLat, fromLng, toLat, toLng
  // Platform auto-detected
);
```

## Common Patterns

### Pattern 1: Basic Directions Button

```typescript
import { Navigation } from 'lucide-react';
import geocodingService from '../../services/geocodingService';

function DirectionsButton({ venueLat, venueLng, venueName }) {
  const handleDirections = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        const url = geocodingService.getWalkingDirectionsUrl(
          position.coords.latitude,
          position.coords.longitude,
          venueLat,
          venueLng
        );
        window.open(url, '_blank');
      });
    }
  };

  return (
    <button onClick={handleDirections} className="flex items-center gap-2">
      <Navigation className="w-4 h-4" />
      Get Directions
    </button>
  );
}
```

### Pattern 2: Directions Menu with Walking/Driving Options

```typescript
import { Footprints, Car } from 'lucide-react';
import geocodingService from '../../services/geocodingService';

function DirectionsMenu({ venueLat, venueLng, venueName }) {
  const [userLocation, setUserLocation] = useState(null);

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((position) => {
        setUserLocation({
          lat: position.coords.latitude,
          lng: position.coords.longitude,
        });
      });
    }
  }, []);

  if (!userLocation) return null;

  return (
    <div className="flex gap-2">
      <button
        onClick={() => {
          const url = geocodingService.getWalkingDirectionsUrl(
            userLocation.lat,
            userLocation.lng,
            venueLat,
            venueLng
          );
          window.open(url, '_blank');
        }}
        className="flex items-center gap-2"
      >
        <Footprints className="w-4 h-4" />
        Walk
      </button>

      <button
        onClick={() => {
          const url = geocodingService.getDrivingDirectionsUrl(
            userLocation.lat,
            userLocation.lng,
            venueLat,
            venueLng
          );
          window.open(url, '_blank');
        }}
        className="flex items-center gap-2"
      >
        <Car className="w-4 h-4" />
        Drive
      </button>
    </div>
  );
}
```

### Pattern 3: Distance Calculation

```typescript
import geocodingService from '../../services/geocodingService';

function VenueDistance({ userLat, userLng, venueLat, venueLng }) {
  const distanceKm = geocodingService.calculateDistance(
    userLat,
    userLng,
    venueLat,
    venueLng
  );

  return (
    <span>
      {distanceKm.toFixed(1)} km away
    </span>
  );
}
```

### Pattern 4: Address Validation (for Admins)

```typescript
import { validateVenueCoordinates } from '../../services/venueService';

async function ValidateVenue(venue) {
  const result = await validateVenueCoordinates(venue);

  if (result.warnings.length > 0) {
    console.warn('Address/coordinate mismatch:', result.warnings);
  }

  return result.addressMatch && result.matchConfidence > 0.7;
}
```

## Mobile-Specific Features

### Opening Native Maps Apps

The service automatically opens the correct maps app based on platform:

```typescript
// On iOS: Opens Apple Maps
// On Android: Opens Google Navigation
// On Web: Opens Google Maps website
const url = geocodingService.getWalkingDirectionsUrl(
  fromLat, fromLng, toLat, toLng
);
window.open(url, '_blank');
```

### Handling Location Permission Denied

```typescript
function SafeDirections({ venueLat, venueLng }) {
  const handleDirections = () => {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        // Success - use user's location
        const url = geocodingService.getWalkingDirectionsUrl(
          position.coords.latitude,
          position.coords.longitude,
          venueLat,
          venueLng
        );
        window.open(url, '_blank');
      },
      (error) => {
        // Fallback - just show venue on map
        const url = geocodingService.getDirectionsUrl(
          venueLat,
          venueLng,
          venueName
        );
        window.open(url, '_blank');
      }
    );
  };

  return <button onClick={handleDirections}>Directions</button>;
}
```

## Component Examples

### VenueCard with Directions

```typescript
function VenueCard({ venue }) {
  const [userLocation, setUserLocation] = useState(null);

  useEffect(() => {
    navigator.geolocation.getCurrentPosition((pos) => {
      setUserLocation({
        lat: pos.coords.latitude,
        lng: pos.coords.longitude,
      });
    });
  }, []);

  return (
    <div className="venue-card">
      <h3>{venue.name}</h3>
      <p>{venue.address}</p>

      {userLocation && (
        <button
          onClick={() => {
            const url = geocodingService.getWalkingDirectionsUrl(
              userLocation.lat,
              userLocation.lng,
              venue.lat,
              venue.lng
            );
            window.open(url, '_blank');
          }}
        >
          Get Directions
        </button>
      )}
    </div>
  );
}
```

### Map with Multi-Venue Routing

```typescript
function MultiVenueRoute({ venues }) {
  const [userLocation, setUserLocation] = useState(null);

  const handleRouteVenues = () => {
    if (!userLocation) return;

    // For multiple venues, use the first as destination
    const url = geocodingService.getDrivingDirectionsUrl(
      userLocation.lat,
      userLocation.lng,
      venues[0].lat,
      venues[0].lng
    );

    // Note: Adding waypoints requires different approach
    // This is a basic example - expand as needed
    window.open(url, '_blank');
  };

  return (
    <button onClick={handleRouteVenues}>
      Route to These Venues
    </button>
  );
}
```

## Advanced: Custom Platform URLs

For custom URLs, generate them manually:

```typescript
// Web - Google Maps with query parameter
const webUrl = `https://maps.google.com/maps/dir/${fromLat},${fromLng}/${toLat},${toLng}/?travelmode=walking`;

// iOS - Apple Maps scheme
const iosUrl = `maps://maps.apple.com/?saddr=${fromLat},${fromLng}&daddr=${toLat},${toLng}&dirflg=w`;

// Android - Google Navigation intent
const androidUrl = `google.navigation:q=${toLat},${toLng}&mode=w`;
```

## Error Handling

```typescript
async function getDirectionsWithErrorHandling(
  userLat,
  userLng,
  venueLat,
  venueLng,
  travelMode = 'walking'
) {
  try {
    if (!userLat || !userLng || !venueLat || !venueLng) {
      console.error('Invalid coordinates provided');
      return null;
    }

    const url = travelMode === 'walking'
      ? geocodingService.getWalkingDirectionsUrl(
          userLat, userLng, venueLat, venueLng
        )
      : geocodingService.getDrivingDirectionsUrl(
          userLat, userLng, venueLat, venueLng
        );

    return url;
  } catch (error) {
    console.error('Direction URL generation failed:', error);
    return null;
  }
}
```

## Testing

### Unit Tests

```typescript
import geocodingService from '../../services/geocodingService';

describe('geocodingService', () => {
  test('generateWalkingDirectionsUrl', () => {
    const url = geocodingService.getWalkingDirectionsUrl(
      -12.46, 130.84,  // Darwin
      -12.47, 130.85,  // Nearby
      'web'
    );
    expect(url).toContain('maps.google.com');
  });

  test('detectPlatform', () => {
    const platform = geocodingService.detectPlatform();
    expect(['web', 'ios', 'android']).toContain(platform);
  });

  test('calculateDistance', () => {
    const distance = geocodingService.calculateDistance(
      -12.46, 130.84,  // Darwin
      -12.47, 130.85
    );
    expect(distance).toBeGreaterThan(0);
  });
});
```

### Manual Testing

1. **Web**: Open in browser, test all direction types
2. **iOS**: Test on iPhone Safari, confirm Apple Maps opens
3. **Android**: Test on Android Chrome, confirm Google Navigation opens
4. **Location denied**: Test without location permission
5. **Missing coordinates**: Test with incomplete venue data

## Performance Considerations

- Geocoding service caches results (24-hour TTL)
- No external API calls for direction URL generation
- Platform detection runs once per session
- Distance calculations use efficient Haversine formula

## Future Enhancements

1. **Waypoint support** - Multiple venue directions
2. **Traffic layer** - Show real-time traffic conditions
3. **ETA updates** - Live estimated time of arrival
4. **Alternative routes** - Compare different route options
5. **Public transit** - Bus, train, metro directions
