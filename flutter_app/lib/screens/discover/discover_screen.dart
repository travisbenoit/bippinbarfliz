import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../extensions/localization_extension.dart';
import '../../models/user_profile.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../widgets/app_loader.dart';

final discoverUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) return [];

  final response = await supabase
      .from('users')
      .select()
      .neq('id', currentUser.id)
      .eq('ghost_mode', false)
      .inFilter('tonight_status', ['out_now', 'going_out_soon'])
      .order('updated_at', ascending: false)
      .limit(50);

  return (response as List).map((json) => UserProfile.fromJson(json)).toList();
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final CardSwiperController _controller = CardSwiperController();
  Set<String> _vibeFilter = {}; // empty = show all

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final usersAsync = ref.watch(discoverUsersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(AppStrings.discoverTitle)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _vibeFilter.isNotEmpty ? const Color(0xFFE91E63) : null,
            ),
            tooltip: 'Filter by vibe',
            onPressed: () => _showFilterSheet(usersAsync.value ?? []),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const AppFullLoader(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(friendlyError(error, tag: 'Discover')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(discoverUsersProvider),
                child: Text(t(AppStrings.retry)),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return _buildEmptyState(t);
          }
          return _buildSwiper(users, t);
        },
      ),
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 50,
              color: Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t(AppStrings.discoverNoOne),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(AppStrings.discoverCheckBack),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(discoverUsersProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(t(AppStrings.discoverRefresh)),
          ),
        ],
      ),
    );
  }

  Widget _buildSwiper(List<UserProfile> users, String Function(String) t) {
    final filtered = _vibeFilter.isEmpty
        ? users
        : users.where((u) => u.vibeTags.any((v) => _vibeFilter.contains(v))).toList();

    if (filtered.isEmpty) return _buildEmptyState(t);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CardSwiper(
              controller: _controller,
              cardsCount: filtered.length,
              numberOfCardsDisplayed: filtered.length > 2 ? 3 : filtered.length,
              backCardOffset: const Offset(0, 40),
              padding: EdgeInsets.zero,
              onSwipe: (previousIndex, currentIndex, direction) {
                if (direction == CardSwiperDirection.right) {
                  _handleLike(filtered[previousIndex], superLike: false);
                } else if (direction == CardSwiperDirection.top) {
                  _handleLike(filtered[previousIndex], superLike: true);
                }
                return true;
              },
              onEnd: () => setState(() {}),
              cardBuilder: (context, index, _, __) =>
                  _UserCard(user: filtered[index]),
            ),
          ),
        ),
        _buildActionButtons(filtered),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButtons(List<UserProfile> users) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.close,
          color: Colors.red,
          size: 60,
          onTap: () => _controller.swipe(CardSwiperDirection.left),
        ),
        const SizedBox(width: 24),
        _ActionButton(
          icon: Icons.star,
          color: Colors.amber,
          size: 50,
          onTap: () => _controller.swipe(CardSwiperDirection.top),
        ),
        const SizedBox(width: 24),
        _ActionButton(
          icon: Icons.favorite,
          color: const Color(0xFFE91E63),
          size: 60,
          onTap: () => _controller.swipe(CardSwiperDirection.right),
        ),
      ],
    );
  }

  void _handleLike(UserProfile user, {required bool superLike}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(superLike
            ? '⭐ Super liked ${user.name}!'
            : '❤️ You liked ${user.name}!'),
        backgroundColor: superLike ? Colors.amber.shade700 : const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static const _allVibeTags = [
    'Happy Hour', 'Dance Party', 'Live Music', 'Craft Beer',
    'Sports', 'Karaoke', 'Chill Vibes', 'Rooftop', 'Late Night', 'Wine Down',
  ];

  void _showFilterSheet(List<UserProfile> users) {
    // Collect tags that actually appear in the current user list
    final available = _allVibeTags
        .where((t) => users.any((u) => u.vibeTags.contains(t)))
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text('Filter by Vibe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (_vibeFilter.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _vibeFilter = {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: Color(0xFFE91E63))),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (available.isEmpty ? _allVibeTags : available).map((tag) {
                    final selected = _vibeFilter.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setSheet(() {
                          setState(() {
                            selected ? _vibeFilter.remove(tag) : _vibeFilter.add(tag);
                          });
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE91E63)
                              : const Color(0xFFE91E63).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE91E63).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : const Color(0xFFE91E63),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_vibeFilter.isEmpty
                        ? 'Show All'
                        : 'Show ${_vibeFilter.length} vibe${_vibeFilter.length == 1 ? '' : 's'}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (user.avatarUrl != null)
              Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.age != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${user.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(context),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                      ),
                    ),
                  ],
                  if (user.vibeTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.vibeTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 100, color: Colors.white54),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (user.tonightStatus) {
      case TonightStatus.outNow:
        color = Colors.green;
        text = context.tr(AppStrings.homeOutNow);
        icon = Icons.local_bar;
        break;
      case TonightStatus.goingOutSoon:
        color = Colors.orange;
        text = context.tr(AppStrings.homeGoingOut2);
        icon = Icons.schedule;
        break;
      case TonightStatus.stayingIn:
        color = Colors.grey;
        text = context.tr(AppStrings.homeStayingIn);
        icon = Icons.home;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
