import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level handler required by firebase_messaging for background/terminated state.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await _NotificationHelper.showFromRemoteMessage(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'barfliz_channel';
  static const _androidChannelName = 'Barfliz Notifications';

  // ── Initialise ──────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    await _initLocalNotifications();
    _setupFCMHandlers();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we request explicitly via requestPermission()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // payload-based deep-link routing can be added here
      },
    );

    // Create the Android channel upfront so it exists before any notification.
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: 'Notifications for Barfliz app',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _setupFCMHandlers() {
    // Foreground messages: FCM suppresses the system tray on iOS/Android when
    // the app is open, so we show a local notification ourselves.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _NotificationHelper.showFromRemoteMessage(message);
    });

    // App was in the background and user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened from background: ${message.messageId}');
      // Deep-link handling can be wired here via a global navigator key.
    });
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    // iOS / Android 13+: ask via firebase_messaging (handles APNs on iOS).
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final fcmGranted = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    // Android < 13 falls through to permission_handler as a safety net.
    if (!fcmGranted && Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return fcmGranted;
  }

  // ── FCM Token Registration ───────────────────────────────────────────────────

  /// Call this after the user is authenticated.
  static Future<void> registerFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // On iOS, APNs token must be available before FCM token is issued.
      if (Platform.isIOS) {
        await messaging.getAPNSToken();
      }

      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] No token available (permission not granted?)');
        return;
      }

      debugPrint('[FCM] Token: $token');
      await _saveTokenToSupabase(token);

      // Refresh handler: token can rotate, keep Supabase in sync.
      messaging.onTokenRefresh.listen(_saveTokenToSupabase);
    } catch (e, st) {
      debugPrint('[FCM] registerFCMToken error: $e\n$st');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('push_subscriptions').upsert({
        'user_id': userId,
        'native_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      debugPrint('[FCM] Token saved to Supabase');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  // ── Local Notifications ──────────────────────────────────────────────────────

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _local.show(
      id,
      title,
      body,
      _buildNotificationDetails(),
      payload: payload,
    );
  }

  static NotificationDetails _buildNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Notifications for Barfliz app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }
}

// Internal helper used by both the foreground listener and the background isolate.
class _NotificationHelper {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'barfliz_channel',
      'Barfliz Notifications',
      channelDescription: 'Notifications for Barfliz app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: message.data['type'] as String?,
    );
  }
}
