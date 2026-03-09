# Deployment Guide

## Quick Deployment Checklist

### Before Deployment

- [ ] Update app version in `pubspec.yaml`
- [ ] Add all required assets (images, fonts, icons)
- [ ] Configure environment variables
- [ ] Test on multiple devices
- [ ] Set up Stripe in production mode
- [ ] Configure Firebase for push notifications
- [ ] Test payment flows
- [ ] Add app icons and splash screens

### Android Deployment

#### 1. Generate Keystore

```bash
keytool -genkey -v -keystore ~/barfliz-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias barfliz
```

#### 2. Configure Signing

Create `android/key.properties`:

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=barfliz
storeFile=../barfliz-release-key.jks
```

Update `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### 3. Build Release APK

```bash
flutter build apk --release
```

#### 4. Build App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release
```

The output will be at `build/app/outputs/bundle/release/app-release.aab`

#### 5. Upload to Google Play Console

1. Go to https://play.google.com/console
2. Create a new application
3. Upload the AAB file
4. Fill in store listing details
5. Set up pricing & distribution
6. Submit for review

### iOS Deployment

#### 1. Configure Xcode Project

```bash
open ios/Runner.xcworkspace
```

In Xcode:
- Set Bundle Identifier
- Configure signing & capabilities
- Add required capabilities (Push Notifications, Location)
- Update version and build number

#### 2. Build Release

```bash
flutter build ios --release
```

#### 3. Archive in Xcode

1. Open `ios/Runner.xcworkspace`
2. Select "Any iOS Device" as target
3. Product > Archive
4. Distribute App > App Store Connect

#### 4. Upload to App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Create new app
3. Upload build from Xcode
4. Fill in app information
5. Submit for review

### Environment-Specific Configuration

#### Development

```dart
const bool isDevelopment = true;
const String supabaseUrl = 'dev-url';
```

#### Production

```dart
const bool isDevelopment = false;
const String supabaseUrl = 'prod-url';
```

### Continuous Integration (Optional)

#### GitHub Actions

Create `.github/workflows/flutter.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release
```

### Monitoring & Analytics

#### Firebase Analytics

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_analytics: ^10.7.0
```

Initialize in `main.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;
```

#### Crashlytics

```yaml
dependencies:
  firebase_crashlytics: ^3.4.0
```

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  runApp(const BarflizApp());
}
```

### Performance Optimization

#### 1. Reduce App Size

```bash
flutter build apk --split-per-abi
```

#### 2. Enable Code Shrinking

In `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
    }
}
```

#### 3. Optimize Images

- Use WebP format for images
- Compress images before adding to assets
- Use `cached_network_image` for remote images

### Security Checklist

- [ ] Use HTTPS for all API calls
- [ ] Implement certificate pinning
- [ ] Obfuscate code in production
- [ ] Store sensitive data securely
- [ ] Validate all user inputs
- [ ] Implement proper RLS in Supabase
- [ ] Use environment variables for secrets
- [ ] Enable ProGuard/R8 for Android

### Post-Deployment

#### Monitor

- App crashes (Firebase Crashlytics)
- User analytics (Firebase Analytics)
- API performance (Supabase Dashboard)
- Payment success rate (Stripe Dashboard)
- User reviews (App Store & Play Store)

#### Update Strategy

1. Use semantic versioning (1.0.0, 1.0.1, 1.1.0, etc.)
2. Test updates on staging environment
3. Roll out gradually (10% → 50% → 100%)
4. Monitor crash rates after updates
5. Keep rollback plan ready

### Compliance

#### GDPR

- Add privacy policy
- Implement data export
- Implement data deletion
- Add cookie consent (if web)

#### App Store Requirements

- Privacy labels
- Age rating
- Content description
- Support URL
- Terms of service

#### Play Store Requirements

- Privacy policy URL
- Target SDK version
- 64-bit support
- Content rating

### Support

Set up:
- Email support (support@barfliz.com)
- In-app feedback form
- FAQ/Help center
- Social media channels

## Congratulations!

Your Barfliz app is now ready for deployment! 🎉
