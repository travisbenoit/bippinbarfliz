# Radar Flutter Integration for Darwin Beta

Complete guide for integrating Radar SDK in Flutter with Darwin-only geofencing.

## Table of Contents
1. [Setup](#setup)
2. [Code Snippets](#code-snippets)
3. [Permission Handling](#permission-handling)
4. [Usage Examples](#usage-examples)
5. [Platform-Specific Configuration](#platform-specific-configuration)

---

## Setup

### 1. Dependencies

The `pubspec.yaml` already includes:

```yaml
dependencies:
  flutter_radar: ^3.11.0
  geolocator: ^10.1.0
  permission_handler: ^12.0.1
```

### 2. Environment Variables

Add your Radar publishable key to your run configuration:

```bash
flutter run --dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx
```

Or in your IDE configuration:
```
--dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx
```

---

## Code Snippets

### Initialize Radar

```dart
import 'package:flutter_radar/flutter_radar.dart';

class RadarService {
  static const String _publishableKey = String.fromEnvironment(
    'RADAR_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  Future<void> initialize() async {
    try {
      await Radar.initialize(_publishableKey);
      print('✅ Radar SDK initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Radar SDK: $e');
      rethrow;
    }
  }
}
```

### Set User ID

```dart
Future<void> setUserId(String userId) async {
  try {
    await Radar.setUserId(userId);
    print('✅ Radar user ID set to: $userId');
  } catch (e) {
    print('❌ Failed to set Radar user ID: $e');
    rethrow;
  }
}
```

### Start Tracking

```dart
Future<bool> startTracking({String? userId}) async {
  if (userId != null) {
    await setUserId(userId);
  }

  try {
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

    print('✅ Radar tracking started successfully');
    return true;
  } catch (e) {
    print('❌ Failed to start Radar tracking: $e');
    return false;
  }
}
```

### Stop Tracking

```dart
Future<void> stopTracking() async {
  try {
    await Radar.stopTracking();
    print('⏹️ Radar tracking stopped');
  } catch (e) {
    print('❌ Failed to stop Radar tracking: $e');
  }
}
```

### Check Darwin Bounds

```dart
class DarwinBounds {
  static const double north = -12.35;
  static const double south = -12.55;
  static const double west = 130.75;
  static const double east = 131.05;

  static bool contains(double latitude, double longitude) {
    return latitude >= south &&
        latitude <= north &&
        longitude >= west &&
        longitude <= east;
  }
}

Future<bool> isInDarwinBounds() async {
  final position = await Geolocator.getCurrentPosition();
  return DarwinBounds.contains(position.latitude, position.longitude);
}

Future<LocationCheckResult> checkDarwinLocation() async {
  final position = await Geolocator.getCurrentPosition();

  if (!DarwinBounds.contains(position.latitude, position.longitude)) {
    return LocationCheckResult(
      isInBounds: false,
      errorMessage: 'Barfliz is in Darwin only during beta.',
    );
  }

  return LocationCheckResult(isInBounds: true);
}
```

---

## Permission Handling

### Check and Request Permissions

```dart
Future<bool> checkLocationPermissions() async {
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
}
```

### iOS Permission Handling

Ensure your `Info.plist` includes:

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

### Android Permission Handling

Ensure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />

<application>
  <!-- Add foreground service permission for Android 14+ -->
  <service
    android:name="io.radar.sdk.RadarService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="location" />
</application>
```

### Request Background Location (Android 10+)

```dart
Future<bool> requestBackgroundLocationPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    if (androidInfo.version.sdkInt >= 29) {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    }
  }

  return true;
}
```

---

## Usage Examples

### Example 1: Initialize on App Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/radar_provider.dart';

class MyApp extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(radarTrackingStateProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

### Example 2: Start Tracking on Login

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthProvider extends StateNotifier<AuthState> {
  final RadarService _radarService;

  AuthProvider(this._radarService) : super(AuthState.initial());

  Future<void> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        await _radarService.initialize();
        await _radarService.setUserId(userId);

        final locationCheck = await _radarService.checkDarwinLocation();

        if (locationCheck.isInBounds) {
          await _radarService.startTracking(userId: userId);
        } else {
          showDarwinOnlyDialog();
        }
      }
    } catch (e) {
      print('Sign in error: $e');
    }
  }
}
```

### Example 3: Check Darwin Location Before Feature Access

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radarState = ref.watch(radarTrackingStateProvider);

    return Scaffold(
      body: radarState.lastLocationCheck?.isInBounds == false
          ? DarwinOnlyMessage(
              message: radarState.errorMessage ??
                       'Barfliz is in Darwin only during beta.',
            )
          : MainContent(),
    );
  }
}

class DarwinOnlyMessage extends StatelessWidget {
  final String message;

  const DarwinOnlyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Darwin, NT',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 4: Periodic Location Check

```dart
class LocationChecker {
  final RadarService _radarService;
  Timer? _timer;

  LocationChecker(this._radarService);

  void startPeriodicCheck() {
    _timer = Timer.periodic(Duration(minutes: 5), (timer) async {
      final isInBounds = await _radarService.isInDarwinBounds();

      if (!isInBounds && _radarService.isTracking) {
        await _radarService.stopTracking();
        showDarwinOnlyDialog();
      }
    });
  }

  void stopPeriodicCheck() {
    _timer?.cancel();
    _timer = null;
  }
}
```

### Example 5: Complete Login Flow with Radar

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if (response.user != null) {
        final userId = response.user!.id;
        final radarNotifier = ref.read(radarTrackingStateProvider.notifier);

        await radarNotifier.initialize();
        await radarNotifier.setUserId(userId);

        final success = await radarNotifier.startTracking(userId: userId);

        if (success) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else {
          final radarState = ref.read(radarTrackingStateProvider);
          _showDarwinOnlyDialog(radarState.errorMessage);
        }
      }
    } catch (e) {
      _showErrorDialog('Login failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDarwinOnlyDialog(String? message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Darwin Only'),
        content: Text(
          message ?? 'Barfliz is in Darwin only during beta.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LoginForm(onLogin: _handleLogin),
    );
  }
}
```

---

## Platform-Specific Configuration

### iOS Configuration (Info.plist)

Location in: `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Barfliz needs your location to show nearby bars and automatically check you in.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Barfliz needs your location in the background to automatically check you in when you arrive at bars.</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Barfliz needs your location in the background to automatically check you in when you arrive at bars.</string>

    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>

    <!-- Privacy - Motion Usage (optional, for improved accuracy) -->
    <key>NSMotionUsageDescription</key>
    <string>Barfliz uses motion data to improve location accuracy and detect when you arrive at bars.</string>
