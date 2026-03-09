# Google Place Photo API

## Endpoint
```
GET /functions/v1/google-place-photo?bar_id=<uuid>&photo_ref=<reference>&max_width=<pixels>
```

## Purpose
Streams Google Places photos directly from the Google Places Photo API with built-in rate limiting, caching headers, and Darwin bounds validation.

## Environment Variables Required
- `GOOGLE_MAPS_SERVER_KEY` - Set in Supabase Project Settings → Edge Functions → Environment Variables

## Request

### Headers
```
Authorization: Bearer <user_jwt_token>
```

### Query Parameters
- `bar_id` (required) - UUID of the bar
- `photo_ref` (required) - Photo reference from `GET /google-place-details` response
- `max_width` (optional) - Image width in pixels, defaults to 400, max 1600

### Example Request
```bash
curl "https://your-project.supabase.co/functions/v1/google-place-photo?bar_id=123e4567-e89b-12d3-a456-426614174000&photo_ref=CmRaAAAA...&max_width=800" \
  -H "Authorization: Bearer <token>" \
  -o photo.jpg
```

## Behavior

1. **Check rate limit** - Per-IP limit of 60 requests/minute
2. **Validate authentication** - Requires valid JWT token
3. **Fetch bar** - Returns 404 if bar not found
4. **Validate Darwin bounds** - Returns 400 if bar outside Darwin bounds
5. **Fetch from Google** - Calls Google Places Photo API with specified dimensions
6. **Stream image** - Returns image bytes with proper MIME type
7. **Add cache headers** - Sets 24-hour immutable cache for browser caching

## Rate Limiting

- **Limit**: 60 requests per minute per IP address
- **Response**: 429 Too Many Requests when exceeded
- **Retry-After**: 60 seconds

The rate limiter is IP-based using `x-forwarded-for` or `cf-connecting-ip` headers.

## Image Size Options

The `max_width` parameter controls the image dimensions:
- **Minimum**: 100 pixels
- **Maximum**: 1600 pixels
- **Default**: 400 pixels
- **Note**: Google API returns images with aspect ratio preserved

Common sizes:
- `max_width=200` - Thumbnails (list views)
- `max_width=400` - Default (card views)
- `max_width=800` - Detail views
- `max_width=1200` - Full-screen detail

## Response

### Success (200)
```
Content-Type: image/jpeg
Cache-Control: public, max-age=86400, immutable
ETag: "<bar_id>-<photo_ref>-<max_width>"

[JPEG image bytes]
```

### Caching Headers Explained
- **Cache-Control**: Browser caches for 24 hours
- **immutable**: Tells browser the image will never change
- **ETag**: Allows efficient cache validation on server

### Errors (JSON Responses)

#### Missing Parameters (400)
```json
{
  "error": "Missing bar_id query parameter"
}
```

#### Bar Not Found (404)
```json
{
  "error": "Bar not found"
}
```

#### Outside Darwin Bounds (400)
```json
{
  "error": "Bar is outside Darwin bounds"
}
```

#### Rate Limited (429)
```json
{
  "error": "Rate limit exceeded"
}
```

#### Unauthorized (401)
```json
{
  "error": "Unauthorized"
}
```

#### Invalid max_width (400)
```json
{
  "error": "Invalid max_width. Must be between 100 and 1600"
}
```

## Integration with google-place-details

The photo references come from the `GET /google-place-details` endpoint:

```bash
# Step 1: Get place details (includes photo references)
curl "https://your-project.supabase.co/functions/v1/google-place-details?bar_id=123..." \
  -H "Authorization: Bearer <token>"

# Response includes:
# {
#   ...
#   "photos": ["CmRaAAAA...", "CmRaAAAA...", ...]
# }

# Step 2: Use a photo reference to fetch the image
curl "https://your-project.supabase.co/functions/v1/google-place-photo?bar_id=123...&photo_ref=CmRaAAAA...&max_width=800" \
  -H "Authorization: Bearer <token>" \
  -o venue.jpg
```

## Flutter Integration

### Direct Image.network() with JWT

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class VenuePhotoWidget extends StatefulWidget {
  final String barId;
  final String photoRef;

  const VenuePhotoWidget({
    required this.barId,
    required this.photoRef,
  });

  @override
  State<VenuePhotoWidget> createState() => _VenuePhotoWidgetState();
}

class _VenuePhotoWidgetState extends State<VenuePhotoWidget> {
  late String _photoUrl;

  @override
  void initState() {
    super.initState();
    _buildPhotoUrl();
  }

  void _buildPhotoUrl() {
    final supabaseUrl = Supabase.instance.client.supabaseUrl;
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';

    _photoUrl = '$supabaseUrl/functions/v1/google-place-photo'
        '?bar_id=${widget.barId}'
        '&photo_ref=${Uri.encodeComponent(widget.photoRef)}'
        '&max_width=800';
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return Image.network(
      _photoUrl,
      headers: {
        'Authorization': 'Bearer ${session?.accessToken ?? ''}',
      },
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[300],
          child: const CircularProgressIndicator(),
        );
      },
    );
  }
}

