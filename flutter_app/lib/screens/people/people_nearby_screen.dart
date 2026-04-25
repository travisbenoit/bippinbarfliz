import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _pink = Color(0xFFE91E63);
const _bg = Color(0xFFFFF5F0);

// ---------------------------------------------------------------------------
// Filter enum
// ---------------------------------------------------------------------------

enum PeopleFilter { all, outNow, goingOutSoon, ddTonight }

extension PeopleFilterX on PeopleFilter {
  String get label {
    switch (this) {
      case PeopleFilter.all:
        return 'All';
      case PeopleFilter.outNow:
        return 'Out Now';
      case PeopleFilter.goingOutSoon:
        return 'Going Out Soon';
      case PeopleFilter.ddTonight:
        return 'DD Tonight';
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _supabase = Supabase.instance.client;

final peopleNearbyProvider =
    FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final me = _supabase.auth.currentUser;

  // Build the filter chain before calling order/limit (which return a
  // PostgrestTransformBuilder that no longer accepts filter methods).
  var filterBuilder = _supabase
      .from('users')
      .select()
      .neq('ghost_mode', true);

  if (me != null) {
    filterBuilder = filterBuilder.neq('id', me.id);
  }

  final rows = await filterBuilder
      .order('last_active_at', ascending: false)
      .limit(100);

  return (rows as List)
      .map((r) => UserProfile.fromJson(r as Map<String, dynamic>))
      .toList();
});

// Friendship state for the current user (to show pending / friends badges)
final _myFriendshipsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('friendships')
      .select('requester_id, addressee_id, status')
      .or('requester_id.eq.${me.id},addressee_id.eq.${me.id}');

  return (rows as List).cast<Map<String, dynamic>>();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PeopleNearbyScreen extends ConsumerStatefulWidget {
  const PeopleNearbyScreen({super.key});

  @override
  ConsumerState<PeopleNearbyScreen> createState() =>
      _PeopleNearbyScreenState();
}

class _PeopleNearbyScreenState extends ConsumerState<PeopleNearbyScreen> {
  PeopleFilter _activeFilter = PeopleFilter.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Optimistic per-user friendship state
  final Map<String, String> _localFriendState = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(peopleNearbyProvider);
    ref.invalidate(_myFriendshipsProvider);
  }

