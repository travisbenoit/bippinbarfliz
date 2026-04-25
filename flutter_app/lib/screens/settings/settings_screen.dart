import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            iconColor: const Color(0xFFE91E63),
            title: 'Edit Profile',
            subtitle: 'Update your name, bio, photos',
            onTap: () => context.push('/edit-profile'),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            title: 'Appearance',
            subtitle: isDark ? 'Dark mode on' : 'Light mode on',
            trailing: Switch(
              value: isDark,
              activeThumbColor: const Color(0xFFE91E63),
              onChanged: (value) => ref.read(themeModeProvider.notifier).setDarkMode(value),
            ),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            iconColor: Colors.blue,
            title: 'Language',
            subtitle: 'Change app language',
            onTap: () => context.push('/language-settings'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'Social'),
          _SettingsTile(
            icon: Icons.people_outline,
            iconColor: Colors.teal,
            title: 'Friends',
            subtitle: 'Manage your friend list',
            onTap: () => context.push('/friends'),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () => context.push('/notifications-settings'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconColor: Colors.green,
            title: 'Safety & Security',
            subtitle: 'Ghost mode, privacy, blocked users',
            onTap: () => context.push('/safety-settings'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'Payments & Premium'),
          _SettingsTile(
            icon: Icons.diamond_outlined,
            iconColor: Colors.amber,
            title: 'Go Premium',
            subtitle: 'Unlock all features',
            onTap: () => context.push('/premium'),
          ),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.indigo,
            title: 'Payments',
            subtitle: 'Send money, LushCoin balance',
            onTap: () => context.push('/payments'),
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            iconColor: const Color(0xFFE91E63),
            title: 'My Gifts',
            subtitle: 'View received gifts',
            onTap: () => context.push('/gifts'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: 'More'),
          _SettingsTile(
            icon: Icons.history_outlined,
            iconColor: Colors.brown,
            title: 'Activity History',
            subtitle: 'Your nightlife history',
            onTap: () => context.push('/history'),
          ),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.deepOrange,
            title: 'Leaderboard & XP',
            subtitle: 'Your rank and achievements',
            onTap: () => context.push('/leaderboard'),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            iconColor: Colors.blueGrey,
            title: 'Help Center',
            subtitle: 'FAQs and support',
            onTap: () => _showHelpDialog(context),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => _showPrivacyDialog(context),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: Colors.grey,
            title: 'Terms of Service',
            onTap: () => _showTermsDialog(context),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) context.go('/signin');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Barfliz v1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help Center'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Q: How do I find people nearby?\nA: Use the People Nearby screen or the map to discover people going out tonight.'),
              SizedBox(height: 8),
              Text('Q: What is a Swarm?\nA: A Swarm is a group hangout you can create or join to meet people at a venue.'),
              SizedBox(height: 8),
              Text('Q: How do I earn XP?\nA: Check in at venues, send messages, join swarms, and send gifts to earn XP.'),
              SizedBox(height: 8),
              Text('Q: What is Ghost Mode?\nA: Ghost mode hides your location and profile from other users.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Your privacy is important to us. We collect only the data necessary to provide the Barfliz service. Your location is used to find nearby venues and people. We never sell your personal data to third parties.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text('By using Barfliz, you agree to our terms. You must be 21+ to use this app in the US or of legal drinking age in your country. You agree to use the app responsibly and not to harass other users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey) : null),
      onTap: onTap,
    );
  }
}
