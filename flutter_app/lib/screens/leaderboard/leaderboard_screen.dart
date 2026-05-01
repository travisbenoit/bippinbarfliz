import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../extensions/localization_extension.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int totalXp;
  final int currentStreak;
  final int totalCheckins;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.totalXp,
    required this.currentStreak,
    required this.totalCheckins,
  });
}

class UserChallenge {
  final String id;
  final String challengeId;
  final String status;
  final int progress;
  final String challengeName;
  final String challengeDescription;
  final int xpReward;
  final int requirementCount;
  final String challengeType;

  UserChallenge({
    required this.id,
    required this.challengeId,
    required this.status,
    required this.progress,
    required this.challengeName,
    required this.challengeDescription,
    required this.xpReward,
    required this.requirementCount,
    required this.challengeType,
  });
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final supabase = Supabase.instance.client;

  final statsRows = await supabase
      .from('user_stats')
      .select('user_id, total_xp, current_streak, total_checkins')
      .order('total_xp', ascending: false)
      .limit(50);

  if ((statsRows as List).isEmpty) return [];

  final userIds = statsRows.map((r) => r['user_id'] as String).toList();

  final usersRows = await supabase
      .from('users')
      .select('id, name, avatar_url')
      .inFilter('id', userIds);

  final userMap = <String, Map<String, dynamic>>{
    for (final u in (usersRows as List))
      (u['id'] as String): u as Map<String, dynamic>
  };

  return statsRows.map((row) {
    final user = userMap[row['user_id'] as String] ?? {};
    return LeaderboardEntry(
      userId: row['user_id'] as String,
      userName: user['name'] as String? ?? 'Unknown',
      avatarUrl: user['avatar_url'] as String?,
      totalXp: (row['total_xp'] as num?)?.toInt() ?? 0,
      currentStreak: (row['current_streak'] as num?)?.toInt() ?? 0,
      totalCheckins: (row['total_checkins'] as num?)?.toInt() ?? 0,
    );
  }).toList();
});

