import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Preference keys must match the keys stored in push_subscriptions.preferences
// and the toggles shown in NotificationsSettingsScreen.
class _Pref {
  static const messages = 'messages';
  static const friendRequests = 'friend_requests';
  static const swarms = 'swarms';
  static const gifts = 'gifts';
}

class NotificationSender {
  static final _db = Supabase.instance.client;

  // ── Public entry points ──────────────────────────────────────────────────

  /// Notifies followers that the current user is being DD tonight.
  static Future<void> ddTonight({required String userName}) async {
    final followerIds = await _acceptedFriendIds();
    if (followerIds.isEmpty) return;
    await _notify(
      recipientIds: followerIds,
      type: 'dd_tonight',
      title: '$userName is the DD tonight! 🚗',
      body: 'They\'re staying sober to keep everyone safe.',
      preferenceKey: _Pref.friendRequests,
    );
  }

  /// Notifies a user that someone started following them.
  static Future<void> followStarted({
    required String toUserId,
    required String followerName,
  }) async {
    await _notify(
      recipientIds: [toUserId],
      type: 'friend_request',
      title: '$followerName started following you',
      body: 'Check out their profile',
      preferenceKey: _Pref.friendRequests,
    );
  }

  /// Notifies all accepted friends when the current user creates a swarm.
  static Future<void> swarmCreated({
    required String swarmId,
    required String swarmTitle,
    required String hostName,
  }) async {
    final friendIds = await _acceptedFriendIds();
    if (friendIds.isEmpty) return;
    await _notify(
      recipientIds: friendIds,
      type: 'swarm_created',
      title: '$hostName created a new swarm!',
      body: swarmTitle,
      preferenceKey: _Pref.swarms,
      swarmId: swarmId,
    );
  }

  /// Notifies the swarm host when someone joins.
  static Future<void> swarmJoined({
    required String swarmId,
    required String swarmTitle,
    required String hostUserId,
    required String joinerName,
  }) async {
    final me = _db.auth.currentUser;
    if (me == null || hostUserId == me.id) return;
    await _notify(
      recipientIds: [hostUserId],
      type: 'swarm_joined',
      title: '$joinerName joined your swarm!',
      body: swarmTitle,
      preferenceKey: _Pref.swarms,
      swarmId: swarmId,
    );
  }

  /// Notifies the recipient of a new friend request.
  static Future<void> friendRequestSent({
    required String toUserId,
    required String fromName,
  }) async {
    await _notify(
      recipientIds: [toUserId],
      type: 'friend_request',
      title: 'New friend request',
      body: '$fromName wants to be your friend',
      preferenceKey: _Pref.friendRequests,
    );
  }

  /// Notifies the original requester that their request was accepted.
  static Future<void> friendRequestAccepted({
    required String toUserId,
    required String accepterName,
  }) async {
    await _notify(
      recipientIds: [toUserId],
      type: 'friend_accepted',
      title: 'Friend request accepted!',
      body: '$accepterName accepted your friend request',
      preferenceKey: _Pref.friendRequests,
    );
  }

  /// Notifies the recipient when they receive a gift.
  static Future<void> giftReceived({
    required String toUserId,
    required String senderName,
    required String itemEmoji,
    required String itemName,
  }) async {
    final me = _db.auth.currentUser;
    if (me == null || toUserId == me.id) return;
    await _notify(
      recipientIds: [toUserId],
      type: 'gift',
      title: '$senderName sent you a gift!',
      body: '$itemEmoji $itemName',
      preferenceKey: _Pref.gifts,
    );
  }

  /// Notifies the recipient when a new DM message is sent to them.
  static Future<void> messageSent({
    required String toUserId,
    required String senderName,
    required String messagePreview,
  }) async {
    final me = _db.auth.currentUser;
    if (me == null || toUserId == me.id) return;
    await _notify(
      recipientIds: [toUserId],
      type: 'message',
      title: senderName,
      body: messagePreview,
      preferenceKey: _Pref.messages,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static Future<void> _notify({
    required List<String> recipientIds,
    required String type,
    required String title,
    required String body,
    required String preferenceKey,
    String? swarmId,
    String? venueId,
  }) async {
    final me = _db.auth.currentUser;
    if (me == null || recipientIds.isEmpty) return;

    // 1. Insert in-app notification rows (always — visible in notification centre)
    try {
      await _db.from('notifications').insert(
        recipientIds
            .map((uid) => {
                  'recipient_user_id': uid,
                  'actor_user_id': me.id,
                  'notification_type': type,
                  'title': title,
                  'body': body,
                  if (swarmId != null) 'swarm_id': swarmId,
                  if (venueId != null) 'venue_id': venueId,
                })
            .toList(),
      );
    } catch (e) {
      debugPrint('[NotificationSender] DB insert failed: $e');
    }

    // 2. Send push — edge function filters by preference_key server-side
    try {
      await _db.functions.invoke(
        'send-push-notification',
        body: {
          'user_ids': recipientIds,
          'title': title,
          'notification_body': body,
          'tag': type,
          'preference_key': preferenceKey,
        },
      );
    } catch (e) {
      debugPrint('[NotificationSender] push send failed: $e');
    }
  }

  static Future<List<String>> _acceptedFriendIds() async {
    final me = _db.auth.currentUser;
    if (me == null) return [];
    try {
      final rows = await _db
          .from('friendships')
          .select('user_id, friend_id')
          .eq('status', 'accepted')
          .or('user_id.eq.${me.id},friend_id.eq.${me.id}');
      return (rows as List).map((r) {
        final uid = r['user_id'] as String;
        final fid = r['friend_id'] as String;
        return uid == me.id ? fid : uid;
      }).toList();
    } catch (e) {
      debugPrint('[NotificationSender] fetch friends failed: $e');
      return [];
    }
  }
}