  List<UserProfile> _applyFilters(List<UserProfile> all) {
    var list = all;

    // Apply status filter
    switch (_activeFilter) {
      case PeopleFilter.outNow:
        list = list
            .where((u) => u.tonightStatus == TonightStatus.outNow)
            .toList();
        break;
      case PeopleFilter.goingOutSoon:
        list = list
            .where((u) => u.tonightStatus == TonightStatus.goingOutSoon)
            .toList();
        break;
      case PeopleFilter.ddTonight:
        // "DD Tonight" maps to stayingIn in the enum
        list = list
            .where((u) => u.tonightStatus == TonightStatus.stayingIn)
            .toList();
        break;
      case PeopleFilter.all:
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
              (u) => u.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return list;
  }

  int _countOutTonight(List<UserProfile> all) => all
      .where((u) =>
          u.tonightStatus == TonightStatus.outNow ||
          u.tonightStatus == TonightStatus.goingOutSoon)
      .length;

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleNearbyProvider);
    final friendshipsAsync = ref.watch(_myFriendshipsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'People Nearby',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            tooltip: 'Filter',
            onPressed: () {
              // The filter chips row is always visible; this is a visual cue.
            },
          ),
        ],
      ),
      body: peopleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _pink),
        ),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: _invalidateAll,
        ),
        data: (allPeople) {
          final filtered = _applyFilters(allPeople);
          final outCount = _countOutTonight(allPeople);

          final friendships = friendshipsAsync.when(
            data: (v) => v,
            loading: () => <Map<String, dynamic>>[],
            error: (_, __) => <Map<String, dynamic>>[],
          );
          final me = _supabase.auth.currentUser;

          return RefreshIndicator(
            onRefresh: () async => _invalidateAll(),
            color: _pink,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Count banner
                      _CountBanner(count: outCount),

                      // Filter chips
                      _FilterChipsRow(
                        active: _activeFilter,
                        onSelected: (f) =>
                            setState(() => _activeFilter = f),
                      ),

                      // Search bar
                      _SearchBar(controller: _searchController),
                    ],
                  ),
                ),

                // Empty state
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      icon: Icons.people_outline,
                      title: _activeFilter == PeopleFilter.all
                          ? 'No one nearby yet'
                          : 'No one matches this filter',
                      subtitle: 'Pull down to refresh or try a different filter.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final user = filtered[i];

                          // Determine friendship state
                          String friendState =
                              _localFriendState[user.id] ?? 'none';
                          if (friendState == 'none' && me != null) {
                            for (final f in friendships) {
                              final rid = f['requester_id'] as String;
                              final aid = f['addressee_id'] as String;
                              final involves = (rid == me.id &&
                                      aid == user.id) ||
                                  (aid == me.id && rid == user.id);
                              if (involves) {
                                final s = f['status'] as String;
                                if (s == 'accepted') {
                                  friendState = 'friends';
                                } else if (s == 'pending') {
                                  friendState = 'pending';
                                }
                                break;
                              }
                            }
                          }

                          return _PersonCard(
                            user: user,
                            friendState: friendState,
                            onChat: () =>
                                context.push('/chat/${user.id}'),
                            onAddFriend: () async {
                              setState(() =>
                                  _localFriendState[user.id] = 'pending');
                              try {
                                final currentUser =
                                    _supabase.auth.currentUser;
                                if (currentUser == null) return;
                                await _supabase
                                    .from('friendships')
                                    .insert({
                                  'requester_id': currentUser.id,
                                  'addressee_id': user.id,
                                  'status': 'pending',
                                });
                                ref.invalidate(_myFriendshipsProvider);
                              } catch (e) {
                                setState(() =>
                                    _localFriendState.remove(user.id));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Count banner
// ---------------------------------------------------------------------------

class _CountBanner extends StatelessWidget {
  final int count;
  const _CountBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count ${count == 1 ? 'person' : 'people'} out tonight',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips row
// ---------------------------------------------------------------------------

class _FilterChipsRow extends StatelessWidget {
  final PeopleFilter active;
  final ValueChanged<PeopleFilter> onSelected;

  const _FilterChipsRow({required this.active, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: PeopleFilter.values.map((f) {
            final isActive = f == active;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: isActive,
                onSelected: (_) => onSelected(f),
                selectedColor: _pink.withValues(alpha: 0.15),
                checkmarkColor: _pink,
                labelStyle: TextStyle(
                  color: isActive ? _pink : Colors.grey[700],
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isActive ? _pink : Colors.grey.shade300,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search, color: _pink),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => controller.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _pink, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Person card
// ---------------------------------------------------------------------------

class _PersonCard extends StatelessWidget {
  final UserProfile user;
  final String friendState; // 'none' | 'pending' | 'friends'
  final VoidCallback onChat;
  final VoidCallback onAddFriend;

  const _PersonCard({
    required this.user,
    required this.friendState,
    required this.onChat,
    required this.onAddFriend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _Avatar(avatarUrl: user.avatarUrl, radius: 28),
            const SizedBox(width: 14),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + age
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.age != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${user.age}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Home city
                  if (user.homeCity != null &&
                      user.homeCity!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_pin,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          user.homeCity!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Status badge
                  _StatusBadge(status: user.tonightStatus),
                  const SizedBox(height: 6),

                  // Vibe tags (first 3)
                  if (user.vibeTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: user.vibeTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _pink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _pink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Bio snippet
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Action buttons row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onChat,
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: 14),
                          label: const Text('Chat'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _pink,
                            side:
                                const BorderSide(color: _pink),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20)),
                            textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AddFriendButton(
                          friendState: friendState,
                          onAddFriend: onAddFriend,
                        ),
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

class _AddFriendButton extends StatelessWidget {
  final String friendState;
  final VoidCallback onAddFriend;

  const _AddFriendButton(
      {required this.friendState, required this.onAddFriend});

  @override
  Widget build(BuildContext context) {
    switch (friendState) {
      case 'friends':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Friends',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green),
          ),
        );
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Pending',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange),
          ),
        );
      default:
        return ElevatedButton.icon(
          onPressed: onAddFriend,
          icon: const Icon(Icons.person_add_alt_1, size: 14),
          label: const Text('Add Friend'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final TonightStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TonightStatus.outNow:
        color = Colors.green;
        text = 'Out Now';
        icon = Icons.local_bar;
        break;
      case TonightStatus.goingOutSoon:
        color = Colors.orange;
        text = 'Going Out Soon';
        icon = Icons.schedule;
        break;
      case TonightStatus.stayingIn:
        color = Colors.grey;
        text = 'Staying In';
        icon = Icons.home;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const _Avatar({this.avatarUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _pink.withValues(alpha: 0.1),
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(Icons.person, size: radius, color: _pink)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: _pink),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
