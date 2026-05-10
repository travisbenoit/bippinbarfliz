import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../extensions/localization_extension.dart';
import '../../models/user_profile.dart';
import '../../services/analytics_service.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../services/notification_sender.dart';
import '../../widgets/app_loader.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class Follow {
  final String id;
  final String followerId;
  final String followedId;
  final DateTime createdAt;

  const Follow({
    required this.id,
    required this.followerId,
    required this.followedId,
    required this.createdAt,
  });

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String,
      followerId: json['user_id'] as String,
      followedId: json['friend_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class FollowWithProfile {
  final Follow follow;
  final UserProfile profile;
  const FollowWithProfile({required this.follow, required this.profile});
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _supabase = Supabase.instance.client;

// People I follow (user_id = me, status = accepted)
final followingProvider =
    FutureProvider.autoDispose<List<FollowWithProfile>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('friendships')
      .select()
      .eq('user_id', me.id)
      .eq('status', 'accepted');

  final follows =
      (rows as List).map((r) => Follow.fromJson(r as Map<String, dynamic>)).toList();
  if (follows.isEmpty) return [];

  final ids = follows.map((f) => f.followedId).toList();
  final profiles = await _supabase.from('users').select().inFilter('id', ids);
  final profileMap = <String, UserProfile>{
    for (final p in (profiles as List))
      (p['id'] as String): UserProfile.fromJson(p as Map<String, dynamic>)
  };

  return follows
      .where((f) => profileMap.containsKey(f.followedId))
      .map((f) => FollowWithProfile(follow: f, profile: profileMap[f.followedId]!))
      .toList();
});

// People who follow me (friend_id = me, status = accepted)
final followersProvider =
    FutureProvider.autoDispose<List<FollowWithProfile>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('friendships')
      .select()
      .eq('friend_id', me.id)
      .eq('status', 'accepted');

  final follows =
      (rows as List).map((r) => Follow.fromJson(r as Map<String, dynamic>)).toList();
  if (follows.isEmpty) return [];

  final ids = follows.map((f) => f.followerId).toList();
  final profiles = await _supabase.from('users').select().inFilter('id', ids);
  final profileMap = <String, UserProfile>{
    for (final p in (profiles as List))
      (p['id'] as String): UserProfile.fromJson(p as Map<String, dynamic>)
  };

  return follows
      .where((f) => profileMap.containsKey(f.followerId))
      .map((f) => FollowWithProfile(follow: f, profile: profileMap[f.followerId]!))
      .toList();
});

// Set of user IDs that I follow — fast lookup for Follow/Unfollow buttons
final myFollowingIdsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final me = _supabase.auth.currentUser;
  if (me == null) return {};
  final rows = await _supabase
      .from('friendships')
      .select('friend_id')
      .eq('user_id', me.id)
      .eq('status', 'accepted');
  return {for (final r in rows as List) r['friend_id'] as String};
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

