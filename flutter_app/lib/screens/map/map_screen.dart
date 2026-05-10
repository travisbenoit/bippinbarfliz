import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../extensions/localization_extension.dart';
import '../../models/venue.dart';
import '../../services/analytics_service.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../widgets/app_loader.dart';

const _approvedCities = ['Darwin', 'Miami', 'Fort Lauderdale'];

final venuesMapProvider = FutureProvider<List<Venue>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('venues')
      .select('id, name, address, lat, lng, rating, user_ratings_total, photo_url, google_place_id, created_at, city, category, type')
      .inFilter('city', _approvedCities)
      .eq('is_active', true)
      .order('name')
      .limit(500);

  return (response as List).map((json) => Venue.fromJson(json)).toList();
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _loadingMarkers = false; // guard against concurrent calls
  String? _error;

  // Cached per-city pin bitmaps — only built once per city
  final Map<String, BitmapDescriptor> _pinCache = {};

  Future<BitmapDescriptor> _buildPinIcon(String? city) async {
    final key = city ?? 'default';
    if (_pinCache.containsKey(key)) return _pinCache[key]!;

    final emoji = switch (city) {
      'Darwin'          => '🦘',
      'Miami'           => '🌴',
      'Fort Lauderdale' => '⛵',
      _                 => '🍸',
    };

    // Draw at 2× so pins look sharp on Retina/high-DPI screens.
    const double scale = 2.0;
    const double lw = 48.0;  // logical width  (points)
    const double lh = 68.0;  // logical height (points)
    const double pw = lw * scale;
    const double ph = lh * scale;
    const double cr = 18.0 * scale;   // circle radius
    const double cx = pw / 2;
    const double cy = cr + 5.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, pw, ph));

    // Drop shadow behind circle
    canvas.drawCircle(
      const Offset(cx, cy + 3.0 * scale),
      cr,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.0 * scale),
    );

    // Teardrop pointer — drawn first so circle overlaps its top edge cleanly
    final pink = Paint()..color = const Color(0xFFE91E63);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 10.0 * scale, cy + cr * 0.55)
        ..lineTo(cx + 10.0 * scale, cy + cr * 0.55)
        ..lineTo(cx, ph - 3.0 * scale)
        ..close(),
      pink,
    );

    // Circle body
    canvas.drawCircle(const Offset(cx, cy), cr, pink);

    // White ring border
    canvas.drawCircle(
      const Offset(cx, cy),
      cr - 1.5 * scale,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale,
    );

    // City emoji centred in circle
    final tp = TextPainter(textDirection: ui.TextDirection.ltr)
      ..text = TextSpan(text: emoji, style: const TextStyle(fontSize: 22.0 * scale))
      ..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(pw.toInt(), ph.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(bytes, width: lw, height: lh);
    _pinCache[key] = descriptor;
    return descriptor;
  }

  static const CameraPosition _darwinCenter = CameraPosition(
    target: LatLng(-12.4634, 130.8456),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[MapScreen] Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted || _mapController == null) return;

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[MapScreen] Error getting location: $e');
      debugPrint('[MapScreen] $stackTrace');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_controller.isCompleted) _controller.complete(controller);
    _loadVenueMarkers();
  }

  Future<void> _loadVenueMarkers({bool invalidate = false}) async {
    if (_loadingMarkers || !mounted) return;
    _loadingMarkers = true;
    setState(() => _isLoading = true);

    try {
      if (invalidate) ref.invalidate(venuesMapProvider);
      final venues = await ref.read(venuesMapProvider.future);
      if (!mounted) return;

      // Build icons per city (cached — only 3 bitmaps created total)
      final markers = await Future.wait(venues.map((venue) async {
        final icon = await _buildPinIcon(venue.city);
        return Marker(
          markerId: MarkerId(venue.id),
          position: LatLng(venue.lat, venue.lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: venue.name,
            snippet: venue.address,
          ),
          onTap: () => _showVenueDetails(venue),
        );
      }));

      if (!mounted) return;
      // Assign a new Set — never mutate in place to avoid accumulation bugs
      setState(() {
        _markers = Set<Marker>.from(markers);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e, stackTrace: stackTrace, tag: 'MapScreen.loadVenues');
        _isLoading = false;
      });
    } finally {
      _loadingMarkers = false;
    }
  }

  void _showVenueDetails(Venue venue) {
    AnalyticsService.instance.venueViewed(venueId: venue.id, venueName: venue.name);
    _showVenueBottomSheet(venue);
  }

  void _showVenueBottomSheet(Venue venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _VenueBottomSheet(
        venue: venue,
        onClose: () => Navigator.pop(context),
        onNavigate: () async {
          Navigator.pop(context);
          final uri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&destination=${venue.lat},${venue.lng}'
            '&destination_place_id=${venue.placeId ?? ""}'
            '&travelmode=walking',
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t(AppStrings.mapTitle)),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadVenueMarkers(invalidate: true),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _darwinCenter,
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            style: _mapStyle,
          ),
          if (_isLoading)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppButtonLoader(size: 16),
                      const SizedBox(width: 8),
                      Text(t(AppStrings.mapLoadingVenues)),
                    ],
                  ),
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_bar, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_markers.length} ${t(AppStrings.mapVenuesNearby)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          t(AppStrings.mapTapMarker),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Darwin · Miami · Fort Lauderdale',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const String _mapStyle = '''
[
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  }
]
''';
}

class _VenueBottomSheet extends StatelessWidget {
  final Venue venue;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  const _VenueBottomSheet({
    required this.venue,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (venue.category != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                venue.category!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE91E63),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (venue.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 18, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              venue.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (venue.address.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venue.address,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.directions),
                        label: Text(context.tr(AppStrings.mapDirections)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE91E63),
                          side: const BorderSide(color: Color(0xFFE91E63)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.login),
                        label: Text(context.tr(AppStrings.mapCheckInVenue)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
