# Map Coordinate Validation & Cleanup

## Overview

This document explains the venue coordinate validation and fixes implemented to ensure venues display correctly on the map across all regions (Darwin, South Florida, and other locations).

## Issues Addressed

### 1. Venue Coordinates Out of Bounds
Some venues had coordinates that placed them outside their actual locations, sometimes appearing over water or in completely wrong cities.

### 2. Coordinate System Validation
Ensured all venues use the correct coordinate format (latitude, longitude) rather than swapped values.

### 3. Regional Filtering
Implemented validation to catch venues with impossible coordinates for their region.

## Solution Implemented

### Migration: `20260312_validate_venue_coordinates`

Created a database migration that:

1. **Deactivates obviously wrong Australian venues**
   - Coordinates outside lat -29 to -10
   - Coordinates outside lng 130 to 135
   - Exceptions: NSW venues (which span larger area)

2. **Validates Darwin-specific venues**
   - Checks postcodes 0800, 0810, 0820 (Darwin area)
   - Ensures coordinates within: -12.6 to -12.3 lat, 130.7 to 131.1 lng
   - Deactivates venues outside these bounds

3. **Validates South Florida venues**
   - Ensures US venues in area: 24-27 lat, -80-82 lng
   - Corrects any venues outside this range

4. **Prevents coordinate swaps**
   - Catches any coordinates with |lat| > 40 or |lng| > 200
   - These indicate lat/lng were swapped or corrupted

## How It Works

### Coordinate System (WGS84)

```
Latitude (lat):  -90 to +90
  - Negative = South of equator (Australia is -12 to -44)
  - Positive = North of equator

Longitude (lng): -180 to +180
  - Negative = West of Prime Meridian
  - Positive = East of Prime Meridian
  - Australia is +113 to +154 (all positive)
```

### Valid Ranges by Region

**Darwin, NT (Australia)**
- Latitude: -12.30 to -12.60 (south)
- Longitude: 130.70 to 131.10 (east)
- Postal codes: 0800, 0810, 0820

**South Florida (USA)**
- Latitude: 24.00 to 27.00 (north)
- Longitude: -82.00 to -80.00 (west)

### Validation Flow

```
Venue record updated/created
         ↓
Check if coordinates in valid range for region
         ↓
If outside bounds:
  - Mark is_active = false
  - Log for manual review
         ↓
If within bounds:
  - Keep is_active status
  - Use for map display
```

## Data Cleanup Results

The migration:
- Validated all Australian venues
- Validated all US venues
- Flagged suspicious coordinates for manual review
- Kept valid venues active for map display

## Testing the Fix

### Verify Darwin Venues Display Correctly

1. Open map focused on Darwin
2. Pan to downtown Darwin (Mitchell Street area)
3. Venues should display within -12.46, 130.84 bounds
4. No venues should appear over water/bay areas unless they're actual waterfront venues

### Verify South Florida Venues Display Correctly

1. Switch to US region
2. Navigate to South Florida area
3. Venues should display within Miami/Broward county bounds
4. All venues on land, not in Atlantic Ocean

### Test Map Bounds Filtering

1. Pan/zoom to specific area
2. Click "Search this area" button
3. Results filter to visible bounds only
4. Distance calculations work from map center

## Technical Details

### Database Table Structure

The `venues` table includes:
- `lat` (double precision) - Latitude coordinate
- `lng` (double precision) - Longitude coordinate
- `address` (text) - Human-readable address
- `city` (text) - City name
- `country` (text) - 2-letter country code
- `is_active` (boolean) - Whether venue displays on map

### Filtering in Application

**LocationService (`locationService.ts`)**:
```typescript
const validVenues = venues?.filter(venue =>
  venue.lat != null && venue.lng != null
) || [];
```

**MapView (`MapView.tsx`)**:
```typescript
const filterByMapBounds = (items) => {
  if (!mapBounds) return items;
  return items.filter(item =>
    item.lat >= mapBounds.sw[0] &&
    item.lat <= mapBounds.ne[0] &&
    item.lng >= mapBounds.sw[1] &&
    item.lng <= mapBounds.ne[1]
  );
};
```

## Future Improvements

1. **Reverse Geocoding Sync**
   - Automatically fetch correct addresses from coordinates
   - Keep address and coordinates synchronized

2. **Venue Clustering**
   - Group venues when zoomed out
   - Show cluster count instead of individual pins

3. **Region-Based Caching**
   - Cache venues by region
   - Faster loading for frequently viewed areas

4. **Manual Review Dashboard**
   - Admin tool to review deactivated venues
   - Easy reactivation if coordinates are corrected

5. **Address Verification**
   - Compare stored addresses with geocoded addresses
   - Flag mismatches for manual review

## Notes for Admins

### Adding Venues in New Regions

When adding venues to a new region:

1. **Know the coordinate bounds**: Research typical lat/lng for that region
2. **Verify on Google Maps**: Compare coordinates with actual venue location
3. **Test before activation**: Zoom to venue, verify correct location
4. **Use consistent precision**: Keep 4 decimal places for venue coordinates

### Debugging Venue Issues

If venues appear in wrong location:

1. **Check coordinates**: Use Google Maps to verify lat/lng
2. **Check is_active**: Ensure venue is marked active in database
3. **Check country**: Ensure correct country code matches region
4. **Check bounds**: Verify coordinates within regional bounds
5. **Test with "Search this area"**: Confirm bounds filtering works

## Build Status

✅ Build successful
- Database migration applied
- All venue validation rules active
- No TypeScript errors
- Ready for deployment

## Related Documentation

- `SEARCH_THIS_AREA_FIX.md` - How search bounds filtering works
- `DIRECTIONS_AND_COORDINATES_FIX.md` - Coordinate precision for directions
- `src/services/locationService.ts` - Venue fetching logic
- `src/components/Map/MapView.tsx` - Map filtering implementation
