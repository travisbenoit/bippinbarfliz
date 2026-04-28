import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../services/analytics_service.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum FriendshipStatus { pending, accepted, rejected }

class Friendship {
  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatus status;
  final DateTime createdAt;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    FriendshipStatus status;
    switch (json['status'] as String? ?? 'pending') {
      case 'accepted':
        status = FriendshipStatus.accepted;
        break;
      case 'rejected':
        status = FriendshipStatus.rejected;
        break;
      default:
        status = FriendshipStatus.pending;
    }
    return Friendship(
      id: json['id'] as String,
      requesterId: json['user_id'] as String,
      addresseeId: json['friend_id'] as String,
      status: status,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FriendWithProfile {
  final Friendship friendship;
  final UserProfile profile;

  const FriendWithProfile({required this.friendship, required this.profile});
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _supabase = Supabase.instance.client;

// Accepted friends — fetch friendship rows then hydrate user profiles
final acceptedFriendsProvider =
    FutureProvider.autoDispose<List<FriendWithProfile>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('friendships')
      .select()
      .eq('status', 'accepted')
      .or('user_id.eq.${me.id},friend_id.eq.${me.id}');

  final friendships = (rows as List)
      .map((r) => Friendship.fromJson(r as Map<String, dynamic>))
      .toList();

  if (friendships.isEmpty) return [];

  final otherIds = friendships
      .map((f) => f.requesterId == me.id ? f.addresseeId : f.requesterId)
      .toSet()
      .toList();

  final profiles = await _supabase
      .from('users')
      .select()
      .inFilter('id', otherIds);

  final profileMap = <String, UserProfile>{
    for (final p in (profiles as List))
      (p['id'] as String): UserProfile.fromJson(p as Map<String, dynamic>)
  };

  return friendships
      .where((f) {
        final otherId =
            f.requesterId == me.id ? f.addresseeId : f.requesterId;
        return profileMap.containsKey(otherId);
      })
      .map((f) {
        final otherId =
            f.requesterId == me.id ? f.addresseeId : f.requesterId;
        return FriendWithProfile(
            friendship: f, profile: profileMap[otherId]!);
      })
      .toList();
});

// Incoming pending requests (where I am addressee)
final pendingRequestsProvider =
    FutureProvider.autoDispose<List<FriendWithProfile>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('friendships')
      .select()
      .eq('friend_id', me.id)
      .eq('status', 'pending');

  final friendships = (rows as List)
      .map((r) => Friendship.fromJson(r as Map<String, dynamic>))
      .toList();

  if (friendships.isEmpty) return [];

  final requesterIds = friendships.map((f) => f.requesterId).toList();

  final profiles = await _supabase
      .from('users')
      .select()
      .inFilter('id', requesterIds);

  final profileMap = <String, UserProfile>{
    for (final p in (profiles as List))
      (p['id'] as String): UserProfile.fromJson(p as Map<String, dynamic>)
  };

  return friendships
      .where((f) => profileMap.containsKey(f.requesterId))
      .map((f) =>
          FriendWithProfile(friendship: f, profile: profileMap[f.requesterId]!))
      .toList();
});

// Suggested users (out tonight, not ghost, limit 20)
final suggestedUsersProvider =
    FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('users')
      .select()
      .neq('id', me.id)
      .neq('ghost_mode', true)
      .inFilter('tonight_status', ['out_now', 'going_out_soon'])
      .order('last_active_at', ascending: false)
      .limit(20);

  return (rows as List)
      .map((r) => UserProfile.fromJson(r as Map<String, dynamic>))
      .toList();
});

