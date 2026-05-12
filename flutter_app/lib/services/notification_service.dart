import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_router.dart';

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

  // Stored when app is opened from a terminated-state notification tap.
  static String? _pendingRoute;

  // Called by BarflizApp after auth is confirmed to consume and navigate.
  static String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }

  // ── Initialise ──────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    await _initLocalNotifications();
    await _captureTerminatedNotification();
    _setupFCMHandlers();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Foreground notification tap — payload is JSON-encoded FCM data map.
        final payload = details.payload;
        if (payload == null) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          navigateFromNotification(_routeFor(data));
        } catch (_) {
          navigateFromNotification('/notifications');
        }
      },
    );

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

  // Capture the message that launched the app from a terminated state.
  static Future<void> _captureTerminatedNotification() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) {
      _pendingRoute = _routeFor(msg.data);
    }
  }

  static void _setupFCMHandlers() {
    // Foreground: FCM suppresses system tray — show local notification instead.
    FirebaseMessaging.onMessage.listen((message) {
      _NotificationHelper.showFromRemoteMessage(message);
    });

    // Background tap: app was in background, user tapped notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      navigateFromNotification(_routeFor(message.data));
    });
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final fcmGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!fcmGranted && Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return fcmGranted;
  }

  // ── FCM Token Registration ───────────────────────────────────────────────────

  static Future<void> registerFCMToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

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
      }, onConflict: 'user_id,platform');

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

  // ── Route helper ─────────────────────────────────────────────────────────────

  static String _routeFor(Map<String, dynamic> data) {
    final tag = data['tag'] as String? ?? '';
    switch (tag) {
      case 'message':
        final senderId = data['sender_user_id'] as String?;
        return senderId != null ? '/chat/$senderId' : '/messages';
      case 'friend_request':
      case 'friend_accepted':
        return '/friends';
      case 'swarm_created':
      case 'swarm_joined':
        return '/swarms';
      case 'gift':
        return '/gifts';
      case 'dd_tonight':
        return '/home';
      default:
        return '/notifications';
    }
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
      // Encode the full data map so the tap handler can route correctly.
      payload: jsonEncode(message.data),
    );
  }
}
