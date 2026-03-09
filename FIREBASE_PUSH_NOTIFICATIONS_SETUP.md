# Firebase Push Notifications Setup Guide

Complete setup for Firebase Cloud Messaging (FCM) on both React Web and Flutter Mobile apps.

## Part 1: Firebase Console Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: `Barfliz`
4. Accept the terms and click **"Continue"**
5. Enable/Disable Google Analytics (optional) → **"Create project"**
6. Wait for project creation to complete

### Step 2: Register Web App

1. In Firebase Console, click the **Web icon** (`</>`)
2. App nickname: `Barfliz Web`
3. Check **"Also set up Firebase Hosting"** (optional)
4. Click **"Register app"**
5. **Copy the entire config object** - you'll need this:
   ```javascript
   {
     apiKey: "YOUR_API_KEY",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     storageBucket: "your-project.appspot.com",
     messagingSenderId: "YOUR_SENDER_ID",
     appId: "YOUR_APP_ID",
     measurementId: "G-XXXXXXXXXX"
   }
   ```
6. Click **"Continue to console"**

### Step 3: Register Mobile App (Flutter)

1. Back in Firebase Console, click **Android icon**
   - Package name: `com.barfliz.app`
   - SHA-1 certificate fingerprint: (get this from your signing key)
   - Click **"Register app"**
   - Download `google-services.json`
   - Place it in: `flutter_app/android/app/`

2. Also register **iOS**:
   - Bundle ID: `com.barfliz.app`
   - Download `GoogleService-Info.plist`
   - Place it in: `flutter_app/ios/Runner/`

### Step 4: Enable Cloud Messaging

1. In Firebase Console, go to **"Cloud Messaging"** tab (left sidebar)
2. Under **"Web configuration"**:
   - Generate **Web Push Certificate** if not already done
   - Copy the **Sender ID** (shown on this page)
3. Go to **Project Settings** (gear icon top-left) → **"Service Accounts"** tab
   - Click **"Generate new private key"**
   - Save the JSON file securely (for backend use)

### Step 5: Get Credentials for Integration

You'll need to collect:

**Web Credentials:**
- Firebase Config (from Step 2)
- Sender ID (from Step 4)

**Mobile Credentials:**
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)

**Backend Credentials:**
- Private key JSON (from Step 4)
- Project ID

---

## Part 2: Database Schema Setup

This stores user notification tokens so you can send notifications.

Run this migration in Supabase:

```sql
/*
  # Add FCM notification tokens table

  1. New Tables
    - `notification_tokens` - stores device FCM tokens for push notifications

  2. Columns
    - `id` - unique identifier
    - `user_id` - user who owns the token
    - `token` - FCM device token
    - `device_type` - 'web', 'ios', or 'android'
    - `is_active` - whether token is still valid
    - `created_at` - when token was registered
    - `last_used_at` - last time notification was sent

  3. Security
    - Enable RLS: only users can manage their own tokens
*/

CREATE TABLE IF NOT EXISTS notification_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  device_type text CHECK (device_type IN ('web', 'ios', 'android')),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  last_used_at timestamptz,
  UNIQUE(user_id, token, device_type)
);

ALTER TABLE notification_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their notification tokens"
  ON notification_tokens
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_notification_tokens_user_id ON notification_tokens(user_id);
CREATE INDEX idx_notification_tokens_active ON notification_tokens(is_active);
```

---

## Part 3: Web App Integration (React)

### Step 1: Install Dependencies

```bash
npm install firebase
```

### Step 2: Create Firebase Service

Create `src/services/firebaseService.ts`:

```typescript
import { initializeApp } from 'firebase/app';
import { getMessaging, getToken, onMessage, Messaging } from 'firebase/messaging';
import { supabase } from '@/lib/supabase';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const app = initializeApp(firebaseConfig);
let messaging: Messaging | null = null;

export const initializeMessaging = async () => {
  if (!('serviceWorker' in navigator)) return null;

  try {
    await navigator.serviceWorker.register('/firebase-messaging-sw.js');
    messaging = getMessaging(app);
    return messaging;
  } catch (error) {
    console.error('Service Worker registration failed:', error);
    return null;
  }
};

export const requestNotificationPermission = async () => {
  if (!messaging) await initializeMessaging();

  try {
    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      const token = await getToken(messaging!, {
        vapidKey: import.meta.env.VITE_FIREBASE_VAPID_KEY,
      });

      if (token) {
        await saveTokenToDatabase(token, 'web');
        return token;
      }
    }
  } catch (error) {
    console.error('Error getting notification permission:', error);
  }
};

export const saveTokenToDatabase = async (token: string, deviceType: 'web' | 'ios' | 'android') => {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase
      .from('notification_tokens')
      .upsert({
        user_id: user.id,
        token,
        device_type: deviceType,
        is_active: true,
      }, {
        onConflict: 'user_id,token,device_type'
      });
  } catch (error) {
    console.error('Error saving token:', error);
  }
};

export const setupForegroundNotifications = () => {
  if (!messaging) return;

  onMessage(messaging, (payload) => {
    console.log('Foreground notification:', payload);

    if (payload.notification) {
      new Notification(payload.notification.title || 'Barfliz', {
        body: payload.notification.body,
        icon: '/logo.png',
      });
    }
  });
};
```

### Step 3: Create Service Worker

Create `public/firebase-messaging-sw.js`:

```javascript
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "YOUR_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Background notification:', payload);

  const notificationTitle = payload.notification?.title || 'Barfliz';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/logo.png',
    badge: '/badge.png',
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
```

### Step 4: Setup Environment Variables

Add to `.env`:

```
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
VITE_FIREBASE_VAPID_KEY=your_vapid_key
```

