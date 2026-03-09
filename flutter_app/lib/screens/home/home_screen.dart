import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/localization_helper.dart';
import '../../i18n/translation_keys.dart';
import '../../models/user_profile.dart';
import '../../models/venue.dart';
import '../../models/swarm.dart';

final nearbyUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('users')
      .select()
      .neq('id', currentUser.id)
      .eq('ghost_mode', false)
      .order('updated_at', ascending: false)
      .limit(20);

  return (response as List).map((json) => UserProfile.fromJson(json)).toList();
});

final nearbyVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('bars')
      .select()
      .order('name')
      .limit(20);

  return (response as List).map((json) => Venue.fromJson(json)).toList();
});

final activeSwarmsProvider = FutureProvider<List<Swarm>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('swarms')
      .select()
      .gte('start_time', DateTime.now().toIso8601String())
      .order('start_time')
      .limit(20);

  return (response as List).map((json) => Swarm.fromJson(json)).toList();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        title: const Text('Barfliz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _PeopleTab(),
          _VenuesTab(),
          _SwarmsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFE91E63),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: ref.t(TranslationKeys.navExplore),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_on_outlined),
            activeIcon: const Icon(Icons.location_on),
            label: 'Venues',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_outlined),
            activeIcon: const Icon(Icons.groups),
            label: ref.t(TranslationKeys.navSwarms),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/discover'),
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.favorite),
        label: Text(ref.t('common.discover') ?? 'Discover'),
      ),
    );
  }
}

class _PeopleTab extends ConsumerWidget {
  const _PeopleTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(nearbyUsersProvider);

    return usersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(nearbyUsersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ref.t('location.nearby') ?? 'No one nearby yet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back when more people are going out!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nearbyUsersProvider);
          },
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) => _UserCard(user: users[index]),
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/chat/${user.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? const Icon(Icons.person, color: Color(0xFFE91E63))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (user.age != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${user.age}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: user.tonightStatus),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: const Color(0xFFE91E63),
                onPressed: () => context.push('/chat/${user.id}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        color: color.withOpacity(0.1),
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

class _VenuesTab extends ConsumerWidget {
  const _VenuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(nearbyVenuesProvider);

    return venuesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(nearbyVenuesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (venues) {
        if (venues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No venues nearby',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Venues will appear when you\'re in Darwin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nearbyVenuesProvider);
          },
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: venues.length,
            itemBuilder: (context, index) => _VenueCard(venue: venues[index]),
          ),
        );
      },
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/map'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (venue.photoUrl != null)
              Image.network(
                venue.photoUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 120,
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  child: const Icon(
                    Icons.local_bar,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                color: const Color(0xFFE91E63).withOpacity(0.1),
                child: const Center(
                  child: Icon(
                    Icons.local_bar,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (venue.rating != null) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          venue.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                  if (venue.address != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      venue.address!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (venue.category != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        venue.category!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFE91E63),
                        ),
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

class _SwarmsTab extends ConsumerWidget {
  const _SwarmsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swarmsAsync = ref.watch(activeSwarmsProvider);

    return swarmsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(activeSwarmsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (swarms) {
        if (swarms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ref.t(TranslationKeys.swarmsLoading) ?? 'No active swarms',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create one or join when friends start one!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/create-swarm'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Swarm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeSwarmsProvider);
          },
          color: const Color(0xFFE91E63),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: swarms.length,
            itemBuilder: (context, index) => _SwarmCard(swarm: swarms[index]),
          ),
        );
      },
    );
  }
}

class _SwarmCard extends StatelessWidget {
  final Swarm swarm;

  const _SwarmCard({required this.swarm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/swarms'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          swarm.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSwarmTime(swarm.startTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${swarm.maxAttendees} max',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                ],
              ),
              if (swarm.description != null && swarm.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  swarm.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (swarm.vibeTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: swarm.vibeTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatSwarmTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inMinutes < 60) {
      return 'Starts in ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Starts in ${diff.inHours}h';
    } else {
      return 'Starts ${time.day}/${time.month} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
