# Google Place Details API

## Endpoint
```
GET /functions/v1/google-place-details?bar_id=<uuid>
```

## Purpose
Fetches detailed information from Google Places API for bars that have been linked to a Google Place ID. Darwin-only with 24-hour caching to minimize API costs.

## Environment Variables Required
- `GOOGLE_MAPS_SERVER_KEY` - Set in Supabase Project Settings → Edge Functions → Environment Variables

## Darwin Bounds
```
North: -12.35
South: -12.55
West: 130.75
East: 131.05
```

## Request

### Headers
```
Authorization: Bearer <user_jwt_token>
```

### Query Parameters
- `bar_id` (required) - UUID of the bar

### Example Request
```bash
curl "https://your-project.supabase.co/functions/v1/google-place-details?bar_id=123e4567-e89b-12d3-a456-426614174000" \
  -H "Authorization: Bearer <token>"
```

## Behavior

1. **Read bar_id** from query parameters
2. **Fetch bar** - Returns 404 if not found
3. **Darwin guard** - Returns 400 if bar is outside Darwin bounds (does NOT call Google)
4. **Check linking** - If `google_place_id` is null, returns `{ needs_linking: true }`
5. **Check cache** - If cached data exists and is less than 24 hours old, returns cached data with `cache_hit: true`
6. **Fetch from Google** - Calls Google Place Details API with minimal field selection
7. **Normalize response** - Converts to stable JSON structure for Flutter
8. **Update cache** - Upserts into `google_place_cache` table
9. **Update fetch time** - Sets `bars.google_last_fetched_at = now()`
10. **Return JSON** - Returns normalized place details

## Minimal Field Selection (Cost Optimization)

The function requests ONLY these fields from Google Places API:
```
name,rating,user_ratings_total,photos,opening_hours,formatted_address
```

This minimal field selection significantly reduces API costs compared to requesting all fields.

## Response Schema

### Success Response
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "google_place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "name": "The Deck Bar",
  "rating": 4.5,
  "review_count": 287,
  "address": "22 Mitchell St, Darwin City NT 0800, Australia",
  "opening_hours": {
    "open_now": true,
    "weekday_text": [
      "Monday: 11:00 AM – 12:00 AM",
      "Tuesday: 11:00 AM – 12:00 AM",
      "Wednesday: 11:00 AM – 12:00 AM",
      "Thursday: 11:00 AM – 2:00 AM",
      "Friday: 11:00 AM – 2:00 AM",
      "Saturday: 11:00 AM – 2:00 AM",
      "Sunday: 11:00 AM – 12:00 AM"
    ]
  },
  "photos": [
    "CmRaAAAA...",
    "CmRaAAAA...",
    "CmRaAAAA..."
  ],
  "cache_hit": false
}
```

### Cached Response (< 24 hours old)
Same as above but with:
```json
{
  "cache_hit": true
}
```

### Needs Linking Response
```json
{
  "needs_linking": true,
  "message": "Bar not yet linked to Google Place. Call /link-google-place first."
}
```

### Error - Bar Not Found
**Status:** 404
```json
{
  "error": "Bar not found"
}
```

### Error - Outside Darwin Bounds
**Status:** 400
```json
{
  "error": "Bar is outside Darwin bounds",
  "bounds": {
    "north": -12.35,
    "south": -12.55,
    "west": 130.75,
    "east": 131.05
  },
  "bar_location": {
    "lat": -12.60,
    "lng": 130.80
  }
}
```

### Error - Missing bar_id
**Status:** 400
```json
{
  "error": "Missing bar_id query parameter"
}
```

### Error - Unauthorized
**Status:** 401
```json
{
  "error": "Unauthorized"
}
```

## Photo References

The `photos` array contains photo references (or names) that can be used with the Google Places Photo API:

```javascript
const photoUrl = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${photoReference}&key=${apiKey}`;
```

## Example Usage (JavaScript)

```javascript
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(
  `${supabaseUrl}/functions/v1/google-place-details?bar_id=123e4567-e89b-12d3-a456-426614174000`,
  {
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
    }
  }
);

const result = await response.json();

if (result.needs_linking) {
  console.log('Bar needs to be linked to Google Place first');
} else if (result.cache_hit) {
  console.log('Returned from cache:', result);
} else {
  console.log('Fresh from Google API:', result);
}
```

