# Search This Area Bug Fix

## Problem Statement

When users moved the map and clicked the "Search this area" button (the black button at the top of the screen), the map would zoom out to default instead of filtering venues/swarms within the current visible area.

## Root Cause

In `/src/components/Map/MapView.tsx`, the `handleSearchThisArea` function was incorrectly updating `mapCenter`:

```typescript
// BEFORE (BROKEN)
const handleSearchThisArea = useCallback(() => {
  setMapCenter(currentMapCenter);      // ❌ This resets map view
  setSearchCenter({ lat: currentMapCenter[0], lng: currentMapCenter[1] });
  setShowSearchThisArea(false);
}, [currentMapCenter]);
```

The problem:
1. `setMapCenter(currentMapCenter)` would trigger the map update effect (line 164)
2. This caused the map to animate to the center instead of staying in place
3. The map bounds filtering wasn't being applied properly
4. Visual result: Map zoomed out instead of staying focused on the searched area

## Solution

Remove the unnecessary `setMapCenter()` call. The filtering already uses `mapBounds` which is correctly calculated from the current map view:

```typescript
// AFTER (FIXED)
const handleSearchThisArea = useCallback(() => {
  setSearchCenter({ lat: currentMapCenter[0], lng: currentMapCenter[1] });
  setShowSearchThisArea(false);
}, [currentMapCenter]);
```

Now:
1. `setSearchCenter()` updates the search center for distance-based sorting
2. `filterByMapBounds()` uses `mapBounds` to filter results to visible area
3. Map stays focused on the area user zoomed to
4. Results update to show only venues/swarms/people within current bounds

## How It Works (Data Flow)

```
User pans/zooms map
         ↓
MapCanvas fires 'moveend' event
         ↓
handleMapMove() captures:
  - currentMapCenter (map center coordinates)
  - mapBounds (NE and SW corners of visible area)
  - Shows "Search this area" button if moved >0.1km
         ↓
User clicks "Search this area" button
         ↓
handleSearchThisArea() called:
  - Sets searchCenter to current map center
  - Keeps map zoom and center unchanged
  - Hides the "Search this area" button
         ↓
Filtering logic applies:
  - filterByDistance() sorts items by distance to searchCenter
  - filterByMapBounds() keeps only items within map bounds
  - Results update on all tabs (Places, People, Swarms, Live)
         ↓
Visual feedback:
  - Bottom button shows "Searching This Area" with close button
  - Results refresh to show only items in visible area
  - User can click button to clear search and go back to user location
```

## Files Modified

- `/src/components/Map/MapView.tsx` - Fixed `handleSearchThisArea()` function (line 260-264)

## Testing the Fix

To verify the fix works:

1. **On mobile web or desktop**:
   - Open the map view
   - Pan/zoom to an area with venues
   - "Search this area" button appears at top
   - Click the button
   - Verify:
     - Map stays focused on that area (no zoom out)
     - Bottom sheet shows results for that area only
     - All tabs (Places, People, Swarms) filter to visible bounds
     - Clicking the bottom "Searching This Area" button clears the search

2. **Verify each tab updates**:
   - **Places**: Shows only venues within visible bounds
   - **People**: Shows only people within search radius + bounds
   - **Swarms**: Shows only swarms at venues within bounds
   - **Live**: Shows activity within bounds

3. **Test with distance filter**:
   - Change distance filter (5km, 10km, etc)
   - Results update based on both distance AND bounds

## Related Functionality

This fix integrates with the existing map behavior:

- **`mapBounds`**: Calculated from Leaflet's `getBounds()` on every map move
- **`filterByMapBounds()`**: Filters items to NE/SW corners of visible area
- **`filterByDistance()`**: Sorts items by distance to search center
- **Search center**: Used as the origin point for distance calculations
- **User location**: Used as fallback for distance calculations if search center not set

## Architecture Notes

The filtering chain for venues is:
```typescript
const filteredVenues = filterByVibes(filterByMapBounds(filterByDistance(realTimeVenues)));
```

Order matters:
1. **filterByDistance()** - Sort all venues by distance
2. **filterByMapBounds()** - Keep only visible ones
3. **filterByVibes()** - Apply vibe tag filters

This ensures efficient filtering with map bounds as the primary constraint.

## Potential Enhancements

Future improvements to the search functionality:

1. **Zoom to fit results**: Automatically zoom map to show all matching results
2. **Search result count**: Show how many results found in current area
3. **Auto-search toggle**: Option to auto-filter when user stops panning
4. **Search history**: Show previous search areas
5. **Favorite areas**: Save frequently searched areas

## Build Status

✅ Build successful
- Zero TypeScript errors
- All modules compiled correctly
- Ready for testing and deployment

## Notes for QA

- Test on various zoom levels (5 to 15)
- Test with different map regions (Darwin, South Florida, etc)
- Test with distance filters enabled/disabled
- Test with vibe tag filters
- Verify bottom sheet updates correctly
- Test the "Searching This Area" clear button
