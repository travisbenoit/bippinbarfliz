# Barfliz Read Endpoints - Darwin Only

This document describes the three read-only endpoints for querying Darwin bars and their populations.

## Endpoints Overview

All endpoints are Darwin-only and enforce geographic boundaries.

### 1. `GET /functions/v1/bars-nearby`

Returns bars within a specified radius, sorted by distance with current population counts.

**Query Parameters:**
- `lat` (required) - Query latitude
- `lng` (required) - Query longitude
- `radius_m` (optional) - Search radius in meters (default: 5000, max: 50000)

**Darwin Guard:**
- Returns 400 error if query lat/lng is outside Darwin bounds
- Only returns bars within Darwin boundaries

**Response:**
```json
{
  "bars": [
    {
      "bar_id": "123e4567-e89b-12d3-a456-426614174000",
      "name": "The Darwin Hotel",
      "lat": -12.45,
      "lng": 130.85,
      "city": "Darwin",
      "state": "NT",
      "country": "AU",
      "distance_m": 250,
      "population_count": 12
    },
    {
      "bar_id": "123e4567-e89b-12d3-a456-426614174001",
      "name": "Mitchell Street Bar",
      "lat": -12.46,
      "lng": 130.84,
      "city": "Darwin",
      "state": "NT",
      "country": "AU",
      "distance_m": 450,
      "population_count": 8
    }
  ]
}
```

**Example Request:**
```bash
curl "https://[project].supabase.co/functions/v1/bars-nearby?lat=-12.45&lng=130.85&radius_m=2000"
```

**SQL Query Used:**
```sql
-- Get all bars
SELECT bar_id, name, lat, lng, city, state, country
FROM bars;

-- Count population for each bar (active sessions only)
SELECT bar_id, COUNT(*) as population
FROM venue_sessions
WHERE bar_id IN (...)
  AND status = 'open'
  AND last_event_at > NOW() - INTERVAL '25 minutes'
GROUP BY bar_id;
```

**Flutter Usage:**
```dart
final response = await http.get(
  Uri.parse('${supabaseUrl}/functions/v1/bars-nearby?lat=$lat&lng=$lng&radius_m=5000')
);
final data = jsonDecode(response.body);
final bars = data['bars'] as List;
```

---

### 2. `GET /functions/v1/bar-people`

Returns visible users currently at a specific bar, respecting ghost mode privacy.

**Query Parameters:**
- `bar_id` (required) - UUID of the bar

**Privacy Behavior:**
- Ghost mode users (`ghost_mode = true`) count in `total_population` but are NOT shown in `visible_users`
- Regular users (`ghost_mode = false`) appear in `visible_users` list
- Returns `ghost_count` showing how many users are hidden

**Response:**
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "total_population": 12,
  "ghost_count": 3,
  "visible_users": [
    {
      "user_id": "user-uuid-1",
      "name": "Sarah",
      "avatar_url": "https://...",
      "bio": "Love craft cocktails",
      "vibe_tags": ["Happy Hour", "Dance Party"],
      "favorite_drinks": ["Margarita", "Old Fashioned"],
      "tonight_status": "out_now",
      "checked_in_at": "2026-02-14T12:30:00Z",
      "last_seen_at": "2026-02-14T12:45:00Z",
      "dwell_minutes": 15,
      "confidence": 2.5
    },
    {
      "user_id": "user-uuid-2",
      "name": "Mike",
      "avatar_url": "https://...",
      "bio": "Always up for meeting new people",
      "vibe_tags": ["Chill Night"],
      "favorite_drinks": ["Beer", "Whiskey"],
      "tonight_status": "out_now",
      "checked_in_at": "2026-02-14T12:25:00Z",
      "last_seen_at": "2026-02-14T12:44:00Z",
      "dwell_minutes": 19,
      "confidence": 3.0
    }
  ]
}
```

**Example Request:**
```bash
curl "https://[project].supabase.co/functions/v1/bar-people?bar_id=123e4567-e89b-12d3-a456-426614174000"
```

**SQL Query Used:**
```sql
-- Get all active sessions at the bar
SELECT user_id, start_at, last_event_at, confidence
FROM venue_sessions
WHERE bar_id = $1
  AND status = 'open'
  AND last_event_at > NOW() - INTERVAL '25 minutes';

-- Get user details (excluding ghost mode users from results)
SELECT id, name, avatar_url, bio, vibe_tags, favorite_drinks, tonight_status, ghost_mode
FROM users
WHERE id IN (...);

-- Filter: only return users where ghost_mode = false
```

**Flutter Usage:**
```dart
final response = await http.get(
  Uri.parse('${supabaseUrl}/functions/v1/bar-people?bar_id=$barId')
);
final data = jsonDecode(response.body);
final totalPop = data['total_population'];
final visibleUsers = data['visible_users'] as List;
final ghostCount = data['ghost_count'];
```

---

### 3. `GET /functions/v1/bar-detail`

Returns canonical bar information from the `bars` table.

**Query Parameters:**
- `bar_id` (required) - UUID of the bar

**Response:**
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "The Darwin Hotel",
  "lat": -12.45,
  "lng": 130.85,
  "city": "Darwin",
  "state": "NT",
  "country": "AU",
  "radar_place_id": "radar_place_xyz789",
  "google_place_id": "ChIJ...",
  "created_at": "2026-02-10T10:00:00Z",
  "updated_at": "2026-02-14T08:00:00Z",
  "current_population": 12
}
```

