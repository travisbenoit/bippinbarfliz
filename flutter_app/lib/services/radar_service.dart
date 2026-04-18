import 'dart:async';
import 'package:flutter_radar/flutter_radar.dart';
import 'package:geolocator/geolocator.dart';

class RadarService {
  static const String _publishableKey = String.fromEnvironment(
    'RADAR_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const DarwinBounds darwinBounds = DarwinBounds(
    north: -12.35,
    south: -12.55,
    west: 130.75,
    east: 131.05,
  );

  bool _isInitialized = false;
  bool _isTracking = false;
  String? _currentUserId;

  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Radar.initialize(_publishableKey);
      _isInitialized = true;
      print('✅ Radar SDK initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Radar SDK: $e');
      rethrow;
    }
  }

  Future<void> setUserId(String userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Radar.setUserId(userId);
      _currentUserId = userId;
      print('✅ Radar user ID set to: $userId');
    } catch (e) {
      print('❌ Failed to set Radar user ID: $e');
      rethrow;
    }
  }

  Future<bool> checkLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        return false;
      }

      if (permission == LocationPermission.denied) {
        print('❌ Location permissions denied');
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking location permissions: $e');
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Error getting current position: $e');
      return null;
    }
  }

  Future<bool> isInDarwinBounds() async {
    final position = await getCurrentPosition();
    if (position == null) return false;

    return darwinBounds.contains(position.latitude, position.longitude);
  }

  Future<LocationCheckResult> checkDarwinLocation() async {
    final position = await getCurrentPosition();

    if (position == null) {
      return LocationCheckResult(
        isInBounds: false,
        errorMessage:
            'Unable to determine location. Please enable location services.',
      );
    }

    final inBounds =
        darwinBounds.contains(position.latitude, position.longitude);

    if (!inBounds) {
      return LocationCheckResult(
        isInBounds: false,
        latitude: position.latitude,
        longitude: position.longitude,
        errorMessage: 'Barfliz is in Darwin only during beta.',
      );
    }

    return LocationCheckResult(
      isInBounds: true,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<bool> startTracking({String? userId}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (userId != null && userId != _currentUserId) {
      await setUserId(userId);
    }

    final hasPermission = await checkLocationPermissions();
    if (!hasPermission) {
      print('❌ Cannot start tracking: missing location permissions');
      return false;
    }

    final locationCheck = await checkDarwinLocation();
    if (!locationCheck.isInBounds) {
      print('❌ Cannot start tracking: ${locationCheck.errorMessage}');
      return false;
    }

    try {
      final options = <String, dynamic>{
        'desiredStoppedUpdateInterval': 180,
        'desiredMovingUpdateInterval': 60,
        'desiredSyncInterval': 50,
        'desiredAccuracy': 'high',
        'stopDuration': 140,
        'stopDistance': 70,
        'sync': 'all',
        'replay': 'stops',
        'showBlueBar': false,
        'useStoppedGeofence': true,
        'stoppedGeofenceRadius': 100,
        'useMovingGeofence': true,
        'movingGeofenceRadius': 100,
        'syncGeofences': true,
        'syncGeofencesLimit': 10,
        'beacons': false,
        'foregroundServiceEnabled': true,
      };

      await Radar.startTrackingCustom(options);

      _isTracking = true;
      print('✅ Radar tracking started successfully');
      return true;
    } catch (e) {
      print('❌ Failed to start Radar tracking: $e');
      return false;
    }
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      await Radar.stopTracking();
      _isTracking = false;
      print('⏹️ Radar tracking stopped');
    } catch (e) {
      print('❌ Failed to stop Radar tracking: $e');
    }
  }

  Future<Map<String, dynamic>?> getLocation() async {
    try {
      final result = await Radar.getLocation('high');
      return result?['location'] as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Failed to get Radar location: $e');
      return null;
    }
  }

  Future<void> trackOnce() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await Radar.trackOnce();
      print('✅ Radar trackOnce completed');
    } catch (e) {
      print('❌ Failed to track once: $e');
    }
  }

  Future<Map<String, dynamic>?> getTrackingOptions() async {
    try {
      return await Radar.getTrackingOptions() as Map<String, dynamic>?;
    } catch (e) {
      print('❌ Failed to get tracking options: $e');
      return null;
    }
  }

  Future<bool> isTrackingRemote() async {
    try {
      return await Radar.isTracking() ?? false;
    } catch (e) {
      print('❌ Failed to check tracking status: $e');
      return false;
    }
  }

  void dispose() {
    if (_isTracking) {
      stopTracking();
    }
  }
}

class DarwinBounds {
  final double north;
  final double south;
  final double west;
  final double east;

  const DarwinBounds({
    required this.north,
    required this.south,
    required this.west,
    required this.east,
  });

  bool contains(double latitude, double longitude) {
    return latitude >= south &&
        latitude <= north &&
        longitude >= west &&
        longitude <= east;
  }

  Map<String, double> toJson() {
    return {
      'north': north,
      'south': south,
      'west': west,
      'east': east,
    };
  }
}

class LocationCheckResult {
  final bool isInBounds;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  LocationCheckResult({
    required this.isInBounds,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });
}