final userChallengesProvider = FutureProvider<List<UserChallenge>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final rows = await supabase
      .from('user_challenges')
      .select('id, challenge_key, status, progress, target, reward_xp')
      .eq('user_id', currentUser.id);

  if ((rows as List).isEmpty) return [];

  final keys = rows.map((r) => r['challenge_key'] as String).toList();

  final defs = await supabase
      .from('challenge_definitions')
      .select('challenge_key, name, description')
      .inFilter('challenge_key', keys);

  final defMap = <String, Map<String, dynamic>>{
    for (final d in (defs as List))
      (d['challenge_key'] as String): d as Map<String, dynamic>
  };

  return rows.map((row) {
    final key = row['challenge_key'] as String;
    final def = defMap[key] ?? {};
    return UserChallenge(
      id: row['id'] as String,
      challengeId: key,
      status: row['status'] as String? ?? 'in_progress',
      progress: (row['progress'] as num?)?.toInt() ?? 0,
      challengeName: def['name'] as String? ?? key,
      challengeDescription: def['description'] as String? ?? '',
      xpReward: (row['reward_xp'] as num?)?.toInt() ?? 0,
      requirementCount: (row['target'] as num?)?.toInt() ?? 1,
      challengeType: '',
    );
  }).toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: _brandPink, size: 22),
            const SizedBox(width: 8),
            Text(
              t(AppStrings.leaderboardTitle),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _brandPink,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: _brandPink,
          indicatorWeight: 3,
          tabs: [
            Tab(text: t(AppStrings.leaderboardTab)),
            Tab(text: t(AppStrings.challengesTab)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LeaderboardTab(),
          _ChallengesTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leaderboard Tab
// ---------------------------------------------------------------------------

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final boardAsync = ref.watch(leaderboardProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return boardAsync.when(
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
              onPressed: () => ref.invalidate(leaderboardProvider),
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
        LeaderboardEntry? myEntry;
        if (currentUserId != null) {
          try {
            myEntry = entries.firstWhere((e) => e.userId == currentUserId);
          } catch (_) {
            myEntry = null;
          }
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(leaderboardProvider),
          color: _brandPink,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MyStatsCard(entry: myEntry),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isMe = entry.userId == currentUserId;
                    return _LeaderboardRow(
                      rank: index + 1,
                      entry: entry,
                      isCurrentUser: isMe,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MyStatsCard extends StatelessWidget {
  final LeaderboardEntry? entry;

  const _MyStatsCard({this.entry});

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brandPink.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: entry == null
            ? Center(
                child: Text(
                  context.tr(AppStrings.leaderboardSignInStats),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(AppStrings.leaderboardYourStats),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry!.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatBadge(
                        icon: '⚡',
                        value: '${entry!.totalXp}',
                        label: context.tr(AppStrings.leaderboardXp),
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: '🔥',
                        value: '${entry!.currentStreak} ${context.tr(AppStrings.leaderboardNightStreak)}',
                        label: '',
                        compact: true,
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: '📍',
                        value: '${entry!.totalCheckins}',
                        label: context.tr(AppStrings.leaderboardCheckIns),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final bool compact;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  static const _brandPink = Color(0xFFE91E63);

  Color _rankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.deepOrange.shade300;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? _brandPink.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: _brandPink.withValues(alpha: 0.3), width: 1.5)
            : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _rankColor(),
                ),
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: _brandPink.withValues(alpha: 0.1),
              backgroundImage: entry.avatarUrl != null
                  ? NetworkImage(entry.avatarUrl!)
                  : null,
              child: entry.avatarUrl == null
                  ? const Icon(Icons.person, size: 20, color: _brandPink)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.userName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.currentStreak}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                const Text(' 🔥  ', style: TextStyle(fontSize: 13)),
                Text(
                  '${entry.totalXp}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _brandPink,
                  ),
                ),
                const Text(' ⚡', style: TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Challenges Tab
// ---------------------------------------------------------------------------

class _ChallengesTab extends ConsumerWidget {
  const _ChallengesTab();

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final challengesAsync = ref.watch(userChallengesProvider);

    return challengesAsync.when(
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
              onPressed: () => ref.invalidate(userChallengesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
              ),
              child: Text(t(AppStrings.retry)),
            ),
          ],
        ),
      ),
      data: (challenges) {
        final totalXpEarned = challenges
            .where((c) => c.status == 'completed')
            .fold<int>(0, (sum, c) => sum + c.xpReward);

        if (challenges.isEmpty) {
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
                    Icons.emoji_events_outlined,
                    size: 40,
                    color: _brandPink,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t(AppStrings.leaderboardNoChallenges),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(AppStrings.leaderboardCompleteXp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(userChallengesProvider),
          color: _brandPink,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _XpEarnedBanner(totalXp: totalXpEarned),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverList.separated(
                  itemCount: challenges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _ChallengeCard(challenge: challenges[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _XpEarnedBanner extends StatelessWidget {
  final int totalXp;

  const _XpEarnedBanner({required this.totalXp});

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _brandPink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandPink.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalXp ${context.tr(AppStrings.leaderboardXpEarned)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _brandPink,
                ),
              ),
              Text(
                context.tr(AppStrings.leaderboardFromChallenges),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final UserChallenge challenge;

  const _ChallengeCard({required this.challenge});

  static const _brandPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    final isCompleted = challenge.status == 'completed';
    final progress = challenge.requirementCount > 0
        ? (challenge.progress / challenge.requirementCount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.challengeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.challengeDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _XpBadge(xp: challenge.xpReward),
                    const SizedBox(height: 6),
                    _StatusBadge(status: challenge.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : _brandPink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${challenge.progress}/${challenge.requirementCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
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

class _XpBadge extends StatelessWidget {
  final int xp;

  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '+$xp XP',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE91E63),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    final color = isCompleted ? Colors.green : Colors.orange;
    final label = isCompleted ? context.tr(AppStrings.challengeCompleted) : context.tr(AppStrings.challengeInProgress);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
