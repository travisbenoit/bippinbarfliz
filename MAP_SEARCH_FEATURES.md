# Map Search Features

## Overview
Enhanced map functionality to allow users to search venues from any location on the map, not just their current GPS location.

## Features Implemented

### 1. Search This Area Button
- Added a new map pin button in the map controls (right side)
- Clicking it sets a search center at the current map view center
- Results are filtered based on distance from this search center instead of user location
- Allows users to explore venues in areas they're planning to visit

### 2. Visual Feedback
- When searching a custom area, a notification badge appears at bottom-left
- Shows "Searching This Area" with an X button to clear
- Clicking X or the recenter button returns to GPS-based search

### 3. Real Distance Calculations
- Fixed distance display bug where all venues showed 0.1 miles
- Venues now show accurate distances in km or miles based on regional settings
- Darwin venues: Range from 1-2.2 km from city center
- Florida venues: Range from 0.07 miles to 4+ miles from demo location

### 4. Map Interaction Flow
1. User opens map (centered on their GPS location by default)
2. User pans/zooms to explore a different area
3. User clicks "Search This Area" button
4. Results update to show venues near that map location
5. Distance filters apply from the search center
6. User can clear search to return to GPS-based results

### 5. Regional Auto-Activation
All venues in these regions automatically activate when added:
- Darwin, Australia
- All Florida cities (FL state)
- Fort Lauderdale, Sunrise, Davie, Weston

## Technical Details

### Distance Calculation
Uses Haversine formula for accurate great-circle distance:
```
distance = 6371 * 2 * arcsin(sqrt(
  sin²((lat2-lat1)/2) + cos(lat1) * cos(lat2) * sin²((lng2-lng1)/2)
))
```

### Search Center State
- `searchCenter`: null (use GPS) or {lat, lng} (custom search point)
- Filter logic checks searchCenter first, falls back to userLocation
- Cleared when user clicks recenter button

## User Benefits
- Explore venues in areas before arriving
- Plan routes and check out neighborhoods
- Find venues near destinations, not just current location
- More flexible and powerful search experience
