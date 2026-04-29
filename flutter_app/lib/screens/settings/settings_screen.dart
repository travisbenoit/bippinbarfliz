import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../i18n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          t(AppStrings.settingsTitle),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: t(AppStrings.settingsAccount)),
          _SettingsTile(
            icon: Icons.person_outline,
            iconColor: const Color(0xFFE91E63),
            title: t(AppStrings.settingsEditProfile),
            subtitle: t(AppStrings.settingsEditProfileSub),
            onTap: () => context.push('/edit-profile'),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            title: t(AppStrings.settingsAppearance),
            subtitle: isDark ? t(AppStrings.settingsDarkOn) : t(AppStrings.settingsLightOn),
            trailing: Switch(
              value: isDark,
              activeThumbColor: const Color(0xFFE91E63),
              onChanged: (value) => ref.read(themeModeProvider.notifier).setDarkMode(value),
            ),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            iconColor: Colors.blue,
            title: t(AppStrings.settingsLanguage),
            subtitle: t(AppStrings.settingsLanguageSub),
            onTap: () => context.push('/language-settings'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: t(AppStrings.settingsSocial)),
          _SettingsTile(
            icon: Icons.people_outline,
            iconColor: Colors.teal,
            title: t(AppStrings.settingsFriends),
            subtitle: t(AppStrings.settingsFriendsSub),
            onTap: () => context.push('/friends'),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: t(AppStrings.settingsNotifications),
            subtitle: t(AppStrings.settingsNotifsSub),
            onTap: () => context.push('/notifications-settings'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: t(AppStrings.settingsPrivacy)),
          _SettingsTile(
            icon: Icons.shield_outlined,
            iconColor: Colors.green,
            title: t(AppStrings.settingsSafety),
            subtitle: t(AppStrings.settingsSafetySub),
            onTap: () => context.push('/safety-settings'),
          ),
          _SettingsTile(
            icon: Icons.person_off_outlined,
            iconColor: Colors.blueGrey,
            title: t(AppStrings.settingsBlocked),
            subtitle: t(AppStrings.settingsBlockedSub),
            onTap: () => context.push('/blocked-users'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: t(AppStrings.settingsPayments)),
          _SettingsTile(
            icon: Icons.diamond_outlined,
            iconColor: Colors.amber,
            title: t(AppStrings.settingsPremium),
            subtitle: t(AppStrings.settingsPremiumSub),
            onTap: () => context.push('/premium'),
          ),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.indigo,
            title: t(AppStrings.settingsPaymentsTitle),
            subtitle: t(AppStrings.settingsPaymentsSub),
            onTap: () => context.push('/payments'),
          ),
          _SettingsTile(
            icon: Icons.card_giftcard_outlined,
            iconColor: const Color(0xFFE91E63),
            title: t(AppStrings.settingsMyGifts),
            subtitle: t(AppStrings.settingsMyGiftsSub),
            onTap: () => context.push('/gifts'),
          ),
          const Divider(height: 1),
          _SectionHeader(title: t(AppStrings.settingsMore)),
          _SettingsTile(
            icon: Icons.history_outlined,
            iconColor: Colors.brown,
            title: t(AppStrings.settingsHistory),
            subtitle: t(AppStrings.settingsHistorySub),
            onTap: () => context.push('/history'),
          ),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.deepOrange,
            title: t(AppStrings.settingsLeaderboard),
            subtitle: t(AppStrings.settingsLeaderboardSub),
            onTap: () => context.push('/leaderboard'),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            iconColor: Colors.blueGrey,
            title: t(AppStrings.settingsHelp),
            subtitle: t(AppStrings.settingsHelpSub),
            onTap: () => _showHelpDialog(context, t),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.grey,
            title: t(AppStrings.settingsPrivacyPolicy),
            subtitle: t(AppStrings.settingsPrivacySub),
            onTap: () => _showPrivacyDialog(context, t),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: Colors.grey,
            title: t(AppStrings.settingsTerms),
            onTap: () => _showTermsDialog(context, t),
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
                    title: Text(t(AppStrings.signOutTitle)),
                    content: Text(t(AppStrings.signOutConfirm)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(t(AppStrings.cancel)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(t(AppStrings.signOut),
                            style: const TextStyle(color: Colors.red)),
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
              label: Text(t(AppStrings.signOut),
                  style: const TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              t(AppStrings.version),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(AppStrings.helpTitle)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Frequently Asked Questions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Text(t(AppStrings.close)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(AppStrings.privacyTitle)),
        content: const Text(
          'Your privacy is important to us. We collect only the data necessary to provide the Barfliz service. Your location is used to find nearby venues and people. We never sell your personal data to third parties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(AppStrings.close)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(AppStrings.termsTitle)),
        content: const Text(
          'By using Barfliz, you agree to our terms. You must be 21+ to use this app in the US or of legal drinking age in your country. You agree to use the app responsibly and not to harass other users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(AppStrings.close)),
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
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }
}
