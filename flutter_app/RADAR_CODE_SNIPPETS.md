# Radar Flutter Code Snippets - Quick Reference

Essential code snippets for Radar integration in Flutter.

---

## 1. Initialize Radar

```dart
import 'package:flutter_radar/flutter_radar.dart';

await Radar.initialize('prj_test_pk_xxxxx');
```

---

## 2. Set User ID (Bolt Auth User ID)

```dart
final userId = supabase.auth.currentUser?.id;
if (userId != null) {
  await Radar.setUserId(userId);
}
```

---

## 3. Start Tracking with Background Detection

```dart
await Radar.startTracking(RadarTrackingOptions(
  desiredStoppedUpdateInterval: 180,
  desiredMovingUpdateInterval: 60,
  desiredSyncInterval: 50,
  desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
  stopDuration: 140,
  stopDistance: 70,
  sync: RadarTrackingOptionsSync.all,
  replay: RadarTrackingOptionsReplay.stops,
  showBlueBar: false,
  useStoppedGeofence: true,
  stoppedGeofenceRadius: 100,
  useMovingGeofence: true,
  movingGeofenceRadius: 100,
  syncGeofences: true,
  syncGeofencesLimit: 10,
  beacons: false,
  foregroundServiceEnabled: true,
));
```

---

## 4. Stop Tracking

```dart
await Radar.stopTracking();
```

---

## 5. Check Location Permissions

```dart
import 'package:geolocator/geolocator.dart';

Future<bool> checkPermissions() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  return permission != LocationPermission.denied &&
         permission != LocationPermission.deniedForever;
}
```

---

## 6. Request iOS Background Location Permission

```dart
import 'package:permission_handler/permission_handler.dart';

final status = await Permission.locationAlways.request();
```

---

## 7. Request Android Background Location Permission (Android 10+)

```dart
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<bool> requestBackgroundLocation() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 29) {
      return (await Permission.locationAlways.request()).isGranted;
    }
  }
  return true;
}
```

---

## 8. Check Darwin Bounds

```dart
class DarwinBounds {
  static const double north = -12.35;
  static const double south = -12.55;
  static const double west = 130.75;
  static const double east = 131.05;

  static bool contains(double lat, double lng) {
    return lat >= south && lat <= north &&
           lng >= west && lng <= east;
  }
}

// Usage
final position = await Geolocator.getCurrentPosition();
final isInDarwin = DarwinBounds.contains(
  position.latitude,
  position.longitude,
);

if (!isInDarwin) {
  await Radar.stopTracking();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Darwin Only'),
      content: Text('Barfliz is in Darwin only during beta.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## 9. Complete Login Flow with Radar

```dart
Future<void> handleLogin(String email, String password) async {
  // Step 1: Sign in with Supabase
  final response = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );

  if (response.user == null) return;

  final userId = response.user!.id;

  // Step 2: Initialize Radar
  await Radar.initialize('prj_test_pk_xxxxx');

  // Step 3: Set Radar user ID
  await Radar.setUserId(userId);

  // Step 4: Check location permissions
  final hasPermission = await checkPermissions();
  if (!hasPermission) {
    showPermissionError();
    return;
  }

  // Step 5: Check Darwin bounds
  final position = await Geolocator.getCurrentPosition();
  if (!DarwinBounds.contains(position.latitude, position.longitude)) {
    showDarwinOnlyMessage();
    return;
  }

  // Step 6: Start tracking
  await Radar.startTracking(RadarTrackingOptions(
    desiredStoppedUpdateInterval: 180,
    desiredMovingUpdateInterval: 60,
    desiredSyncInterval: 50,
    desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,
    stopDuration: 140,
    stopDistance: 70,
    sync: RadarTrackingOptionsSync.all,
    replay: RadarTrackingOptionsReplay.stops,
    useStoppedGeofence: true,
    stoppedGeofenceRadius: 100,
    useMovingGeofence: true,
    movingGeofenceRadius: 100,
    syncGeofences: true,
    foregroundServiceEnabled: true,
  ));

  // Step 7: Navigate to home
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => HomeScreen()),
  );
}
```

---

## 10. App Start - Restore Tracking

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeRadar();
  }

  Future<void> _initializeRadar() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Radar.initialize('prj_test_pk_xxxxx');
      await Radar.setUserId(userId);

      final position = await Geolocator.getCurrentPosition();
      if (DarwinBounds.contains(position.latitude, position.longitude)) {
        final isTracking = await Radar.isTracking();
        if (!isTracking) {
          await Radar.startTracking(/* tracking options */);
        }
      }
    } catch (e) {
      print('Failed to initialize Radar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

---

## 11. Using RadarService (Recommended)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/radar_service.dart';
import 'providers/radar_provider.dart';

// In your widget
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radarState = ref.watch(radarTrackingStateProvider);

    return Scaffold(
      body: ElevatedButton(
        onPressed: () async {
          // Login logic
          final userId = 'user-uuid-from-supabase';

          // Start tracking with RadarService
          final success = await ref
              .read(radarTrackingStateProvider.notifier)
              .startTracking(userId: userId);

          if (!success) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Darwin Only'),
                content: Text(radarState.errorMessage ?? 'Location error'),
              ),
            );
          }
        },
        child: Text('Login'),
      ),
    );
  }
}
```

