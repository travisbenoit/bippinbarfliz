# Dashboard Features

## Overview

The Barfliz dashboard now includes powerful features to help users customize their experience and plan their night out effectively.

## New Features

### 1. Search Radius Control

Users can now adjust how far they want to search for venues directly from their dashboard.

**Features:**
- Preset radius options: 0.5km, 1km, 2km, 5km, 10km, 25km
- Radius preference is saved to user profile
- Automatically applies to venue searches
- Clear descriptions for each option (e.g., "Walking distance", "Nearby", "Wide search")

**Usage:**
```tsx
<RadiusControl
  currentRadius={searchRadius}
  onRadiusChange={(radius) => {
    setSearchRadius(radius);
    fetchNearbyVenues();
  }}
/>
```

**Database:**
- Added `preferred_radius_meters` column to users table
- Default: 5000m (5km)
- Range: 500m to 50000m (50km)

### 2. Weather Integration

Real-time weather information helps users plan their night appropriately.

**Features:**
- Current temperature and feels-like temperature
- Weather condition with icon (Clear, Cloudy, Rain, etc.)
- Humidity, wind speed, and visibility metrics
- Smart recommendations based on weather:
  - "Perfect for rooftop bars" (warm weather)
  - "Rainy night - indoor venues recommended"
  - "Bring a jacket tonight" (cold weather)
- Demo mode with sample data
- Optional OpenWeather API integration

**Usage:**
```tsx
<WeatherCard
  location="Los Angeles"
  apiKey="your-openweather-api-key" // optional
/>
```

**API Integration:**
To use real weather data, add your OpenWeather API key:
1. Get free API key from https://openweathermap.org/api
2. Pass it to the WeatherCard component
3. Weather updates automatically based on user's location

**Database:**
- Added `weather_location` column to users table
- Added `weather_enabled` boolean flag
- Users can customize their weather location

### 3. Uber Placeholder

A placeholder UI for future Uber integration, showing users what ride-sharing features are coming.

**Features:**
- Pickup and destination display
- Estimated time and fare preview
- Coming soon messaging
- Feature preview list:
  - Quick ride requests to venues
  - Split fare with swarm members
  - Track ride in real-time

**Usage:**
```tsx
<UberPlaceholder
  currentLocation="Your location"
  destination="The Rooftop Bar"
/>
```

**Future Integration:**
This component is ready to be connected to Uber's API when:
1. Uber API credentials are obtained
2. Deep linking is configured
3. Payment integration is setup

### 4. Quick Stats Dashboard

A visual overview of user's social landscape.

**Displays:**
- Number of people nearby
- Number of venues in radius
- Number of active swarms

## Dashboard Tab

The new Dashboard tab in the Home view provides quick access to all customization features.

**Layout:**
1. Weather Card - See tonight's weather
2. Radius Control - Adjust search area
3. Uber Placeholder - Ride preview
4. Quick Stats - Social overview

## User Experience Flow

```
1. User opens Barfliz
2. Dashboard tab shows by default
3. User sees weather: "72°F - Perfect for rooftop bars"
4. User adjusts radius to 2km for walking distance venues
5. User sees 15 venues, 8 people, 3 swarms in stats
6. User can preview Uber ride options (coming soon)
7. User switches to Venues tab to browse filtered results
```

## Database Schema Changes

### Users Table Additions

```sql
-- Radius preference
ALTER TABLE users ADD COLUMN preferred_radius_meters integer DEFAULT 5000
  CONSTRAINT valid_preferred_radius CHECK (
    preferred_radius_meters >= 500 AND
    preferred_radius_meters <= 50000
  );

-- Weather preferences
ALTER TABLE users ADD COLUMN weather_location text;
ALTER TABLE users ADD COLUMN weather_enabled boolean DEFAULT true;
```

## Component Files

- **`src/components/Map/RadiusControl.tsx`** - Radius selection UI
- **`src/components/Weather/WeatherCard.tsx`** - Weather display
- **`src/components/Transportation/UberPlaceholder.tsx`** - Uber preview
- **`src/components/Home/Home.tsx`** - Updated dashboard

## Configuration

### Weather API (Optional)

To enable real weather data:

1. Sign up at https://openweathermap.org/
2. Get your free API key
3. Add to environment or pass to WeatherCard component

Without an API key, the weather component shows demo data.

### Radius Options

Modify preset options in `RadiusControl.tsx`:

```typescript
const RADIUS_OPTIONS = [
  { value: 500, label: '0.5 km', description: 'Very close by' },
  { value: 1000, label: '1 km', description: 'Walking distance' },
  { value: 2000, label: '2 km', description: 'Short trip' },
  { value: 5000, label: '5 km', description: 'Nearby' },
  { value: 10000, label: '10 km', description: 'Extended area' },
  { value: 25000, label: '25 km', description: 'Wide search' },
];
```

## Mobile Responsive

All dashboard features are mobile-optimized:
- Touch-friendly controls
- Responsive grid layouts
- Optimized card sizes
- Smooth scrolling

## Accessibility

- Proper ARIA labels
- Keyboard navigation support
- High contrast color schemes
- Screen reader friendly

## Performance

- Weather data is cached
- Radius updates are debounced
- Lazy loading for heavy components
- Optimized re-renders

## Future Enhancements

### Weather
- [ ] Hourly forecast
- [ ] 7-day forecast
- [ ] Severe weather alerts
- [ ] Location-based recommendations

### Radius
- [ ] Save multiple favorite radii
- [ ] Different radii for different times
- [ ] Auto-adjust based on venue density

### Uber
- [ ] Real Uber API integration
- [ ] Ride price comparison
- [ ] Split fare with friends
- [ ] Ride scheduling
- [ ] Pool ride options
- [ ] Driver ratings

## Testing

### Radius Control
```bash
# Test different radius options
1. Open Dashboard tab
2. Click each radius option
3. Verify venues update
4. Check database for saved preference
```

### Weather
```bash
# Test weather display
1. Refresh dashboard
2. Verify weather loads
3. Check condition matches icon
4. Verify recommendations make sense
```

### Uber Placeholder
```bash
# Test UI display
1. View Uber section
2. Verify all information displays
3. Check disabled state on button
4. Verify coming soon message
```

## Support

For issues or questions about dashboard features:
- Check console for errors
- Verify database migrations applied
- Ensure user permissions are correct
- Check API keys if using weather API

## License

Part of the Barfliz application.
