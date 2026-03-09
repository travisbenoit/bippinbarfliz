# Link Google Place API

## Endpoint
```
POST /functions/v1/link-google-place
```

## Purpose
Links bars to their corresponding Google Place IDs with minimal API usage. Darwin-only, admin-restricted, with rate limiting.

## Environment Variables Required
- `GOOGLE_MAPS_SERVER_KEY` - Set in Supabase Project Settings → Edge Functions → Environment Variables

## Access Control
- **Admin only** - Requires `user_profiles.is_admin = true`
- **Rate limit** - 10 requests per minute per user

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
Content-Type: application/json
```

### Body
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

## Behavior

1. **Fetch bar** - Returns 404 if not found
2. **Darwin guard** - Returns 400 if bar is outside Darwin bounds (does NOT call Google)
3. **Check existing link** - If `google_place_id` already set, returns it immediately
4. **Google Places Search** - Searches for best match near bar location
5. **Candidate filtering**:
   - Keep only candidates within 150 meters
   - Keep only candidates inside Darwin bounds
   - Sort by match confidence (name similarity 70% + distance 30%)
6. **Auto-link** - If confidence ≥ 0.80, updates database automatically
7. **Manual review** - If confidence < 0.80, returns top 3 candidates for review

## Response Examples

### Success - High Confidence Match (≥0.80)
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "google_place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "matched_name": "The Deck Bar",
  "distance_m": 12,
  "match_confidence": 0.94
}
```

### Success - Already Linked
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "google_place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "already_linked": true,
  "linked_at": "2026-02-15T10:30:00.000Z"
}
```

### Needs Manual Review - Low Confidence
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "google_place_id": null,
  "needs_manual_review": true,
  "reason": "Best match confidence 0.75 below threshold 0.80",
  "candidates": [
    {
      "place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
      "name": "The Deck Bar & Grill",
      "address": "22 Mitchell St, Darwin City NT 0800, Australia",
      "distance_m": 8,
      "match_confidence": 0.75
    },
    {
      "place_id": "ChIJXYZ123ABC456DEF789GHI",
      "name": "Deck Bar Darwin",
      "address": "24 Mitchell St, Darwin City NT 0800, Australia",
      "distance_m": 45,
      "match_confidence": 0.68
    },
    {
      "place_id": "ChIJABC789XYZ123",
      "name": "The Darwin Deck",
      "address": "18 Mitchell St, Darwin City NT 0800, Australia",
      "distance_m": 102,
      "match_confidence": 0.62
    }
  ]
}
```

### Needs Manual Review - No Candidates Found
```json
{
  "bar_id": "123e4567-e89b-12d3-a456-426614174000",
  "google_place_id": null,
  "needs_manual_review": true,
  "reason": "No candidates found within 150m in Darwin bounds",
  "candidates": []
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

### Error - Not Admin
**Status:** 403
```json
{
  "error": "Admin access required"
}
```

### Error - Rate Limit Exceeded
**Status:** 429
```json
{
  "error": "Rate limit exceeded. Maximum 10 requests per minute."
}
```

### Error - Unauthorized
**Status:** 401
```json
{
  "error": "Unauthorized"
}
```

## Example Usage (JavaScript)

```javascript
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const { data: { session } } = await supabase.auth.getSession();

const response = await fetch(`${supabaseUrl}/functions/v1/link-google-place`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${session.access_token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    bar_id: '123e4567-e89b-12d3-a456-426614174000'
  })
});

const result = await response.json();

if (result.needs_manual_review) {
  console.log('Manual review required:', result.reason);
  console.log('Candidates:', result.candidates);
} else if (result.already_linked) {
  console.log('Already linked:', result.google_place_id);
} else {
  console.log('Successfully linked:', result.google_place_id);
  console.log('Match confidence:', result.match_confidence);
}
```

## Match Confidence Algorithm

Match confidence is calculated as:
```
match_confidence = (name_similarity × 0.7) + (distance_score × 0.3)

where:
  name_similarity = 1.0 - (levenshtein_distance / max_length)
  distance_score = max(0, 1.0 - (distance_meters / 150))
```

## Security Features

1. **Admin-only access** - Prevents regular users from spamming the endpoint
2. **Rate limiting** - 10 requests per minute per user (in-memory)
3. **Darwin geo-fence** - No Google API calls for locations outside Darwin
4. **Idempotent** - Returns existing link if already set
5. **Server-side API key** - Never exposed to client

## Cost Optimization

- Only calls Google API if bar is in Darwin bounds
- Returns cached result if already linked
- Uses Text Search API (not Places API Autocomplete)
- Minimal fields returned to reduce cost
- Rate limiting prevents abuse

## Database Updates

When confidence ≥ 0.80, updates:
```sql
UPDATE bars SET
  google_place_id = 'ChIJ...',
  google_last_linked_at = NOW()
WHERE id = 'bar_id';
```