## Example Usage (Flutter/Dart)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>> fetchGooglePlaceDetails(String barId) async {
  final response = await Supabase.instance.client.functions.invoke(
    'google-place-details',
    queryParameters: {'bar_id': barId},
  );

  if (response.status == 200) {
    final data = response.data as Map<String, dynamic>;

    if (data['needs_linking'] == true) {
      throw Exception('Bar needs to be linked to Google Place first');
    }

    return data;
  } else {
    throw Exception('Failed to fetch place details');
  }
}

// Usage
try {
  final details = await fetchGooglePlaceDetails('123e4567-e89b-12d3-a456-426614174000');
  print('Rating: ${details['rating']}');
  print('Reviews: ${details['review_count']}');
  print('Cached: ${details['cache_hit']}');
} catch (e) {
  print('Error: $e');
}
```

## Caching Strategy

### Cache Table: `google_place_cache`
- Stores normalized JSON response
- 24-hour TTL (Time To Live)
- Automatic cache invalidation after 24 hours
- Upserted on each fresh fetch

### Cache Hit vs Miss
- **Cache Hit** (`cache_hit: true`) - Data retrieved from database, no Google API call
- **Cache Miss** (`cache_hit: false`) - Fresh data from Google API, cache updated

### Cache Benefits
1. **Cost Reduction** - Minimizes billable Google API calls
2. **Performance** - Faster response times for cached data
3. **Rate Limit Protection** - Reduces risk of hitting API quotas

## Database Updates

### On Fresh Fetch (Cache Miss)
1. **Upserts** `google_place_cache`:
```sql
INSERT INTO google_place_cache (bar_id, place_id, cached_data, cached_at)
VALUES ($1, $2, $3, NOW())
ON CONFLICT (bar_id) DO UPDATE SET
  place_id = $2,
  cached_data = $3,
  cached_at = NOW();
```

2. **Updates** `bars.google_last_fetched_at`:
```sql
UPDATE bars
SET google_last_fetched_at = NOW()
WHERE bar_id = $1;
```

## Cost Optimization Features

1. **Minimal field selection** - Only requests 6 fields instead of all fields
2. **24-hour caching** - Reduces API calls by up to 95% for popular venues
3. **Darwin geo-fence** - Prevents API calls for out-of-bounds locations
4. **Idempotent caching** - Safe to call repeatedly without cost concern
5. **No automatic refresh** - Cache only refreshes on explicit requests after TTL

## Security Features

1. **Authentication required** - Must provide valid JWT token
2. **Darwin bounds validation** - Rejects requests for non-Darwin locations
3. **RLS policies** - Row-level security on cache table
4. **Server-side API key** - Never exposed to client

## Integration Flow

### Step 1: Link Bar to Google Place
```javascript
// Admin only - links bar to Google Place ID
POST /link-google-place
{ "bar_id": "123..." }
```

### Step 2: Fetch Place Details
```javascript
// Any authenticated user
GET /google-place-details?bar_id=123...
```

### Step 3: Display in App
```javascript
// Use the returned data to enrich venue information
- Show Google rating and review count
- Display photos from Google
- Show opening hours
- Display formatted address
```

## Common Use Cases

### 1. Venue Detail Page
Fetch and display Google rating, reviews, photos, and hours when user views a bar's detail page.

### 2. Map Markers
Enrich map markers with Google ratings to help users choose venues.

### 3. Venue Discovery
Show Google ratings and photo previews in venue lists and search results.

### 4. Opening Hours Check
Display current opening status and weekly hours for each venue.

## Troubleshooting

### "Bar not found" (404)
- Verify the bar_id exists in the database
- Check that you're using the correct UUID format

### "Bar is outside Darwin bounds" (400)
- This bar is not within the Darwin geo-fence
- Only Darwin-area bars are supported

### "needs_linking: true"
- Bar exists but hasn't been linked to a Google Place yet
- Admin must call `/link-google-place` first

### "Google Places API error"
- Check that `GOOGLE_MAPS_SERVER_KEY` is configured
- Verify the API key has Places API enabled
- Check Google Cloud Console for quota/billing issues

## Performance Metrics

### Cache Hit
- Response time: ~50-100ms (database query)
- Cost: $0 (no Google API call)

### Cache Miss
- Response time: ~300-500ms (Google API + database writes)
- Cost: ~$0.017 per request (Place Details - Basic Data)

### Expected Cache Hit Rate
- First request: 0% (always miss)
- 24 hours: ~95% for popular venues
- Cost savings: ~95% reduction in API costs