---

## 12. Track Once (Manual Update)

```dart
await Radar.trackOnce();
```

---

## 13. Get Current Radar Location

```dart
final result = await Radar.getLocation(
  RadarTrackingOptionsDesiredAccuracy.high,
);

if (result.location != null) {
  print('Lat: ${result.location!.latitude}');
  print('Lng: ${result.location!.longitude}');
}
```

---

## 14. Check if Tracking is Active

```dart
final isTracking = await Radar.isTracking();
print('Currently tracking: $isTracking');
```

---

## 15. Get Current Tracking Options

```dart
final options = await Radar.getTrackingOptions();
if (options != null) {
  print('Stopped interval: ${options.desiredStoppedUpdateInterval}');
  print('Moving interval: ${options.desiredMovingUpdateInterval}');
}
```

---

## 16. Environment Variable Setup

### Option 1: Command Line

```bash
flutter run --dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx
```

### Option 2: VS Code launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx"
      ]
    }
  ]
}
```

### Option 3: Android Studio Run Configuration

```
Run > Edit Configurations > Additional run args:
--dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx
```

---

## 17. iOS Info.plist (Copy-Paste Ready)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Barfliz needs your location to show nearby bars and automatically check you in.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Barfliz needs your location in the background to automatically check you in when you arrive at bars.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Barfliz needs your location in the background to automatically check you in when you arrive at bars.</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>fetch</string>
</array>
```

---

## 18. Android Permissions (Copy-Paste Ready)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

---

## 19. Android Service Configuration (Copy-Paste Ready)

```xml
<service
    android:name="io.radar.sdk.RadarService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="location" />
```

---

## 20. Show Darwin Only Dialog

```dart
void showDarwinOnlyDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange),
          SizedBox(width: 12),
          Text('Darwin Only'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Barfliz is in Darwin only during beta.'),
          SizedBox(height: 16),
          Text(
            'Darwin, Northern Territory',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bounds: ${DarwinBounds.south}°S to ${DarwinBounds.north}°S',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## Quick Integration Checklist

1. ✅ Add `flutter_radar: ^3.11.0` to `pubspec.yaml`
2. ✅ Configure iOS Info.plist
3. ✅ Configure Android AndroidManifest.xml
4. ✅ Set RADAR_PUBLISHABLE_KEY environment variable
5. ✅ Initialize Radar on app start
6. ✅ Set userId on login with Supabase user ID
7. ✅ Check Darwin bounds before starting tracking
8. ✅ Start tracking with appropriate options
9. ✅ Stop tracking on logout or out of bounds
10. ✅ Handle permission requests properly

---

## Production Environment Variables

```bash
# Development
flutter run --dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx

# Production
flutter build apk --dart-define=RADAR_PUBLISHABLE_KEY=prj_live_pk_xxxxx
flutter build ios --dart-define=RADAR_PUBLISHABLE_KEY=prj_live_pk_xxxxx
```