</dict>
</plist>
```

### Android Configuration (AndroidManifest.xml)

Location in: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- For Android 12+ (API 31+) -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />

    <!-- For Android 10+ (API 29+) Background Location -->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <application
        android:label="Barfliz"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Radar Service -->
        <service
            android:name="io.radar.sdk.RadarService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="location" />

        <!-- Main Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### Android build.gradle Configuration

Location in: `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}

dependencies {
    // Radar SDK is automatically added by flutter_radar plugin
}
```

---

## Tracking Options Explained

```dart
RadarTrackingOptions(
  // Update interval when user is stationary (seconds)
  desiredStoppedUpdateInterval: 180,  // 3 minutes

  // Update interval when user is moving (seconds)
  desiredMovingUpdateInterval: 60,    // 1 minute

  // Sync interval (seconds)
  desiredSyncInterval: 50,             // 50 seconds

  // Location accuracy
  desiredAccuracy: RadarTrackingOptionsDesiredAccuracy.high,

  // Minimum duration to be considered stopped (seconds)
  stopDuration: 140,                   // 2.3 minutes

  // Minimum distance to be considered stopped (meters)
  stopDistance: 70,                    // 70 meters

  // Sync all location data
  sync: RadarTrackingOptionsSync.all,

  // Replay stops for better accuracy
  replay: RadarTrackingOptionsReplay.stops,

  // Don't show blue bar on iOS
  showBlueBar: false,

  // Use geofencing when stopped
  useStoppedGeofence: true,
  stoppedGeofenceRadius: 100,          // 100 meters

  // Use geofencing when moving
  useMovingGeofence: true,
  movingGeofenceRadius: 100,           // 100 meters

  // Sync geofences from server
  syncGeofences: true,
  syncGeofencesLimit: 10,              // Max 10 geofences

  // Don't use beacons
  beacons: false,

  // Enable foreground service for Android
  foregroundServiceEnabled: true,
)
```

---

## Testing Checklist

### Initial Setup
- [ ] Add Radar publishable key to environment
- [ ] Configure iOS Info.plist
- [ ] Configure Android AndroidManifest.xml
- [ ] Run `flutter pub get`

### Permission Testing
- [ ] Test location permission request flow
- [ ] Test "denied" permission handling
- [ ] Test "deniedForever" permission handling
- [ ] Test background location permission (Android 10+)

### Darwin Bounds Testing
- [ ] Test with location inside Darwin bounds
- [ ] Test with location outside Darwin bounds
- [ ] Verify error message shows correctly

### Tracking Testing
- [ ] Test tracking start on login
- [ ] Test tracking stop on logout
- [ ] Test tracking persistence across app restarts
- [ ] Test background tracking
- [ ] Verify geofence events in Radar dashboard

### Edge Cases
- [ ] Test with location services disabled
- [ ] Test with no internet connection
- [ ] Test rapid start/stop cycles
- [ ] Test memory leaks (dispose properly)

---

## Troubleshooting

### Issue: Radar not initializing
**Solution:** Verify publishable key is set correctly in environment variables.

```bash
flutter run --dart-define=RADAR_PUBLISHABLE_KEY=prj_test_pk_xxxxx
```

### Issue: Background tracking not working on iOS
**Solution:** Ensure all required keys are in Info.plist and background modes are enabled.

### Issue: Background tracking not working on Android
**Solution:** Request ACCESS_BACKGROUND_LOCATION permission for Android 10+.

### Issue: Darwin bounds check failing
**Solution:** Ensure location permissions are granted and location services are enabled.

### Issue: User not appearing in Radar dashboard
**Solution:** Verify `setUserId()` is called with the correct Supabase user ID.

---

## Production Checklist

Before releasing to production:

- [ ] Replace test publishable key with production key
- [ ] Update tracking intervals for production use
- [ ] Test with real devices in Darwin area
- [ ] Monitor Radar dashboard for tracking accuracy
- [ ] Set up error monitoring for Radar failures
- [ ] Configure rate limiting if needed
- [ ] Test battery impact
- [ ] Verify GDPR/privacy compliance
- [ ] Add user controls for tracking preferences

---

## Additional Resources

- [Radar Flutter SDK Documentation](https://radar.com/documentation/sdk/flutter)
- [Radar Dashboard](https://radar.com/dashboard)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Permission Handler Package](https://pub.dev/packages/permission_handler)
