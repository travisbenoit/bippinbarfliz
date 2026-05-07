import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['notification_type'] as String? ?? 'default',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: (json['metadata'] as Map<String, dynamic>?) ?? {},
      read: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('notifications')
      .select()
      .eq('recipient_user_id', currentUser.id)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) =>
          AppNotification.fromJson(json as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const _brandPink = Color(0xFFE91E63);

  bool _markingAll = false;

  Future<void> _markAllRead() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_user_id', currentUser.id)
          .eq('is_read', false);

      ref.invalidate(notificationsProvider);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.read).length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t(AppStrings.notificationsTitle),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount ${t(AppStrings.notificationsUnread)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _brandPink,
                ),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            _markingAll
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _brandPink,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      t(AppStrings.notificationsMarkAllRead),
                      style: const TextStyle(
                        color: _brandPink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _brandPink),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${t(AppStrings.notificationsError)}: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandPink,
                  foregroundColor: Colors.white,
                ),
                child: Text(t(AppStrings.retry)),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _brandPink.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      size: 40,
                      color: _brandPink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t(AppStrings.notificationsEmpty),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(AppStrings.notificationsAllCaughtUp),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          final today = notifications
              .where((n) => n.createdAt.toLocal().isAfter(todayStart))
              .toList();
          final earlier = notifications
              .where((n) => !n.createdAt.toLocal().isAfter(todayStart))
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            color: _brandPink,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (today.isNotEmpty) ...[
                  _SectionHeader(label: t(AppStrings.notificationsToday)),
                  ...today.map(
                    (n) => _NotificationCard(
                      notification: n,
                      onTap: () => _handleTap(context, ref, n),
                    ),
                  ),
                ],
                if (earlier.isNotEmpty) ...[
                  _SectionHeader(label: t(AppStrings.notificationsEarlier)),
                  ...earlier.map(
                    (n) => _NotificationCard(
                      notification: n,
                      onTap: () => _handleTap(context, ref, n),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // Mark as read in DB if not already
    if (!notification.read) {
      try {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', notification.id);
        ref.invalidate(notificationsProvider);
      } catch (_) {
        // Non-fatal: silently ignore
      }
    }

    if (!context.mounted) return;

    // Navigate based on type
    switch (notification.type) {
      case 'message':
        context.push('/messages');
        break;
      case 'swarm':
        context.push('/swarms');
        break;
      case 'gift':
        context.push('/gifts');
        break;
      case 'friend':
      case 'friend_request':
        context.push('/friends');
        break;
      default:
        break;
    }
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification card
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  static const _brandPink = Color(0xFFE91E63);

  IconData _iconForType(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend':
        return Icons.person_add;
      case 'message':
        return Icons.chat_bubble;
      case 'swarm':
        return Icons.groups;
      case 'gift':
        return Icons.card_giftcard;
      case 'checkin':
        return Icons.local_bar;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'friend_request':
      case 'friend':
        return Colors.blue;
      case 'message':
        return Colors.teal;
      case 'swarm':
        return Colors.deepPurple;
      case 'gift':
        return Colors.amber.shade700;
      case 'checkin':
        return Colors.green;
      default:
        return _brandPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final iconColor = _colorForType(notification.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? _brandPink.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator dot
            SizedBox(
              width: 10,
              child: isUnread
                  ? Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: _brandPink,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox(width: 8),
            ),
            const SizedBox(width: 8),
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForType(notification.type),
                  size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeago.format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