// Usage in a list or grid
ListView.builder(
  itemCount: photos.length,
  itemBuilder: (context, index) {
    return VenuePhotoWidget(
      barId: venue.id,
      photoRef: photos[index],
    );
  },
)
```

### Alternative: Download & Cache Locally

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CachedVenuePhoto extends StatefulWidget {
  final String barId;
  final String photoRef;
  final double maxWidth;

  const CachedVenuePhoto({
    required this.barId,
    required this.photoRef,
    this.maxWidth = 800,
  });

  @override
  State<CachedVenuePhoto> createState() => _CachedVenuePhotoState();
}

class _CachedVenuePhotoState extends State<CachedVenuePhoto> {
  late Future<File> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = _fetchAndCachePhoto();
  }

  Future<File> _fetchAndCachePhoto() async {
    final supabaseUrl = Supabase.instance.client.supabaseUrl;
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';

    final photoUrl = '$supabaseUrl/functions/v1/google-place-photo'
        '?bar_id=${widget.barId}'
        '&photo_ref=${Uri.encodeComponent(widget.photoRef)}'
        '&max_width=${widget.maxWidth.toInt()}';

    final cacheManager = DefaultCacheManager();
    return await cacheManager.getSingleFile(
      photoUrl,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _photoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          }
        }

        return Container(
          color: Colors.grey[300],
          child: const CircularProgressIndicator(),
        );
      },
    );
  }
}

// Usage
CachedVenuePhoto(
  barId: venue.id,
  photoRef: photos[0],
  maxWidth: 1200,
)
```

### Photo Gallery Component

```dart
class VenuePhotoGallery extends StatefulWidget {
  final String barId;
  final List<String> photoRefs;

  const VenuePhotoGallery({
    required this.barId,
    required this.photoRefs,
  });

  @override
  State<VenuePhotoGallery> createState() => _VenuePhotoGalleryState();
}

class _VenuePhotoGalleryState extends State<VenuePhotoGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _buildPhotoUrl(String photoRef, {int maxWidth = 800}) {
    final supabaseUrl = Supabase.instance.client.supabaseUrl;
    return '$supabaseUrl/functions/v1/google-place-photo'
        '?bar_id=${widget.barId}'
        '&photo_ref=${Uri.encodeComponent(photoRef)}'
        '&max_width=$maxWidth';
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';

    if (widget.photoRefs.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemCount: widget.photoRefs.length,
          itemBuilder: (context, index) {
            return Image.network(
              _buildPhotoUrl(widget.photoRefs[index], maxWidth: 1200),
              headers: {'Authorization': 'Bearer $token'},
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
            );
          },
        ),
        // Photo counter
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1}/${widget.photoRefs.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Usage
VenuePhotoGallery(
  barId: venue.id,
  photoRefs: placeDetails.photos,
)
```

## Performance Optimization

### Browser Caching
Images are cached for 24 hours with `immutable` flag, so repeated requests from the same URL are served from browser cache without server request.

### ETag Validation
Even if cache expires, the ETag allows efficient validation without re-downloading the image.

### Rate Limiting
Per-IP rate limiting prevents abuse while allowing reasonable usage:
- 60 requests/minute = 3,600 requests/hour
- Sufficient for most use cases
- Exceeding returns 429 with Retry-After header

### Recommended Widths
- **Thumbnails (list)**: 200px - ~5-10 KB
- **Cards (discovery)**: 400px - ~20-30 KB
- **Details (full page)**: 800px - ~50-80 KB
- **Full screen (zoom)**: 1200px - ~100-150 KB

## Common Patterns

### Carousel/Slider
```dart
// Use PhotoGallery component above with PageView
// Lazy load photos as user swipes
```

### Thumbnail Grid
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
  ),
  itemBuilder: (context, index) {
    return VenuePhotoWidget(
      barId: barId,
      photoRef: photos[index],
    );
  },
)
```

### Hero Animation
```dart
GestureDetector(
  onTap: () {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Hero(
          tag: 'photo_${barId}_$index',
          child: VenuePhotoWidget(
            barId: barId,
            photoRef: photoRef,
          ),
        ),
      ),
    ));
  },
  child: Hero(
    tag: 'photo_${barId}_$index',
    child: VenuePhotoWidget(
      barId: barId,
      photoRef: photoRef,
    ),
  ),
)
```

## Troubleshooting

### "Bar not found" (404)
- Verify `bar_id` is correct and exists
- Check UUID format is valid

### "Bar is outside Darwin bounds" (400)
- Photo API only works for Darwin venues
- Confirm bar location is within bounds

### "Rate limit exceeded" (429)
- Wait 60 seconds before retrying
- Check for excessive concurrent requests
- Consider local caching to reduce API calls

### "Invalid max_width" (400)
- Must be between 100-1600 pixels
- Check parameter format is numeric

### Image loads slowly
- First load always fetches from Google API (~500ms)
- Subsequent loads use browser cache (~1-10ms)
- Use thumbnail size (200px) for lists, larger for details

## Security

- **Authentication Required**: All requests must include valid JWT
- **Authorization**: Only authenticated users can access
- **Rate Limiting**: Per-IP to prevent abuse
- **Darwin-Only**: Geofence prevents external usage
- **Server-Side Key**: API key never exposed to client
