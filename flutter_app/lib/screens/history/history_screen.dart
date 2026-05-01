import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../extensions/localization_extension.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class ActivityFeedEntry {
  final String id;
  final String activityType;
  final String? content;
  final DateTime createdAt;

  ActivityFeedEntry({
    required this.id,
    required this.activityType,
    this.content,
    required this.createdAt,
  });

  factory ActivityFeedEntry.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    return ActivityFeedEntry(
      id: json['id'] as String,
      activityType: json['activity_type'] as String? ?? '',
      content: metadata?['content'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class VenueVisitEntry {
  final String id;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  VenueVisitEntry({
    required this.id,
    required this.metadata,
    required this.createdAt,
  });

  factory VenueVisitEntry.fromJson(Map<String, dynamic> json) {
    return VenueVisitEntry(
      id: json['id'] as String,
      metadata: (json['activity_data'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get venueName => metadata['venue_name'] as String? ?? 'Unknown Venue';
  String? get venueAddress => metadata['venue_address'] as String?;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final activityFeedProvider = FutureProvider<List<ActivityFeedEntry>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('activity_feed')
      .select()
      .eq('actor_user_id', currentUser.id)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => ActivityFeedEntry.fromJson(json as Map<String, dynamic>))
      .toList();
});

final venueVisitsProvider = FutureProvider<List<VenueVisitEntry>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('user_activity_history')
      .select()
      .eq('user_id', currentUser.id)
      .eq('activity_type', 'venue_checkin')
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => VenueVisitEntry.fromJson(json as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _brandPink = Color(0xFFE91E63);
  static const _background = Color(0xFFFFF5F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t(AppStrings.historyTitle),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brandPink,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: _brandPink,
          indicatorWeight: 3,
          tabs: [
            Tab(text: t(AppStrings.historyTabActivity)),
            Tab(text: t(AppStrings.historyTabVisits)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActivityTab(),
          _VisitsTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity Tab
// ---------------------------------------------------------------------------

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  static const _brandPink = Color(0xFFE91E63);

  IconData _iconForType(String type) {
    switch (type) {
      case 'check_in':
        return Icons.local_bar;
      case 'message':
        return Icons.chat_bubble;
      case 'swarm':
        return Icons.groups;
      case 'friend':
        return Icons.person_add;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.bolt;
    }
  }

  String _titleForType(BuildContext context, String type) {
    switch (type) {
      case 'check_in':
        return context.tr(AppStrings.historyTypeCheckin);
      case 'message':
        return context.tr(AppStrings.historyTypeMessage);
      case 'swarm':
        return context.tr(AppStrings.historyTypeSwarm);
      case 'friend':
        return context.tr(AppStrings.historyTypeFriend);
      case 'gift':
        return context.tr(AppStrings.historyTypeGift);
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final feedAsync = ref.watch(activityFeedProvider);

    return feedAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _brandPink),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('${context.tr(AppStrings.error)}: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(activityFeedProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
              ),
              child: Text(t(AppStrings.retry)),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
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
                    Icons.history,
                    size: 40,
                    color: _brandPink,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t(AppStrings.historyEmpty),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(AppStrings.historyEmptySub),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(activityFeedProvider),
          color: _brandPink,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _ActivityTile(
                icon: _iconForType(entry.activityType),
                title: _titleForType(context, entry.activityType),
                content: entry.content,
                timestamp: entry.createdAt,
              );
            },
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final DateTime timestamp;

  const _ActivityTile({
    required this.icon,
    required this.title,
    this.content,
    required this.timestamp,
  });

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _brandPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: _brandPink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  if (content != null && content!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      content!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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

// ---------------------------------------------------------------------------
// Visits Tab
// ---------------------------------------------------------------------------

class _VisitsTab extends ConsumerWidget {
  const _VisitsTab();

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final visitsAsync = ref.watch(venueVisitsProvider);

    return visitsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _brandPink),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('${context.tr(AppStrings.error)}: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(venueVisitsProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
              ),
              child: Text(t(AppStrings.retry)),
            ),
          ],
        ),
      ),
      data: (visits) {
        if (visits.isEmpty) {
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
                    Icons.local_bar,
                    size: 40,
                    color: _brandPink,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t(AppStrings.historyVisitsEmpty),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(AppStrings.historyVisitsEmptySub),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(venueVisitsProvider),
          color: _brandPink,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: visits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final visit = visits[index];
              return _VenueVisitTile(visit: visit);
            },
          ),
        );
      },
    );
  }
}

class _VenueVisitTile extends StatelessWidget {
  final VenueVisitEntry visit;

  const _VenueVisitTile({required this.visit});

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(visit.createdAt.toLocal());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _brandPink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_bar, size: 22, color: _brandPink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visit.venueName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (visit.venueAddress != null &&
                      visit.venueAddress!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      visit.venueAddress!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
