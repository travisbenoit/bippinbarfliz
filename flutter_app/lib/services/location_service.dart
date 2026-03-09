import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'supabase_service.dart';

class LocationService {
  final SupabaseService _supabase;

  LocationService(this._supabase);

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserLocation() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;

      final position = await getCurrentLocation();
      if (position == null) return;

      await _supabase.client.from('users').update({
        'last_known_lat': position.latitude,
        'last_known_lng': position.longitude,
        'last_active_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      return;
    }
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
