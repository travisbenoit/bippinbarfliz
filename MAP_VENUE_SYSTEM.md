# Map & Venue System - Technical Documentation

## Overview
This document explains how the map and venue display system works, ensuring 1:1 correspondence between map markers and list items.

## Current Darwin Test Setup

### Darwin Venues in Database
There are currently **5 active venues** in Darwin, Australia:

1. **Boarding House** - Brewery (44 Mitchell Street)
2. **Monsoons Bar & Cocktail Lounge** - Bar (Mitchell Street)
3. **Nightcliff Hotel** - Nightclub
4. **Rorys Karaoke Bar** - Bar
5. **Shenanigans Irish Bar** - Bar (69 Smith Street)

All venues are:
- Located near coordinates: `-12.46, 130.84` (Darwin CBD)
- Active (`is_active = true`)
- Have 80m geofence radius
- Country code: `AU`

### Default Map Position for Darwin
- **Coordinates**: `[-12.4634, 130.8456]`
- **Initial Zoom**: Automatically calculated based on user's radius preference
- **Demo Mode**: When `userCountryCode = 'AU'`, defaults to Darwin coordinates

## Map Zoom System

### Dynamic Zoom Calculation
The map automatically adjusts zoom level based on search radius:

```typescript
Radius (km)  →  Zoom Level
≤ 1 km       →  15 (street level)
≤ 2 km       →  14
≤ 5 km       →  13
≤ 10 km      →  12 (default 6-mile view)
≤ 15 km      →  11
≤ 25 km      →  10
> 25 km      →  9
```

### Zoom Persistence
- Zoom level is saved when user changes distance filter
- Recenter button uses appropriate zoom for current radius
- Initial zoom is calculated from user's saved `preferred_radius_meters`

## Venue Loading Flow

### 1. Data Fetching (`locationService.ts`)
```typescript
fetchNearbyVenues(centerLat, centerLng, radiusKm, countryCode)
```
- Queries `venues` table filtered by:
  - `country = countryCode` (from localStorage or 'US')
  - `is_active = true`
- Calculates distance from center point to each venue
- Filters venues within `radiusKm`
- Fetches user counts from `user_venue_presence` table

### 2. Hook Integration (`useMapData.ts`)
```typescript
useMapData(userLocation, distanceFilter)
```
- Calls `fetchNearbyVenues()` every 30 seconds
- Subscribes to real-time updates on venue presence changes
- Returns: `{ swarms, users, venues }`

### 3. Map View Filtering (`MapView.tsx`)
```typescript
const filteredVenues = filterByVibes(filterByDistance(realTimeVenues))
```
- **Distance Filter**: Applies Haversine formula, filters within radius
- **Vibe Filter**: Optional filter by vibe tags
- Same filtering applied to both map markers AND list

### 4. Marker Rendering (`MapCanvas.tsx`)
```typescript
filteredVenues.forEach(venue => {
  // Create marker with category icon and color
  // Position at [venue.lat, venue.lng]
  // Show user count badge if > 0
})
```

### 5. List Rendering (`MapBottomSheet.tsx`)
```typescript
filteredVenues.map(venue => {
  // Render list item
  // Show same data as map marker
})
```

## Venue Category Icons & Colors

Each venue category has a unique emoji and color:

