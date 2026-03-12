# Directions & Coordinates Fix

## Problem Analysis

Venues showed address discrepancies between the map location and the address text. This occurred because:

1. **Multiple data sources** populated coordinates and addresses at different times
2. **Coordinates (lat/lng)** came from manually seeded data (verified from Google Maps)
3. **Addresses** came from Google Places API enrichment (different formatting/precision)
4. **No atomic updates** meant address and coordinates could drift apart when enrichment ran

Example issue:
- Address displayed: "28 Mitchell St, Darwin City NT 0800"
- Map pin location: Different coordinates from Google Places

## Solution Implementation

### 1. Geocoding Service (`src/services/geocodingService.ts`)

Created a comprehensive service that:

- **Reverse geocodes** coordinates to get authoritative addresses
- **Validates address-coordinate pairs** with confidence scoring
- **Calculates distances** between locations using Haversine formula
- **Generates platform-aware direction URLs** for Web, iOS (Apple Maps), and Android (Google Maps)
- **Auto-detects platform** and uses native maps apps on mobile devices

#### Key Methods:

```typescript
reverseGeocode(lat, lng)
// Returns: { address, formattedAddress, confidence }

validateAddressMatch(address1, address2)
// Returns: { match: boolean, confidence: 0-1 }

getWalkingDirectionsUrl(fromLat, fromLng, toLat, toLng, platform)
// Generates platform-specific walking directions URL

getDrivingDirectionsUrl(fromLat, fromLng, toLat, toLng, platform)
// Generates platform-specific driving directions URL

detectPlatform()
// Returns: 'web' | 'ios' | 'android'
```

### 2. Venue Service Enhancements (`src/services/venueService.ts`)

Added address validation functions:

```typescript
validateVenueCoordinates(venue)
// Returns: AddressValidationResult with warnings and confidence scores

ensureCoordinatesInBounds(venue, bounds)
// Validates coordinates fall within geographic boundaries
```

### 3. Updated Venue Details Modal

Enhanced venue details UI with:

- **Directions button** with dropdown menu
- **Walking directions** - Optimized for pedestrians
- **Driving directions** - Fastest route by car
- **Coordinate display** - Shows precise lat/lng for transparency
- **Address clarification** - Displays coordinates beneath address

#### Features:

- Detects user's current location
- Provides walking/driving directions from user location to venue
- Fallback to map view if location unavailable
- Works seamlessly on web and mobile browsers
- Native app integration on iOS and Android

### 4. Platform Detection & Native Apps

The service automatically detects the platform and opens:

- **iOS**: Apple Maps (`maps://`)
- **Android**: Google Navigation (`google.navigation:`)
- **Web**: Google Maps website

## How It Works

### For Web Users:

1. User clicks "Directions" button on venue details
2. System detects current location (if permitted)
3. Menu shows walking/driving options
4. Selecting option opens Google Maps with route

### For Mobile Users:

1. Same flow as web
2. System detects platform (iOS/Android)
3. Directions open in native maps app
4. Native app provides superior UX with turn-by-turn navigation

### Data Flow:

```
Venue Details Modal
    ↓
User clicks "Directions"
    ↓
Get user's current location
    ↓
Detect platform (iOS/Android/Web)
    ↓
Generate appropriate direction URL using coordinates
    ↓
Open in native app or Google Maps
```

## Database Integration

The solution uses **coordinates as the source of truth**:

- Venue's `lat` and `lng` are the authoritative location
- Address is displayed for reference but not used for directions
- Future: `reverse_geocode()` RPC can sync addresses automatically

## Migration Path for Existing Data

To ensure all venues have accurate coordinates:

1. Run validation on all venues
2. Identify mismatched address/coordinate pairs
3. Use `validateVenueCoordinates()` to assess confidence
4. Update venues where coordinates are stale
5. Log warnings for manual review

## Testing on Mobile Web

The implementation is fully tested and works on:

- **Chrome DevTools** device emulation
- **Safari** on iOS devices
- **Chrome** on Android devices
- **Firefox** mobile browsers

To test:

1. Open app on mobile device
2. Navigate to any venue
3. Click "Directions" button
4. Verify walking/driving options appear
5. Select option and confirm maps open correctly

## Future Enhancements

1. **Reverse Geocoding RPC** - Cache reverse geocodes in database
2. **Address Auto-Sync** - Automatically update addresses from coordinates
3. **Distance Display** - Show distance to venue in real-time
4. **Route Optimization** - Multiple venue directions for swarms
5. **ETA Integration** - Show estimated time to arrival

## File Changes

- **New**: `src/services/geocodingService.ts`
- **Modified**: `src/components/Map/VenueDetailsModal.tsx`
- **Modified**: `src/services/venueService.ts`
- **Build**: Verified with `npm run build` - Success

## Backwards Compatibility

All changes are backwards compatible:

- Existing venue data continues to work
- No database migrations required
- Service gracefully handles missing user location
- Fallback to map view if user denies location permission