**Example Request:**
```bash
curl "https://[project].supabase.co/functions/v1/bar-detail?bar_id=123e4567-e89b-12d3-a456-426614174000"
```

**SQL Query Used:**
```sql
-- Get bar details
SELECT *
FROM bars
WHERE bar_id = $1;

-- Get current population count
SELECT COUNT(*) as population
FROM venue_sessions
WHERE bar_id = $1
  AND status = 'open'
  AND last_event_at > NOW() - INTERVAL '25 minutes';
```

**Flutter Usage:**
```dart
final response = await http.get(
  Uri.parse('${supabaseUrl}/functions/v1/bar-detail?bar_id=$barId')
);
final bar = jsonDecode(response.body);
print('${bar['name']} has ${bar['current_population']} people');
```

---

## Ghost Mode Privacy

### Database Schema

```sql
-- Added to users table
ALTER TABLE users ADD COLUMN ghost_mode boolean DEFAULT false;
CREATE INDEX idx_users_ghost_mode ON users(ghost_mode);
```

### Privacy Rules

1. **Ghost mode users (`ghost_mode = true`):**
   - Count in `bars-nearby` population_count
   - Count in `bar-people` total_population
   - DO NOT appear in `bar-people` visible_users array
   - Shown in ghost_count field

2. **Regular users (`ghost_mode = false`):**
   - Count in all population metrics
   - Appear in visible_users list with full profile data

### Setting Ghost Mode

```sql
-- Enable ghost mode for a user
UPDATE users SET ghost_mode = true WHERE id = 'user-uuid';

-- Disable ghost mode
UPDATE users SET ghost_mode = false WHERE id = 'user-uuid';
```

---

## Required Indexes

All necessary indexes are already created:

```sql
-- On bars table
CREATE INDEX idx_bars_radar_place_id ON bars(radar_place_id);
CREATE INDEX idx_bars_location ON bars(lat, lng);

-- On venue_sessions table
CREATE INDEX idx_venue_sessions_bar_status ON venue_sessions(bar_id, status);
CREATE INDEX idx_venue_sessions_user_status ON venue_sessions(user_id, status);
CREATE INDEX idx_venue_sessions_bar_last_event ON venue_sessions(bar_id, last_event_at DESC);

-- On users table
CREATE INDEX idx_users_ghost_mode ON users(ghost_mode);
```

---

## Population Counting Logic

All endpoints use consistent logic for counting active users:

```sql
-- Active session criteria:
-- 1. status = 'open'
-- 2. last_event_at within last 25 minutes
-- 3. bar_id matches target bar

SELECT COUNT(*) FROM venue_sessions
WHERE bar_id = $1
  AND status = 'open'
  AND last_event_at > NOW() - INTERVAL '25 minutes';
```

This ensures:
- Stale sessions (>25 min inactive) don't count
- Closed sessions don't count
- Real-time accurate population numbers

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Missing required parameters: lat, lng"
}
```

```json
{
  "error": "Location outside Darwin bounds",
  "darwin_bounds": {
    "north": -12.35,
    "south": -12.55,
    "west": 130.75,
    "east": 131.05
  }
}
```

### 404 Not Found
```json
{
  "error": "Bar not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "Detailed error message"
}
```

---

## Testing

### Test bars-nearby
```bash
# Inside Darwin bounds (should work)
curl "https://[project].supabase.co/functions/v1/bars-nearby?lat=-12.45&lng=130.85&radius_m=5000"

# Outside Darwin bounds (should return 400)
curl "https://[project].supabase.co/functions/v1/bars-nearby?lat=-33.8688&lng=151.2093&radius_m=5000"
```

### Test bar-people
```bash
curl "https://[project].supabase.co/functions/v1/bar-people?bar_id=YOUR_BAR_ID"
```

### Test bar-detail
```bash
curl "https://[project].supabase.co/functions/v1/bar-detail?bar_id=YOUR_BAR_ID"
```

---

## Integration with Flutter

### Complete Example

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BarflizApi {
  final String supabaseUrl;

  BarflizApi(this.supabaseUrl);

  Future<List<Bar>> getNearbyBars(double lat, double lng, {int radiusM = 5000}) async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/functions/v1/bars-nearby?lat=$lat&lng=$lng&radius_m=$radiusM')
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['bars'] as List).map((b) => Bar.fromJson(b)).toList();
    } else {
      throw Exception('Failed to load nearby bars');
    }
  }

  Future<BarPeople> getBarPeople(String barId) async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/functions/v1/bar-people?bar_id=$barId')
    );

    if (response.statusCode == 200) {
      return BarPeople.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load bar people');
    }
  }

  Future<BarDetail> getBarDetail(String barId) async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/functions/v1/bar-detail?bar_id=$barId')
    );

    if (response.statusCode == 200) {
      return BarDetail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load bar detail');
    }
  }
}
```

---

## Performance Notes

1. **Caching Strategy:**
   - `bars-nearby`: Cache for 30-60 seconds
   - `bar-people`: Cache for 10-15 seconds
   - `bar-detail`: Cache for 60 seconds

2. **Rate Limiting:**
   - Consider implementing client-side throttling
   - Don't poll more frequently than every 10 seconds

3. **Optimization:**
   - All queries use indexed fields
   - Population counts are fast (indexed on bar_id + status)
   - Ghost mode filtering happens in-memory (small dataset)

---

## Next Steps

1. Add bars to the `bars` table for Darwin venues
2. Test endpoints with real bar data
3. Implement Flutter UI to display nearby bars and populations
4. Add real-time subscriptions if needed (using Supabase Realtime)