// All friendships for the current user (to know pending / accepted states)
final myFriendshipsProvider =
    FutureProvider.autoDispose<List<Friendship>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('friendships')
      .select()
      .or('user_id.eq.${me.id},friend_id.eq.${me.id}');

  return (rows as List)
      .map((r) => Friendship.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFE91E63);
  static const _bg = Color(0xFFFFF5F0);

  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _invalidateAll() {
    ref.invalidate(acceptedFriendsProvider);
    ref.invalidate(pendingRequestsProvider);
    ref.invalidate(suggestedUsersProvider);
    ref.invalidate(myFriendshipsProvider);
  }

  @override
  Widget build(BuildContext context) {
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
          'Friends',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _pink,
          labelColor: _pink,
          unselectedLabelColor: Colors.grey[600],
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Find Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsTab(onRefresh: _invalidateAll),
          _RequestsTab(onRefresh: _invalidateAll),
          _FindFriendsTab(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onRefresh: _invalidateAll,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 – Friends
// ---------------------------------------------------------------------------

class _FriendsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _FriendsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(acceptedFriendsProvider);

    return friendsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      ),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(acceptedFriendsProvider),
      ),
      data: (friends) {
        if (friends.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline,
            title: 'No friends yet',
            subtitle: 'Use "Find Friends" to connect with people nearby.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            itemBuilder: (context, i) =>
                _FriendCard(item: friends[i]),
          ),
        );
      },
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendWithProfile item;
  const _FriendCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final user = item.profile;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Avatar(avatarUrl: user.avatarUrl, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
                  _StatusDot(status: user.tonightStatus),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => context.push('/chat/${user.id}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE91E63),
                side: const BorderSide(color: Color(0xFFE91E63)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Message'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 – Requests
// ---------------------------------------------------------------------------

class _RequestsTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _RequestsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      ),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(pendingRequestsProvider),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyState(
            icon: Icons.mark_email_unread_outlined,
            title: 'No pending requests',
            subtitle: 'Friend requests will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, i) => _RequestCard(
              item: requests[i],
              onDecision: onRefresh,
            ),
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final FriendWithProfile item;
  final VoidCallback onDecision;

  const _RequestCard({required this.item, required this.onDecision});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _loading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client
          .from('friendships')
          .update({'status': status})
          .eq('id', widget.item.friendship.id);
      widget.onDecision();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.item.profile;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Avatar(avatarUrl: user.avatarUrl, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.age != null) ...[
                        const SizedBox(width: 6),
                        Text('${user.age}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _StatusDot(status: user.tonightStatus),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      user.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE91E63)),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus('accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                  elevation: 0,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus('rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  side: BorderSide(
                                      color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Decline'),
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

// ---------------------------------------------------------------------------
// Tab 3 – Find Friends
// ---------------------------------------------------------------------------

class _FindFriendsTab extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onRefresh;

  const _FindFriendsTab({
    required this.searchController,
    required this.searchQuery,
    required this.onRefresh,
  });

  @override
  ConsumerState<_FindFriendsTab> createState() => _FindFriendsTabState();
}

class _FindFriendsTabState extends ConsumerState<_FindFriendsTab> {
  // Tracks optimistic friendship state per user id
  final Map<String, String> _localState = {};

  @override
  Widget build(BuildContext context) {
    final suggestedAsync = ref.watch(suggestedUsersProvider);
    final myFriendshipsAsync = ref.watch(myFriendshipsProvider);

    return Column(
      children: [
        _SearchBar(controller: widget.searchController),
        Expanded(
          child: suggestedAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            ),
            error: (e, _) => _ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(suggestedUsersProvider),
            ),
            data: (users) {
              final filtered = widget.searchQuery.isEmpty
                  ? users
                  : users
                      .where((u) => u.name
                          .toLowerCase()
                          .contains(widget.searchQuery))
                      .toList();

              if (filtered.isEmpty) {
                return _EmptyState(
                  icon: Icons.search_off,
                  title: 'No one found',
                  subtitle: 'Try a different search or check back later.',
                );
              }

              final friendships =
                  myFriendshipsAsync.when(data: (v) => v, loading: () => <Friendship>[], error: (_, __) => <Friendship>[]);
              final me = _supabase.auth.currentUser;

              return RefreshIndicator(
                onRefresh: () async => widget.onRefresh(),
                color: const Color(0xFFE91E63),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final user = filtered[i];

                    // Determine friendship state
                    String friendState = _localState[user.id] ?? 'none';
                    if (friendState == 'none' && me != null) {
                      for (final f in friendships) {
                        final involves = (f.requesterId == me.id &&
                                f.addresseeId == user.id) ||
                            (f.addresseeId == me.id &&
                                f.requesterId == user.id);
                        if (involves) {
                          if (f.status == FriendshipStatus.accepted) {
                            friendState = 'friends';
                          } else if (f.status == FriendshipStatus.pending) {
                            friendState = 'pending';
                          }
                          break;
                        }
                      }
                    }

                    return _SuggestedUserCard(
                      user: user,
                      friendState: friendState,
                      onAddFriend: () async {
                        setState(() =>
                            _localState[user.id] = 'pending');
                        try {
                          final currentUser =
                              _supabase.auth.currentUser;
                          if (currentUser == null) return;
                          await _supabase
                              .from('friendships')
                              .insert({
                            'user_id': currentUser.id,
                            'friend_id': user.id,
                            'status': 'pending',
                          });
                          await AnalyticsService.instance.friendRequestSent(user.id);
                          ref.invalidate(myFriendshipsProvider);
                        } catch (e) {
                          setState(() =>
                              _localState.remove(user.id));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestedUserCard extends StatelessWidget {
  final UserProfile user;
  final String friendState; // 'none' | 'pending' | 'friends'
  final VoidCallback onAddFriend;

  const _SuggestedUserCard({
    required this.user,
    required this.friendState,
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
          children: [
            _Avatar(avatarUrl: user.avatarUrl, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (user.vibeTags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: user.vibeTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _FriendStateButton(
                friendState: friendState, onAddFriend: onAddFriend),
          ],
        ),
      ),
    );
  }
}

class _FriendStateButton extends StatelessWidget {
  final String friendState;
  final VoidCallback onAddFriend;

  const _FriendStateButton(
      {required this.friendState, required this.onAddFriend});

  @override
  Widget build(BuildContext context) {
    switch (friendState) {
      case 'friends':
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        return ElevatedButton(
          onPressed: onAddFriend,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
          child: const Text('Add Friend'),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
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
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFFE91E63)),
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
            borderSide:
                const BorderSide(color: Color(0xFFE91E63), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const _Avatar({this.avatarUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          const Color(0xFFE91E63).withValues(alpha: 0.1),
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(Icons.person,
              size: radius, color: const Color(0xFFE91E63))
          : null,
    );
  }
}

class _StatusDot extends StatelessWidget {
  final TonightStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    String label;

    switch (status) {
      case TonightStatus.outNow:
        dotColor = Colors.green;
        label = 'Out Now';
        break;
      case TonightStatus.goingOutSoon:
        dotColor = Colors.orange;
        label = 'Going Out Soon';
        break;
      case TonightStatus.stayingIn:
        dotColor = Colors.grey;
        label = 'Staying In';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
              fontSize: 11, color: dotColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

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
                color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: const Color(0xFFE91E63)),
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
            Text(
              'Something went wrong',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
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
                backgroundColor: const Color(0xFFE91E63),
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
