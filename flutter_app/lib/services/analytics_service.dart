import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  Future<void> initialize({required String apiKey, required String host}) async {
    final config = PostHogConfig(apiKey)
      ..host = host
      ..debug = kDebugMode
      ..captureApplicationLifecycleEvents = true;
    await Posthog().setup(config);
    debugPrint('[Analytics] PostHog initialised (host: $host)');
  }

  Future<void> identify(String userId, {Map<String, Object>? properties}) async {
    try {
      await Posthog().identify(userId: userId, userProperties: properties);
    } catch (e, st) {
      debugPrint('[Analytics] identify error: $e\n$st');
    }
  }

  Future<void> reset() async {
    try {
      await Posthog().reset();
    } catch (e, st) {
      debugPrint('[Analytics] reset error: $e\n$st');
    }
  }

  Future<void> screen(String screenName, {Map<String, Object>? properties}) async {
    try {
      await Posthog().screen(screenName: screenName, properties: properties);
      debugPrint('[Analytics] screen: $screenName');
    } catch (e, st) {
      debugPrint('[Analytics] screen error: $e\n$st');
    }
  }

  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    try {
      await Posthog().capture(eventName: event, properties: properties);
      debugPrint('[Analytics] event: $event $properties');
    } catch (e, st) {
      debugPrint('[Analytics] capture error: $e\n$st');
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> userSignedUp(String userId) async {
    await identify(userId);
    await capture('user_signed_up');
  }

  Future<void> userSignedIn(String userId) async {
    await identify(userId);
    await capture('user_signed_in');
  }

  Future<void> userSignedOut() async {
    await capture('user_signed_out');
    await reset();
  }

  // ── Venue ─────────────────────────────────────────────────────────────────

  Future<void> venueCheckedIn({required String venueId, required String venueName}) async {
    await capture('venue_checked_in', properties: {
      'venue_id': venueId,
      'venue_name': venueName,
    });
  }

  Future<void> venueViewed({required String venueId, required String venueName}) async {
    await capture('venue_viewed', properties: {
      'venue_id': venueId,
      'venue_name': venueName,
    });
  }

  // ── Social ────────────────────────────────────────────────────────────────

  Future<void> swarmCreated({String? swarmId}) async {
    await capture('swarm_created', properties: swarmId != null ? {'swarm_id': swarmId} : null);
  }

  Future<void> messageSent() async {
    await capture('message_sent');
  }

  Future<void> friendRequestSent(String targetUserId) async {
    await capture('friend_request_sent', properties: {'target_user_id': targetUserId});
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Future<void> paymentSent({required double amount, required String currency}) async {
    await capture('payment_sent', properties: {
      'amount': amount,
      'currency': currency,
    });
  }

  Future<void> giftSent({required String giftType, required double amount}) async {
    await capture('gift_sent', properties: {
      'gift_type': giftType,
      'amount': amount,
    });
  }
}

// ---------------------------------------------------------------------------
// GoRouter / Navigator observer — tracks every pushed screen automatically
// ---------------------------------------------------------------------------

class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AnalyticsService.instance.screen(name);
    }
  }
}
