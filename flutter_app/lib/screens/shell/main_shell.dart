import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

const _brandPink = Color(0xFFE91E63);

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _MoreBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final current = navigationShell.currentIndex;
    final isMapActive = current == 1;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: navigationShell,

      // ── Centre FAB (Map) ──────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goBranch(1),
        backgroundColor: _brandPink,
        foregroundColor: Colors.white,
        elevation: isMapActive ? 8 : 4,
        shape: const CircleBorder(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isMapActive ? Icons.map : Icons.map_outlined,
            key: ValueKey(isMapActive),
            size: 26,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom bar with notch ─────────────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: surface,
        elevation: 12,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Left pair
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: t(AppStrings.navHome),
              isActive: current == 0,
              onTap: () => _goBranch(0),
              onSurface: onSurface,
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: t(AppStrings.navMessages),
              isActive: current == 2,
              onTap: () => _goBranch(2),
              onSurface: onSurface,
            ),
            // Gap for the FAB notch
            const Expanded(child: SizedBox()),
            // Right pair
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: t(AppStrings.navProfile),
              isActive: current == 3,
              onTap: () => _goBranch(3),
              onSurface: onSurface,
            ),
            _NavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view,
              label: t(AppStrings.navMore),
              isActive: false,
              onTap: () => _showMoreSheet(context),
              onSurface: onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single nav bar item ───────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color onSurface;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _brandPink : onSurface.withValues(alpha: 0.45);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── More bottom sheet ─────────────────────────────────────────────────────────

class _MoreBottomSheet extends ConsumerWidget {
  const _MoreBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final items = [
      (Icons.group_outlined,        t(AppStrings.moreFriends),       '/friends',     Colors.blue),
      (Icons.history_outlined,      t(AppStrings.moreHistory),       '/history',     Colors.purple),
      (Icons.payment_outlined,      t(AppStrings.morePayments),      '/payments',    Colors.green),
      (Icons.leaderboard_outlined,  t(AppStrings.moreLeaderboard),   '/leaderboard', Colors.amber),
      (Icons.nightlight_outlined,   t(AppStrings.moreNightRecap),    '/night-recap', _brandPink),
      (Icons.notifications_outlined,t(AppStrings.moreNotifications), '/notifications', Colors.orange),
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
                t(AppStrings.navMore),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final (icon, label, route, color) = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(route);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 26),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
