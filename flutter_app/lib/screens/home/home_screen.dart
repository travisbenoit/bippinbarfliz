import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../models/swarm.dart';
import '../../widgets/first_run_tour.dart';
import '../../extensions/localization_extension.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final nearbyUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('users')
      .select()
      .neq('id', currentUser.id)
      .neq('ghost_mode', true)
      .inFilter('tonight_status', ['out_now', 'going_out_soon'])
      .order('last_active_at', ascending: false)
      .limit(50);

  return (response as List).map((json) => UserProfile.fromJson(json)).toList();
});

final nearbyVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('venues')
      .select()
      .eq('is_active', true)
      .order('name')
      .limit(50);

  return (response as List).map((json) => Venue.fromJson(json)).toList();
});

final activeSwarmsProvider = FutureProvider<List<Swarm>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('swarms')
      .select()
      .eq('status', 'active')
      .order('start_time')
      .limit(20);

  return (response as List).map((json) => Swarm.fromJson(json)).toList();
});

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return null;

  final response = await supabase
      .from('users')
      .select()
      .eq('id', currentUser.id)
      .maybeSingle();

  return response;
});

final userStatsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return null;

  final response = await supabase
      .from('user_stats')
      .select()
      .eq('user_id', currentUser.id)
      .maybeSingle();

  return response;
});

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _brandPink = Color(0xFFE91E63);

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDdTonight = false;
  bool _ddLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDdStatus();
  }

  Future<void> _loadDdStatus() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    final row = await supabase
        .from('users')
        .select('is_dd_tonight')
        .eq('id', currentUser.id)
        .maybeSingle();
    if (row != null && mounted) {
      setState(() {
        _isDdTonight = (row['is_dd_tonight'] as bool?) ?? false;
      });
    }
  }

  Future<void> _toggleDd(bool value) async {
    setState(() {
      _isDdTonight = value;
      _ddLoading = true;
    });
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    await supabase
        .from('users')
        .update({'is_dd_tonight': value})
        .eq('id', currentUser.id);
    if (mounted) setState(() => _ddLoading = false);
  }

  Future<void> _checkInSafeArrival() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    await supabase.from('safe_arrivals').insert({
      'user_id': currentUser.id,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'safe',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(AppStrings.homeSafeArrivalRecorded)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _StatusBottomSheet(
        onStatusChanged: () {
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(nearbyUsersProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tProvider);
    final userAsync = ref.watch(currentUserProfileProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final usersAsync = ref.watch(nearbyUsersProvider);
    final venuesAsync = ref.watch(nearbyVenuesProvider);
    final swarmsAsync = ref.watch(activeSwarmsProvider);

    return Stack(
      children: [
        Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: _brandPink,
        onRefresh: () async {
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(userStatsProvider);
          ref.invalidate(nearbyUsersProvider);
          ref.invalidate(nearbyVenuesProvider);
          ref.invalidate(activeSwarmsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Profile Card
              _UserProfileCard(
                userAsync: userAsync,
                onEditStatus: _showStatusBottomSheet,
              ),
              const SizedBox(height: 16),

              // 2. XP / Leaderboard Banner
              _XpBanner(statsAsync: statsAsync),
              const SizedBox(height: 16),

              // 3. Quick Actions
              _QuickActionsGrid(),
              const SizedBox(height: 20),

              // 4. Social Stats
              _SocialStatsRow(
                usersAsync: usersAsync,
                venuesAsync: venuesAsync,
                swarmsAsync: swarmsAsync,
              ),
              const SizedBox(height: 20),

              // 5. Tonight's Scene
              _TonightsSceneSection(usersAsync: usersAsync),
              const SizedBox(height: 20),

              // 6. Popular Venues
              _PopularVenuesSection(venuesAsync: venuesAsync),
              const SizedBox(height: 20),

              // 7. Active Swarms
              _ActiveSwarmsSection(swarmsAsync: swarmsAsync),
              const SizedBox(height: 20),

              // 8. DD Mode Toggle
              _DdModeToggle(
                value: _isDdTonight,
                loading: _ddLoading,
                onChanged: _toggleDd,
              ),
              const SizedBox(height: 16),

              // 9. Safe Arrival Button
              _SafeArrivalButton(onTap: _checkInSafeArrival),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
        ),
        const FirstRunTour(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barfliz',
            style: TextStyle(
              color: _brandPink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            context.tr(AppStrings.homeAppTagline),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        // Messages with badge — go() switches to the Messages tab
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.go('/messages'),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _brandPink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User Profile Card
// ---------------------------------------------------------------------------

class _UserProfileCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> userAsync;
  final VoidCallback onEditStatus;

  const _UserProfileCard({required this.userAsync, required this.onEditStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Text(
          context.tr(AppStrings.homeCouldNotLoadProfile),
          style: const TextStyle(color: Colors.white),
        ),
        data: (userData) {
          if (userData == null) {
            return Text(
              context.tr(AppStrings.homeProfileNotFound),
              style: const TextStyle(color: Colors.white),
            );
          }

          final name = userData['name'] as String? ?? 'User';
          final avatarUrl = userData['avatar_url'] as String?;
          final statusStr = userData['tonight_status'] as String? ?? 'staying_in';
          final status = TonightStatus.fromString(statusStr);
          final vibeTags = (userData['vibe_tags'] as List<dynamic>?)?.cast<String>() ?? [];
          final favDrinks = (userData['favorite_drinks'] as List<dynamic>?)?.cast<String>() ?? [];
          final lushCoins = userData['lush_coin_balance'] as int? ?? 0;
          final isPremium = userData['is_premium'] as bool? ?? false;

          Color dotColor;
          String statusLabel;
          switch (status) {
            case TonightStatus.outNow:
              dotColor = Colors.greenAccent;
              statusLabel = context.tr(AppStrings.homeOutNow);
              break;
            case TonightStatus.goingOutSoon:
              dotColor = Colors.orangeAccent;
              statusLabel = context.tr(AppStrings.homeGoingOut2);
              break;
            case TonightStatus.stayingIn:
              dotColor = Colors.white54;
              statusLabel = context.tr(AppStrings.homeStayingIn);
              break;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onEditStatus,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      context.tr(AppStrings.homeEditStatus),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ProfileStat(label: context.tr(AppStrings.homeVibes), value: vibeTags.length.toString()),
                  const SizedBox(width: 24),
                  _ProfileStat(label: context.tr(AppStrings.homeDrinks), value: favDrinks.length.toString()),
                  const SizedBox(width: 24),
                  _ProfileStat(label: context.tr(AppStrings.homeLushCoins), value: lushCoins.toString()),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// XP / Leaderboard Banner
// ---------------------------------------------------------------------------

class _XpBanner extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> statsAsync;

  const _XpBanner({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/leaderboard'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: statsAsync.when(
          loading: () => const Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          ),
          error: (_, __) => _XpBannerContent(totalXp: 0, streak: 0, checkins: 0),
          data: (stats) => _XpBannerContent(
            totalXp: stats?['total_xp'] as int? ?? 0,
            streak: stats?['current_streak'] as int? ?? 0,
            checkins: stats?['total_checkins'] as int? ?? 0,
          ),
        ),
      ),
    );
  }
}

class _XpBannerContent extends StatelessWidget {
  final int totalXp;
  final int streak;
  final int checkins;

  const _XpBannerContent({
    required this.totalXp,
    required this.streak,
    required this.checkins,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(AppStrings.homeYourStats),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$totalXp XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _XpStat(label: context.tr(AppStrings.homeStreak), value: '${streak}d', icon: Icons.local_fire_department),
        const SizedBox(width: 16),
        _XpStat(label: context.tr(AppStrings.homeCheckins), value: '$checkins', icon: Icons.check_circle_outline),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
      ],
    );
  }
}

class _XpStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _XpStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Grid
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.groups_2, label: context.tr(AppStrings.homeQuickCreateSwarm), route: '/create-swarm'),
      _QuickAction(icon: Icons.send, label: context.tr(AppStrings.homeQuickSendMessage), route: '/messages', isTab: true),
      _QuickAction(icon: Icons.map_outlined, label: context.tr(AppStrings.homeQuickFindVenues), route: '/map', isTab: true),
      _QuickAction(icon: Icons.people_outline, label: context.tr(AppStrings.homeQuickFindPeople), route: '/people-nearby'),
      _QuickAction(icon: Icons.history, label: context.tr(AppStrings.homeQuickViewHistory), route: '/history'),
      _QuickAction(icon: Icons.group_outlined, label: context.tr(AppStrings.homeQuickFriends), route: '/friends'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(AppStrings.homeQuickActions),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickActionTile(action: action);
          },
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final bool isTab;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    this.isTab = false,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => action.isTab ? context.go(action.route) : context.push(action.route),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _brandPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: _brandPink, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Social Stats Row
// ---------------------------------------------------------------------------

class _SocialStatsRow extends StatelessWidget {
  final AsyncValue<List<UserProfile>> usersAsync;
  final AsyncValue<List<Venue>> venuesAsync;
  final AsyncValue<List<Swarm>> swarmsAsync;

  const _SocialStatsRow({
    required this.usersAsync,
    required this.venuesAsync,
    required this.swarmsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final usersList = usersAsync.when(data: (v) => v, loading: () => <UserProfile>[], error: (_, __) => <UserProfile>[]);
    final venuesList = venuesAsync.when(data: (v) => v, loading: () => <Venue>[], error: (_, __) => <Venue>[]);
    final swarmsList = swarmsAsync.when(data: (v) => v, loading: () => <Swarm>[], error: (_, __) => <Swarm>[]);

    final totalPeople = usersList.length;
    final outNow = usersList.where((u) => u.tonightStatus == TonightStatus.outNow).length;
    final venues = venuesList.length;
    final swarms = swarmsList.length;

    return Row(
      children: [
        _StatChip(
          icon: Icons.people,
          label: context.tr(AppStrings.homeStatNearby),
          value: '$totalPeople',
          color: Colors.blue,
          onTap: () => context.push('/people-nearby'),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.local_bar,
          label: context.tr(AppStrings.homeStatOutNow),
          value: '$outNow',
          color: Colors.green,
          onTap: () => context.push('/people-nearby'),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.location_on,
          label: context.tr(AppStrings.homeStatVenues),
          value: '$venues',
          color: _brandPink,
          onTap: () => context.push('/map'),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.groups,
          label: context.tr(AppStrings.homeSwarms),
          value: '$swarms',
          color: Colors.orange,
          onTap: () => context.push('/swarms'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tonight's Scene
// ---------------------------------------------------------------------------

class _TonightsSceneSection extends StatelessWidget {
  final AsyncValue<List<UserProfile>> usersAsync;

  const _TonightsSceneSection({required this.usersAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr(AppStrings.homeSceneTonight),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/people-nearby'),
              child: Text(
                context.tr(AppStrings.homeSeeAll),
                style: const TextStyle(color: _brandPink, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        usersAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _brandPink),
          ),
          error: (_, __) => Text(context.tr(AppStrings.homeCouldNotLoadPeople)),
          data: (users) {
            final outNowUsers = users
                .where((u) => u.tonightStatus == TonightStatus.outNow)
                .take(5)
                .toList();
            if (outNowUsers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    context.tr(AppStrings.homeNoOneTonightScene),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: outNowUsers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final user = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        onTap: () => context.push('/people-nearby'),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: _brandPink.withValues(alpha: 0.1),
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? const Icon(Icons.person, color: _brandPink, size: 22)
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: user.vibeTags.isNotEmpty
                            ? Text(
                                user.vibeTags.first,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr(AppStrings.homeOutNow),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < outNowUsers.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Popular Venues Section
// ---------------------------------------------------------------------------

class _PopularVenuesSection extends StatelessWidget {
  final AsyncValue<List<Venue>> venuesAsync;

  const _PopularVenuesSection({required this.venuesAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr(AppStrings.homePopularVenues),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/map'),
              child: Text(
                context.tr(AppStrings.homeSeeAll),
                style: const TextStyle(color: _brandPink, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        venuesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _brandPink)),
          error: (_, __) => Text(context.tr(AppStrings.homeCouldNotLoadVenues)),
          data: (venues) {
            final top = venues.take(5).toList();
            if (top.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(context.tr(AppStrings.homeNoVenuesFound)),
                ),
              );
            }
            return SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: top.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _VenueTile(venue: top[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VenueTile extends StatelessWidget {
  final Venue venue;

  const _VenueTile({required this.venue});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/map'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (venue.photoUrl != null)
              Image.network(
                venue.photoUrl!,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  color: _brandPink.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(Icons.local_bar, color: _brandPink, size: 32),
                  ),
                ),
              )
            else
              Container(
                height: 90,
                color: _brandPink.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(Icons.local_bar, color: _brandPink, size: 32),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (venue.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      venue.category!,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                  if (venue.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final full = i < (venue.rating ?? 0).floor();
                          return Icon(
                            full ? Icons.star : Icons.star_border,
                            size: 12,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          venue.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
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
// Active Swarms Section
// ---------------------------------------------------------------------------

class _ActiveSwarmsSection extends StatelessWidget {
  final AsyncValue<List<Swarm>> swarmsAsync;

  const _ActiveSwarmsSection({required this.swarmsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr(AppStrings.homeActiveSwarms),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/swarms'),
              child: Text(
                context.tr(AppStrings.homeSeeAll),
                style: const TextStyle(color: _brandPink, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        swarmsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: _brandPink)),
          error: (_, __) => Text(context.tr(AppStrings.homeCouldNotLoadSwarms)),
          data: (swarms) {
            if (swarms.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.groups_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(AppStrings.homeNoActiveSwarmsLong),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/create-swarm'),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.tr(AppStrings.homeQuickCreateSwarm)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final top = swarms.take(5).toList();
            return Column(
              children: top.map((swarm) => _SwarmTile(swarm: swarm)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SwarmTile extends StatelessWidget {
  final Swarm swarm;

  const _SwarmTile({required this.swarm});

  String _formatTime(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);
    if (diff.inMinutes < 60) {
      return '${context.tr(AppStrings.swarmsStartsInMinutes)} ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${context.tr(AppStrings.swarmsStartsInMinutes)} ${diff.inHours}h';
    } else {
      return '${time.day}/${time.month} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => context.push('/swarms'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_brandPink, Color(0xFFFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups, color: Colors.white, size: 22),
        ),
        title: Text(
          swarm.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (swarm.description != null && swarm.description!.isNotEmpty)
              Text(
                swarm.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 2),
            Text(
              _formatTime(context, swarm.startTime),
              style: const TextStyle(fontSize: 11, color: _brandPink, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _brandPink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${swarm.maxAttendees} ${context.tr(AppStrings.homeMaxAttendees)}',
            style: const TextStyle(
              color: _brandPink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DD Mode Toggle
// ---------------------------------------------------------------------------

class _DdModeToggle extends StatelessWidget {
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _DdModeToggle({
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🚗', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(AppStrings.homeDdToggleTitle),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  context.tr(AppStrings.homeDdToggleSub),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ),
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                )
              : Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.green,
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Safe Arrival Button
// ---------------------------------------------------------------------------

class _SafeArrivalButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SafeArrivalButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.shield_outlined, color: _brandPink),
        label: Text(
          context.tr(AppStrings.homeCheckInSafeArrival),
          style: const TextStyle(color: _brandPink, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _brandPink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Bottom Sheet
// ---------------------------------------------------------------------------

class _StatusBottomSheet extends ConsumerStatefulWidget {
  final VoidCallback onStatusChanged;

  const _StatusBottomSheet({required this.onStatusChanged});

  @override
  ConsumerState<_StatusBottomSheet> createState() => _StatusBottomSheetState();
}

class _StatusBottomSheetState extends ConsumerState<_StatusBottomSheet> {
  TonightStatus? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    final row = await supabase
        .from('users')
        .select('tonight_status')
        .eq('id', uid)
        .maybeSingle();
    if (row != null && mounted) {
      setState(() {
        _selected = TonightStatus.fromString(row['tonight_status'] as String? ?? 'staying_in');
      });
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    final supabase = Supabase.instance.client;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    await supabase.from('users').update({'tonight_status': _selected!.toDbString()}).eq('id', uid);
    widget.onStatusChanged();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final options = [
      (TonightStatus.outNow, t(AppStrings.homeOutNow), Colors.green, Icons.local_bar),
      (TonightStatus.goingOutSoon, t(AppStrings.homeGoingOut2), Colors.orange, Icons.schedule),
      (TonightStatus.stayingIn, t(AppStrings.homeStayingIn), Colors.grey, Icons.home_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                t(AppStrings.homeUpdateStatus),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final (status, label, color, icon) = opt;
            final selected = _selected == status;
            return GestureDetector(
              onTap: () => setState(() => _selected = status),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: selected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? color : Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(Icons.check_circle, color: color, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(t(AppStrings.homeSaveStatus), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

