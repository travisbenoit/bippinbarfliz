import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../extensions/localization_extension.dart';
import '../../widgets/app_loader.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends ConsumerState<NotificationsSettingsScreen> {
  static const _brandPink = Color(0xFFE91E63);

  bool _messages = true;
  bool _friendRequests = true;
  bool _swarms = true;
  bool _gifts = true;
  bool _checkinReminders = false;
  bool _nearbyPeople = true;
  bool _safeArrival = true;
  bool _marketing = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final res = await supabase
          .from('push_subscriptions')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (res != null) {
        final prefs = res['preferences'] as Map<String, dynamic>? ?? {};
        setState(() {
          _messages = prefs['messages'] as bool? ?? true;
          _friendRequests = prefs['friend_requests'] as bool? ?? true;
          _swarms = prefs['swarms'] as bool? ?? true;
          _gifts = prefs['gifts'] as bool? ?? true;
          _checkinReminders = prefs['checkin_reminders'] as bool? ?? false;
          _nearbyPeople = prefs['nearby_people'] as bool? ?? true;
          _safeArrival = prefs['safe_arrival'] as bool? ?? true;
          _marketing = prefs['marketing'] as bool? ?? false;
        });
      }
    } catch (e, st) {
      debugPrint('[NotifSettings] Failed to load preferences: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(AppStrings.notifSettingsFailedLoad))),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final savedMsg = context.tr(AppStrings.notifSettingsSavedBanner);
    final errorMsg = context.tr(AppStrings.notifSettingsSaveError);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase.from('push_subscriptions').upsert({
        'user_id': currentUser.id,
        'preferences': {
          'messages': _messages,
          'friend_requests': _friendRequests,
          'swarms': _swarms,
          'gifts': _gifts,
          'checkin_reminders': _checkinReminders,
          'nearby_people': _nearbyPeople,
          'safe_arrival': _safeArrival,
          'marketing': _marketing,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(savedMsg), backgroundColor: _brandPink));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        title: Text(t(AppStrings.notifSettingsTitle), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: AppButtonLoader(color: _brandPink, size: 24),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(t(AppStrings.save), style: const TextStyle(color: _brandPink, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: _loading
          ? const AppFullLoader(color: _brandPink)
          : ListView(
              children: [
                _SectionHeader(title: t(AppStrings.notifSettingsSocial)),
                _NotifTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.blue,
                  title: t(AppStrings.notifMessages),
                  subtitle: t(AppStrings.notifMessagesSub),
                  value: _messages,
                  onChanged: (v) => setState(() => _messages = v),
                ),
                _NotifTile(
                  icon: Icons.person_add_outlined,
                  iconColor: Colors.teal,
                  title: t(AppStrings.notifFriendReq),
                  subtitle: t(AppStrings.notifFriendReqSub),
                  value: _friendRequests,
                  onChanged: (v) => setState(() => _friendRequests = v),
                ),
                _NotifTile(
                  icon: Icons.groups_outlined,
                  iconColor: const Color(0xFFE91E63),
                  title: t(AppStrings.notifSwarms),
                  subtitle: t(AppStrings.notifSwarmsSub),
                  value: _swarms,
                  onChanged: (v) => setState(() => _swarms = v),
                ),
                _NotifTile(
                  icon: Icons.card_giftcard_outlined,
                  iconColor: Colors.green,
                  title: t(AppStrings.notifGifts),
                  subtitle: t(AppStrings.notifGiftsSub),
                  value: _gifts,
                  onChanged: (v) => setState(() => _gifts = v),
                ),
                const Divider(height: 1),
                _SectionHeader(title: t(AppStrings.notifSettingsLocation)),
                _NotifTile(
                  icon: Icons.people_outline,
                  iconColor: Colors.orange,
                  title: t(AppStrings.notifNearbyFriends),
                  subtitle: t(AppStrings.notifNearbyFriendsSub),
                  value: _nearbyPeople,
                  onChanged: (v) => setState(() => _nearbyPeople = v),
                ),
                _NotifTile(
                  icon: Icons.local_bar_outlined,
                  iconColor: Colors.purple,
                  title: t(AppStrings.notifCheckins),
                  subtitle: t(AppStrings.notifCheckinsSub),
                  value: _checkinReminders,
                  onChanged: (v) => setState(() => _checkinReminders = v),
                ),
                _NotifTile(
                  icon: Icons.shield_outlined,
                  iconColor: Colors.green,
                  title: t(AppStrings.notifSafeArrival),
                  subtitle: t(AppStrings.notifSafeArrivalSub),
                  value: _safeArrival,
                  onChanged: (v) => setState(() => _safeArrival = v),
                ),
                const Divider(height: 1),
                _SectionHeader(title: t(AppStrings.notifSettingsOther)),
                _NotifTile(
                  icon: Icons.campaign_outlined,
                  iconColor: Colors.grey,
                  title: t(AppStrings.notifPromo),
                  subtitle: t(AppStrings.notifPromoSub),
                  value: _marketing,
                  onChanged: (v) => setState(() => _marketing = v),
                ),
                const SizedBox(height: 32),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.2),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        activeThumbColor: const Color(0xFFE91E63),
        activeTrackColor: const Color(0xFFE91E63).withValues(alpha: 0.3),
        onChanged: onChanged,
      ),
    );
  }
}