| Category | Emoji | Color |
|----------|-------|-------|
| Club | 🎵 | Purple (#8B5CF6) |
| Brewery | 🍺 | Orange (#F59E0B) |
| Rooftop | 🌆 | Cyan (#06B6D4) |
| Lounge | 🍸 | Pink (#EC4899) |
| Sports Bar | 🏈 | Green (#10B981) |
| Bar | 🍻 | Pink (#E91E63) |
| Restaurant | 🍽️ | Gray (#6B7280) |
| Nightclub | 💃 | Purple (#A855F7) |
| Pub | 🍺 | Orange (#D97706) |
| Wine Bar | 🍷 | Red (#DC2626) |

## Map Marker Styling

### Standard Marker
- **Size**: 44x44px
- **Border**: 2px solid (category color)
- **Background**: Gradient using category color (15% to 8% opacity)
- **Shadow**: Multi-layer for depth
- **Hover**: Scales to 115%

### User Count Badge
- **Position**: Top-right corner (-8px offset)
- **Size**: 22x22px (min width)
- **Background**: Green gradient (#10b981 to #059669)
- **Animation**: Subtle pulse every 2s
- **Border**: 2px white border

### Hotspot Marker (venues with users)
- **Size**: 52x52px
- **Glow Effect**: Orange pulsing animation
- **Flame Icon**: Centered white SVG
- **Badge**: Shows user count

## Ensuring 1:1 Map-List Correspondence

### Key Principles
1. **Single Source of Truth**: `filteredVenues` array used for BOTH map and list
2. **Same Filtering**: Distance and vibe filters applied identically
3. **Proper Zoom**: Map zoomed out enough to show all filtered venues
4. **No Separate Queries**: Map markers and list items come from same data fetch

### Testing Checklist
- [ ] Dropdown count matches number of map markers
- [ ] Clicking marker and list item shows same venue details
- [ ] Changing radius updates both map and list simultaneously
- [ ] All venues in list are visible on map (zoom out if needed)
- [ ] Vibe filters affect both map and list identically

## Country-Specific Behavior

### Australia (AU)
- Default center: Darwin (-12.4634, 130.8456)
- Distance unit: Kilometers
- Default radius: 10 km
- Currency: AUD
- Phone format: +61

### United States (US)
- Default center: Fort Lauderdale (26.1003, -80.3882)
- Distance unit: Miles
- Default radius: 6 miles
- Currency: USD
- Phone format: +1

## Real-Time Features

### Venue Presence Updates
- Subscribes to `user_venue_presence` table changes
- Updates user counts in real-time
- Shows active users at each venue
- Filters by `status = 'IN_VENUE'` and `is_visible_in_venue = true`

### Location Updates
- Subscribes to user location changes
- Refetches nearby venues when user moves
- 30-second polling interval for reliability

## Troubleshooting

### Issue: Map shows fewer markers than list
**Cause**: Map zoom too high (too close)
**Fix**: Map now auto-adjusts zoom based on radius

### Issue: Venues not appearing
**Check**:
1. `is_active = true` in database
2. Country code matches (`AU` for Australia)
3. Venue coordinates within search radius
4. User location correctly set

### Issue: Zoom resets on page load
**Fix**: Zoom now calculated from saved `preferred_radius_meters`

### Issue: Wrong default location
**Check**: `localStorage.getItem('userCountryCode')` returns correct code

## Database Schema Reference

### venues table
```sql
- id: uuid (PK)
- name: text
- address: text
- lat: numeric
- lng: numeric
- category: text
- is_active: boolean
- country: text (e.g., 'AU', 'US')
- city: text
- geofence_radius_meters: integer
- rating: numeric
- photo_url: text
```

### user_venue_presence table
```sql
- user_id: uuid (FK)
- venue_id: uuid (FK)
- status: enum ('IN_VENUE', 'NEARBY', 'LEFT')
- is_visible_in_venue: boolean
- dwell_seconds: integer
```

## Adding New Venues

To add venues for a new city/region:

1. Insert into `venues` table with:
   - Correct `lat`, `lng` coordinates
   - `country` code (2-letter ISO)
   - `city` name
   - `category` from supported list
   - `is_active = true`
   - `geofence_radius_meters` (recommended: 80)

2. Update default coordinates in `MapView.tsx` if new country:
   ```typescript
   const countryDefaults: Record<string, [number, number]> = {
     // Add new entry here
   };
   ```

3. Test by setting `localStorage.setItem('userCountryCode', 'XX')`

## Performance Notes

- Venues cached locally for 30 seconds
- Maximum 100 users fetched at once
- Distance calculations use Haversine formula
- Map markers use HTML divIcon for better performance
- Real-time subscriptions use Supabase channels
