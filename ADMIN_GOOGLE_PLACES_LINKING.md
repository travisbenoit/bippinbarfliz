# Admin Google Places Linking Workflow

## Overview

This is the admin interface for linking bars in the database to Google Places API. This prevents unnecessary API crawling by only linking bars that actually exist in our database and fall within the Darwin bounds.

## Access

Navigate to **Settings → Admin → Link Google Places**

Access is restricted to users with the `is_admin` flag set to `true` in the `user_profiles` table.

## Features

### 1. Bar Listing
- Displays all bars that do NOT have a `google_place_id` linked
- Shows bar name and precise coordinates
- Sorted alphabetically by bar name
- Maximum of ~50 bars displayed with scrolling support

### 2. Link Button
Each bar has an individual "Link" button that:
- Sends a request to `/functions/v1/link-google-place`
- Automatically matches the bar to a Google Place
- Updates the database on success
- Shows status: "Linking...", "Linked", "Failed"

### 3. Rate Limiting
- **Server-side**: 10 requests per minute per user (backend rate limit)
- **Client-side**: 2-second delay between individual link requests (UI rate limit)
- Prevents API quota exhaustion and excessive Google Places API usage

### 4. Status Display
After each linking attempt:
- **Successfully linked**: Bar removed from list, success message shown for 3 seconds
- **Already linked**: Shows "Already linked" status
- **Needs review**: Shows "Needs review (X candidates)" if confidence score too low
- **Failed**: Error message displayed with retry option

### 5. Refresh Button
Click "Refresh List" to reload the list of bars needing linking

## Response Statuses

### Successful Match
The endpoint finds a high-confidence Google Place match and links it automatically:
```
Status: "Successfully linked"
- Confidence score ≥ 80%
- Within 150m of bar location
- Name matches at least 80%
```

### Needs Manual Review
The endpoint found candidates but none meet the confidence threshold:
```
Status: "Needs review (3 candidates)"
- Top 3 candidates shown with:
  - Place name
  - Address
  - Distance from bar
  - Match confidence score
```

**Action**: Manually select the correct Google Place in a future version

### Already Linked
The bar is already linked to a Google Place:
```
Status: "Already linked"
- Skipped without API call
- Shows original linking timestamp
```

## How It Works

### Linking Algorithm

1. **Fetch bar location** from database
2. **Check Darwin bounds** - reject if outside bounds
3. **Search Google Places** using:
   - Bar name as query
   - Bar coordinates as location center
   - 300m search radius
   - Australia region filter
4. **Score candidates** by:
   - Name similarity (Levenshtein distance)
   - Distance from bar location
   - Combined confidence score: 70% name + 30% distance
5. **Auto-link if confident** (≥80% match)
6. **Manual review if uncertain** (<80% match)
7. **Update bar record** with `google_place_id` and timestamp

### Database Updates

On successful link:
```sql
UPDATE bars SET
  google_place_id = 'ChIJN1t_tDeuEmsRUsoyG83frY4',
  google_last_linked_at = NOW()
WHERE id = $1;
```

## Security

- **Authentication Required**: Must be logged in
- **Admin Only**: Requires `is_admin = true` in user_profiles
- **Darwin Only**: Links only bars within Darwin bounds
- **Rate Limited**: 10 requests/minute per user
- **Server-Key**: Uses GOOGLE_MAPS_SERVER_KEY (never exposed to client)

## Common Scenarios

### Scenario 1: New bars added to database
1. Run "Refresh List" to load bars without google_place_id
2. Click "Link" on each bar
3. Wait 2 seconds between requests
4. Monitor "Needs review" bars for manual linking

### Scenario 2: Maintenance run
- Run on a schedule (e.g., weekly) to link any newly added bars
- Typical workflow: 5-10 bars × 2 seconds = ~20-30 seconds runtime
- No cost if already linked (cached in google_place_cache)

### Scenario 3: Manual review needed
If a bar shows "Needs review":
1. Check the top 3 candidate names and distances
2. Decide if any is correct
3. (Future) Implement manual override UI to select from candidates

## API Details

### Endpoint
```
POST /functions/v1/link-google-place
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "bar_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Response: Auto-Linked
```json
{
  "bar_id": "550e8400-e29b-41d4-a716-446655440000",
  "google_place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
  "matched_name": "The Deck Bar",
  "distance_m": 45,
  "match_confidence": 0.92
}
```

### Response: Needs Review
```json
{
  "bar_id": "550e8400-e29b-41d4-a716-446655440000",
  "google_place_id": null,
  "needs_manual_review": true,
  "reason": "Best match confidence 0.72 below threshold 0.80",
  "candidates": [
    {
      "place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",
      "name": "The Deck Bar",
      "address": "22 Mitchell St, Darwin...",
      "distance_m": 120,
      "match_confidence": 0.72
    },
    {...},
    {...}
  ]
}
```

### Response: Outside Bounds
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

## Monitoring

### Metrics to Track
- **Total bars**: Count of all bars in database
- **Linked bars**: Count with non-null `google_place_id`
- **Linking percentage**: (linked / total) × 100%
- **Failed links**: Count needing manual review

### Database Query
```sql
SELECT
  COUNT(*) as total,
  COUNT(google_place_id) as linked,
  ROUND(100.0 * COUNT(google_place_id) / COUNT(*), 1) as percent_linked,
  COUNT(CASE WHEN google_place_id IS NULL THEN 1 END) as needs_linking
FROM bars;
```

## Troubleshooting

### "Access Denied - Admin privileges required"
- User is not an admin
- Ask database admin to set `is_admin = true` in user_profiles table

### "Rate limit exceeded. Maximum 10 requests per minute."
- Hit server-side rate limit
- Wait 60 seconds and try again
- Or link fewer bars per minute

### "Bar is outside Darwin bounds"
- Bar coordinates fall outside Darwin geofence
- Only Darwin bars can be linked
- Verify coordinates in database

### "Google Places API error"
- GOOGLE_MAPS_SERVER_KEY not configured in Edge Functions
- Google Maps API not enabled in Google Cloud Console
- API quota exceeded
- Check Supabase Edge Functions logs

### Bar shows "Needs review" repeatedly
- No high-confidence Google Place match found
- Manual review/selection needed
- Check Google Place database for alternate listings
- May need to manually update google_place_id in database

## Future Enhancements

1. **Manual Selection UI**: Allow clicking on candidate names to manually link
2. **Batch Operations**: Link multiple selected bars at once
3. **Conflict Resolution**: Handle multiple bars linking to same place
4. **Logging**: Track all linking attempts and results
5. **Relink**: Allow updating existing links if Google Place changed
6. **Bulk Import**: Load bars from CSV and link in batch

## Cost Optimization

### Current Approach
- Links only database bars (no crawling of all Google Places)
- One request per bar being linked
- Caches results for 24 hours in `google_place_cache`
- Typical cost: ~$0.017 per place linked

### Estimated Budget
For 50 bars: ~$0.85
For 200 bars: ~$3.40
For 1000 bars: ~$17.00

(Assuming Google Places API Standard pricing at ~$0.017/request for Place Details)

## Contact

For issues or questions about the linking workflow, contact the admin team.