// Search all non-ghost users by name
final searchUsersProvider =
    FutureProvider.autoDispose.family<List<UserProfile>, String>((ref, query) async {
  if (query.length < 2) return [];
  final me = _supabase.auth.currentUser;
  if (me == null) return [];

  final rows = await _supabase
      .from('users')
      .select()
      .neq('id', me.id)
      .neq('ghost_mode', true)
      .ilike('name', '%$query%')
      .limit(30);

  return (rows as List)
      .map((r) => UserProfile.fromJson(r as Map<String, dynamic>))
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
    ref.invalidate(followingProvider);
    ref.invalidate(followersProvider);
    ref.invalidate(myFollowingIdsProvider);
    ref.invalidate(suggestedUsersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr(AppStrings.friendsTitle),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _pink,
          labelColor: _pink,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: t(AppStrings.followFollowingTab)),
            Tab(text: t(AppStrings.followFollowersTab)),
            Tab(text: context.tr(AppStrings.friendsTabFind)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowingTab(onRefresh: _invalidateAll),
          _FollowersTab(onRefresh: _invalidateAll),
          _FindPeopleTab(
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
// Tab 1 – Following
// ---------------------------------------------------------------------------

class _FollowingTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _FollowingTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync = ref.watch(followingProvider);

    return followingAsync.when(
      loading: () => const AppFullLoader(),
      error: (e, _) => _ErrorState(
        message: friendlyError(e),
        onRetry: () => ref.invalidate(followingProvider),
      ),
      data: (following) {
        if (following.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline,
            title: context.tr(AppStrings.followNoFollowing),
            subtitle: context.tr(AppStrings.followNoFollowingSub),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: following.length,
            itemBuilder: (context, i) =>
                _FollowingCard(item: following[i], onRefresh: onRefresh),
          ),
        );
      },
    );
  }
}

class _FollowingCard extends ConsumerStatefulWidget {
  final FollowWithProfile item;
  final VoidCallback onRefresh;
  const _FollowingCard({required this.item, required this.onRefresh});

  @override
  ConsumerState<_FollowingCard> createState() => _FollowingCardState();
}

class _FollowingCardState extends ConsumerState<_FollowingCard> {
  bool _unfollowing = false;

  Future<void> _unfollow() async {
    setState(() => _unfollowing = true);
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', widget.item.follow.id);
      widget.onRefresh();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'Friends.unfollow');
    } finally {
      if (mounted) setState(() => _unfollowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final user = widget.item.profile;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserProfile(context, ref, user, isFollowing: true,
            onAction: widget.onRefresh),
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
                          child: Text(user.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (user.age != null) ...[
                          const SizedBox(width: 6),
                          Text('${user.age}',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    _StatusDot(status: user.tonightStatus),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(user.bio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => context.push('/chat/${user.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE91E63),
                      side: const BorderSide(color: Color(0xFFE91E63)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(context.tr(AppStrings.friendsMessage)),
                  ),
                  const SizedBox(width: 6),
                  _unfollowing
                      ? const AppButtonLoader(size: 18)
                      : OutlinedButton(
                          onPressed: _unfollow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          child: Text(t(AppStrings.followUnfollow)),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 – Followers
// ---------------------------------------------------------------------------

class _FollowersTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _FollowersTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followersAsync = ref.watch(followersProvider);
    final myIdsAsync = ref.watch(myFollowingIdsProvider);

    return followersAsync.when(
      loading: () => const AppFullLoader(),
      error: (e, _) => _ErrorState(
        message: friendlyError(e),
        onRetry: () => ref.invalidate(followersProvider),
      ),
      data: (followers) {
        if (followers.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline,
            title: context.tr(AppStrings.followNoFollowers),
            subtitle: context.tr(AppStrings.followNoFollowersSub),
          );
        }
        final myIds = myIdsAsync.value ?? {};
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: followers.length,
            itemBuilder: (context, i) => _FollowerCard(
              item: followers[i],
              iFollowBack: myIds.contains(followers[i].profile.id),
              onRefresh: onRefresh,
            ),
          ),
        );
      },
    );
  }
}

class _FollowerCard extends ConsumerStatefulWidget {
  final FollowWithProfile item;
  final bool iFollowBack;
  final VoidCallback onRefresh;
  const _FollowerCard(
      {required this.item, required this.iFollowBack, required this.onRefresh});

  @override
  ConsumerState<_FollowerCard> createState() => _FollowerCardState();
}

class _FollowerCardState extends ConsumerState<_FollowerCard> {
  late bool _following;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _following = widget.iFollowBack;
  }

  Future<void> _toggleFollow() async {
    setState(() => _loading = true);
    try {
      final me = _supabase.auth.currentUser;
      if (me == null) return;
      if (_following) {
        await _supabase
            .from('friendships')
            .delete()
            .eq('user_id', me.id)
            .eq('friend_id', widget.item.profile.id);
        setState(() => _following = false);
      } else {
        await _supabase.from('friendships').insert({
          'user_id': me.id,
          'friend_id': widget.item.profile.id,
          'status': 'accepted',
        });
        setState(() => _following = true);
        final profile = await _supabase
            .from('users')
            .select('name')
            .eq('id', me.id)
            .maybeSingle();
        final name = (profile?['name'] as String?)?.trim() ?? '';
        await NotificationSender.followStarted(
          toUserId: widget.item.profile.id,
          followerName: name.isEmpty ? 'Someone' : name,
        );
      }
      widget.onRefresh();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'Friends.followerToggle');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final user = widget.item.profile;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUserProfile(context, ref, user,
            isFollowing: _following, onAction: widget.onRefresh),
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
                          child: Text(user.name,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (user.age != null) ...[
                          const SizedBox(width: 6),
                          Text('${user.age}',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    _StatusDot(status: user.tonightStatus),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const AppButtonLoader(size: 18)
                  : _following
                      ? OutlinedButton(
                          onPressed: _toggleFollow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          child: Text(t(AppStrings.followFollowing)),
                        )
                      : ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            elevation: 0,
                          ),
                          child: Text(t(AppStrings.followFollowBack)),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 – Find People
// ---------------------------------------------------------------------------

class _FindPeopleTab extends ConsumerStatefulWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onRefresh;

  const _FindPeopleTab({
    required this.searchController,
    required this.searchQuery,
    required this.onRefresh,
  });

  @override
  ConsumerState<_FindPeopleTab> createState() => _FindPeopleTabState();
}

class _FindPeopleTabState extends ConsumerState<_FindPeopleTab> {
  // Local optimistic state so Follow button flips immediately
  final Map<String, bool> _localFollowing = {};

  @override
  Widget build(BuildContext context) {
    final myIdsAsync = ref.watch(myFollowingIdsProvider);
    final me = _supabase.auth.currentUser;

    final bool isSearching = widget.searchQuery.length >= 2;
    final usersAsync = isSearching
        ? ref.watch(searchUsersProvider(widget.searchQuery))
        : ref.watch(suggestedUsersProvider);

    return Column(
      children: [
        _SearchBar(controller: widget.searchController),
        Expanded(
          child: usersAsync.when(
            loading: () => const AppFullLoader(),
            error: (e, _) => _ErrorState(
              message: friendlyError(e),
              onRetry: () {
                if (isSearching) {
                  ref.invalidate(searchUsersProvider(widget.searchQuery));
                } else {
                  ref.invalidate(suggestedUsersProvider);
                }
              },
            ),
            data: (users) {
              final filtered = (!isSearching && widget.searchQuery.isNotEmpty)
                  ? users
                      .where((u) => u.name
                          .toLowerCase()
                          .contains(widget.searchQuery))
                      .toList()
                  : users;

              if (filtered.isEmpty) {
                return _EmptyState(
                  icon: Icons.search_off,
                  title: context.tr(AppStrings.friendsNoOneFound),
                  subtitle: context.tr(AppStrings.friendsNoOneFoundSub),
                );
              }

              final myIds = myIdsAsync.value ?? {};

              return RefreshIndicator(
                onRefresh: () async => widget.onRefresh(),
                color: const Color(0xFFE91E63),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final user = filtered[i];
                    final isFollowing = _localFollowing.containsKey(user.id)
                        ? _localFollowing[user.id]!
                        : myIds.contains(user.id);

                    return _SuggestedUserCard(
                      user: user,
                      isFollowing: isFollowing,
                      onTap: () => _showUserProfile(context, ref, user,
                          isFollowing: isFollowing,
                          onAction: () {
                            setState(() => _localFollowing[user.id] = !isFollowing);
                            widget.onRefresh();
                          }),
                      onToggleFollow: () async {
                        setState(() => _localFollowing[user.id] = !isFollowing);
                        try {
                          if (isFollowing) {
                            await _supabase
                                .from('friendships')
                                .delete()
                                .eq('user_id', me!.id)
                                .eq('friend_id', user.id);
                          } else {
                            await _supabase.from('friendships').insert({
                              'user_id': me!.id,
                              'friend_id': user.id,
                              'status': 'accepted',
                            });
                            await AnalyticsService.instance.friendRequestSent(user.id);
                            final profile = await _supabase
                                .from('users')
                                .select('name')
                                .eq('id', me.id)
                                .maybeSingle();
                            final name = (profile?['name'] as String?)?.trim() ?? '';
                            await NotificationSender.followStarted(
                              toUserId: user.id,
                              followerName: name.isEmpty ? 'Someone' : name,
                            );
                          }
                          ref.invalidate(myFollowingIdsProvider);
                        } catch (e) {
                          setState(() => _localFollowing[user.id] = isFollowing);
                          if (context.mounted) {
                            showErrorSnackBar(context, e, tag: 'Friends.follow');
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

class _SuggestedUserCard extends ConsumerWidget {
  final UserProfile user;
  final bool isFollowing;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;

  const _SuggestedUserCard({
    required this.user,
    required this.isFollowing,
    required this.onTap,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                    Text(user.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    _StatusDot(status: user.tonightStatus),
                    if (user.vibeTags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.vibeTags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFE91E63),
                                    fontWeight: FontWeight.w500)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isFollowing
                  ? OutlinedButton(
                      onPressed: onToggleFollow,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: Text(t(AppStrings.followFollowing)),
                    )
                  : ElevatedButton(
                      onPressed: onToggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        elevation: 0,
                      ),
                      child: Text(t(AppStrings.followFollow)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User profile bottom sheet
// ---------------------------------------------------------------------------

void _showUserProfile(
  BuildContext context,
  WidgetRef ref,
  UserProfile user, {
  bool isFollowing = false,
  VoidCallback? onAction,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _UserProfileSheet(
      user: user,
      isFollowing: isFollowing,
      onAction: onAction,
    ),
  );
}

class _UserProfileSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  final bool isFollowing;
  final VoidCallback? onAction;

  const _UserProfileSheet({
    required this.user,
    required this.isFollowing,
    this.onAction,
  });

  @override
  ConsumerState<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends ConsumerState<_UserProfileSheet> {
  static const _pink = Color(0xFFE91E63);
  bool _blocking = false;
  bool _actionLoading = false;
  late bool _following;

  @override
  void initState() {
    super.initState();
    _following = widget.isFollowing;
  }

  Future<void> _toggleFollow() async {
    setState(() => _actionLoading = true);
    try {
      final db = Supabase.instance.client;
      final me = db.auth.currentUser;
      if (me == null) return;

      if (_following) {
        await db
            .from('friendships')
            .delete()
            .eq('user_id', me.id)
            .eq('friend_id', widget.user.id);
        setState(() => _following = false);
      } else {
        await db.from('friendships').insert({
          'user_id': me.id,
          'friend_id': widget.user.id,
          'status': 'accepted',
        });
        final profile =
            await db.from('users').select('name').eq('id', me.id).maybeSingle();
        final name = (profile?['name'] as String?)?.trim() ?? '';
        await NotificationSender.followStarted(
          toUserId: widget.user.id,
          followerName: name.isEmpty ? 'Someone' : name,
        );
        setState(() => _following = true);
      }
      widget.onAction?.call();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'ProfileSheet.follow');
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _blockUser() async {
    final t = ref.read(tProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(AppStrings.blockConfirmTitle)),
        content: Text(t(AppStrings.blockConfirmMsg)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t(AppStrings.cancel))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t(AppStrings.block),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _blocking = true);
    try {
      final db = Supabase.instance.client;
      final me = db.auth.currentUser;
      if (me == null) return;

      await db.from('user_blocks').insert({
        'blocker_id': me.id,
        'blocked_id': widget.user.id,
      });
      widget.onAction?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e, tag: 'ProfileSheet.block');
        setState(() => _blocking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final user = widget.user;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            _Avatar(avatarUrl: user.avatarUrl, radius: 44),
            const SizedBox(height: 14),
            Text(user.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (user.age != null) ...[
              const SizedBox(height: 4),
              Text('${user.age} ${t(AppStrings.profileYearsOld)}',
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.6))),
            ],
            const SizedBox(height: 8),
            _StatusDot(status: user.tonightStatus),

            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(user.bio!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.7))),
            ],

            if (user.vibeTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: user.vibeTags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tag,
                        style: const TextStyle(
                            fontSize: 12,
                            color: _pink,
                            fontWeight: FontWeight.w500)),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                // Message button (always visible if following)
                if (_following) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/chat/${user.id}');
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(t(AppStrings.profileSendMessage)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Follow / Unfollow button
                Expanded(
                  child: _actionLoading
                      ? const Center(child: AppButtonLoader())
                      : _following
                          ? OutlinedButton(
                              onPressed: _toggleFollow,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(t(AppStrings.followUnfollow),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            )
                          : ElevatedButton.icon(
                              onPressed: _toggleFollow,
                              icon: const Icon(Icons.person_add_outlined,
                                  size: 18),
                              label: Text(t(AppStrings.followFollow)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pink,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                            ),
                ),

                const SizedBox(width: 10),

                // Block button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _blocking ? null : _blockUser,
                    icon: _blocking
                        ? const AppButtonLoader(color: Colors.red, size: 16)
                        : const Icon(Icons.block, size: 18, color: Colors.red),
                    label: Text(t(AppStrings.block),
                        style: const TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          hintText: context.tr(AppStrings.friendsSearchHintName),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE91E63)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => controller.clear(),
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15)),
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
      backgroundColor: const Color(0xFFE91E63).withValues(alpha: 0.1),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(Icons.person, size: radius, color: const Color(0xFFE91E63))
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
        label = context.tr(AppStrings.homeOutNow);
        break;
      case TonightStatus.goingOutSoon:
        dotColor = Colors.orange;
        label = context.tr(AppStrings.homeGoingOut2);
        break;
      case TonightStatus.stayingIn:
        dotColor = Colors.grey;
        label = context.tr(AppStrings.homeStayingIn);
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
        Text(label,
            style: TextStyle(
                fontSize: 11, color: dotColor, fontWeight: FontWeight.w500)),
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
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center),
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
            Text(context.tr(AppStrings.friendsSomethingWrong),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(context.tr(AppStrings.retry)),
            ),
          ],
        ),
      ),
    );
  }
}