### Step 5: Initialize in App

Add to your main layout or auth context initialization:

```typescript
import { initializeMessaging, requestNotificationPermission, setupForegroundNotifications } from '@/services/firebaseService';

// After user logs in
useEffect(() => {
  const setupNotifications = async () => {
    await initializeMessaging();
    setupForegroundNotifications();
    // Optionally request permission
    // await requestNotificationPermission();
  };

  setupNotifications();
}, [user]);
```

---

## Part 4: Mobile App Integration (Flutter)

### Step 1: Add Dependencies

Update `flutter_app/pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.6.0
  flutter_local_notifications: ^16.1.0
```

Run `flutter pub get`

### Step 2: Android Setup

1. In `flutter_app/android/build.gradle`, add:
```gradle
dependencies {
  classpath 'com.google.gms:google-services:4.4.0'
}
```

2. In `flutter_app/android/app/build.gradle`, add at bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

3. Ensure `google-services.json` is in `flutter_app/android/app/`

### Step 3: iOS Setup

1. In Xcode, open `flutter_app/ios/Runner.xcworkspace`
2. Select Runner → Build Settings
3. Search for "iOS Deployment Target" → set to 11.0+
4. Add `GoogleService-Info.plist` via Xcode (add files → select the plist)

### Step 4: Create Firebase Service (Flutter)

Create `flutter_app/lib/services/firebase_messaging_service.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart'; // Generated by Firebase CLI
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseMessagingService {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Setup local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Get and save token
    await _saveToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> _saveToken(String? token) async {
    token ??= await _firebaseMessaging.getToken();
    if (token == null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('notification_tokens')
            .upsert({
              'user_id': user.id,
              'token': token,
              'device_type': GetPlatform.isAndroid ? 'android' : 'ios',
              'is_active': true,
            }, onConflict: 'user_id,token,device_type');
      }
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'barfliz_channel',
          'Barfliz Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background notification: ${message.notification?.title}');
  }
}

// Platform helper
class GetPlatform {
  static bool get isAndroid => true; // Replace with actual platform detection
}
```

### Step 5: Initialize in Main

Update `flutter_app/lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseMessagingService.initialize();

  // Other initializations...

  runApp(const MyApp());
}
```

---

## Part 5: Backend - Send Notifications

### Create Edge Function for Sending Notifications

Create `supabase/functions/send-notification/index.ts`:

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const { userId, title, body, data }: NotificationPayload = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") || "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
    );

    // Get user's notification tokens
    const { data: tokens } = await supabase
      .from("notification_tokens")
      .select("token, device_type")
      .eq("user_id", userId)
      .eq("is_active", true);

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: "No tokens found" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Send to each token
    const responses = await Promise.all(
      tokens.map((t) =>
        sendFCMNotification(t.token, title, body, data, t.device_type)
      )
    );

    return new Response(
      JSON.stringify({ sent: responses.length, responses }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
  deviceType?: string
) {
  const fcmUrl = "https://fcm.googleapis.com/v1/projects/{projectId}/messages:send";

  const accessToken = await getAccessToken();

  const payload = {
    message: {
      token,
      notification: { title, body },
      data: data || {},
      ...(deviceType === "web" && {
        webpush: {
          ttl: "3600s",
        },
      }),
      ...(["ios", "android"].includes(deviceType || "") && {
        android: {
          ttl: "3600s",
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      }),
    },
  };

  const response = await fetch(
    fcmUrl.replace("{projectId}", Deno.env.get("FIREBASE_PROJECT_ID") || ""),
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(payload),
    }
  );

  return response.json();
}

async function getAccessToken() {
  // Get from Firebase Service Account JSON
  const serviceAccount = JSON.parse(
    Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") || "{}"
  );

  const assertion = createJWT(serviceAccount);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }).toString(),
  });

  const data = await response.json();
  return data.access_token;
}

function createJWT(serviceAccount: any): string {
  // Implement JWT signing using crypto APIs
  // For production, use a JWT library
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const now = Math.floor(Date.now() / 1000);
  const payload = btoa(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    })
  );

  // This is simplified - use proper JWT signing in production
  return `${header}.${payload}.signature`;
}
```

---

## Part 6: Testing & Verification

### Test Web Notifications

1. Open your web app
2. Check browser console for Firebase initialization
3. Browser will ask for notification permission
4. Allow permissions
5. Check Supabase `notification_tokens` table - token should be saved

### Test Mobile Notifications

1. Build and run Flutter app
2. Grant notification permissions
3. Check Supabase `notification_tokens` table
4. Send test notification from Firebase Console

### Send Test Notification via API

```bash
curl -X POST http://localhost:3000/functions/v1/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "userId": "user-uuid",
    "title": "Test",
    "body": "Hello!"
  }'
```

---

## Quick Checklist

- [ ] Firebase project created
- [ ] Web app registered in Firebase
- [ ] Mobile apps registered (iOS & Android)
- [ ] Cloud Messaging enabled
- [ ] Database migration applied
- [ ] `.env` file updated with Firebase config
- [ ] Web service worker created
- [ ] Web Firebase service created
- [ ] Flutter dependencies added
- [ ] Flutter Firebase service created
- [ ] Backend edge function deployed
- [ ] Test notification sent successfully

---

## Troubleshooting

**Notifications not showing on web?**
- Check browser notifications permissions
- Verify service worker is registered
- Check browser console for errors

**Notifications not showing on mobile?**
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Check app logs in Xcode/Android Studio
- Ensure notification permissions are granted

**Tokens not saving to database?**
- Check Supabase RLS policies
- Verify user is authenticated
- Check browser/app console for errors

