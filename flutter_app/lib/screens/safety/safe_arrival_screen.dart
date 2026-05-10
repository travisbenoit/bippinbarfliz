import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../extensions/localization_extension.dart';
import '../../widgets/app_loader.dart';

class SafeArrivalScreen extends ConsumerStatefulWidget {
  const SafeArrivalScreen({super.key});

  @override
  ConsumerState<SafeArrivalScreen> createState() => _SafeArrivalScreenState();
}

class _SafeArrivalScreenState extends ConsumerState<SafeArrivalScreen> {
  static const _brandPink = Color(0xFFE91E63);

  List<Map<String, dynamic>> _safeArrivals = [];
  List<Map<String, dynamic>> _safetyFriends = [];
  bool _loading = true;
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final arrivals = await supabase
          .from('safe_arrivals')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(10);

      final friendRows = await supabase
          .from('safety_friends')
          .select('*, friend:users!safety_friends_friend_id_fkey(id, name, avatar_url)')
          .eq('user_id', currentUser.id);

      setState(() {
        _safeArrivals = List<Map<String, dynamic>>.from(arrivals as List);
        _safetyFriends = List<Map<String, dynamic>>.from(friendRows as List);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkInSafe() async {
    setState(() => _checkingIn = true);
    final messenger = ScaffoldMessenger.of(context);
    final failMsg = context.tr(AppStrings.safeArrivalFailedRecord);
    final recordedTitle = context.tr(AppStrings.safeArrivalRecordedTitle);
    final notifyMsg = context.tr(AppStrings.safeArrivalNotifyMsg);
    final greatLabel = context.tr(AppStrings.safeArrivalGreat);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase.from('safe_arrivals').insert({
        'user_id': currentUser.id,
        'status': 'safe',
        'location_note': 'Home',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  recordedTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  notifyMsg,
                  style: const TextStyle(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(greatLabel, style: const TextStyle(color: _brandPink)),
              ),
            ],
          ),
        );
        _loadData();
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(failMsg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  Future<void> _callEmergency(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showAddFriendDialog() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    final messenger = ScaffoldMessenger.of(context);
    final addedMsg = context.tr(AppStrings.safeArrivalFriendAdded);
    final dialogTitle = context.tr(AppStrings.safeArrivalAddFriendDialog);
    final searchHint = context.tr(AppStrings.safeArrivalSearchHint);
    final addLabel = context.tr(AppStrings.safeArrivalAddBtn);
    final cancelLabel = context.tr(AppStrings.cancel);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (q) async {
                  if (q.length < 2) return;
                  final supabase = Supabase.instance.client;
                  final res = await supabase
                      .from('users')
                      .select('id, name, avatar_url')
                      .ilike('name', '%$q%')
                      .limit(5);
                  setLocal(() => results = List<Map<String, dynamic>>.from(res as List));
                },
              ),
              const SizedBox(height: 12),
              ...results.map((u) => ListTile(
                    leading: CircleAvatar(
                      backgroundImage: u['avatar_url'] != null ? NetworkImage(u['avatar_url'] as String) : null,
                      child: u['avatar_url'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(u['name'] as String),
                    trailing: TextButton(
                      onPressed: () async {
                        final supabase = Supabase.instance.client;
                        final currentUser = supabase.auth.currentUser;
                        if (currentUser == null) return;
                        await supabase.from('safety_friends').insert({
                          'user_id': currentUser.id,
                          'friend_id': u['id'],
                        });
                        Navigator.pop(ctx);
                        _loadData();
                        if (mounted) {
                          messenger.showSnackBar(SnackBar(content: Text(addedMsg), backgroundColor: _brandPink));
                        }
                      },
                      child: Text(addLabel, style: const TextStyle(color: _brandPink)),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(cancelLabel)),
          ],
        ),
      ),
    );
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
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: _brandPink, size: 22),
            const SizedBox(width: 8),
            Text(t(AppStrings.safeArrivalTitle), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _loading
          ? const AppFullLoader(color: _brandPink)
          : RefreshIndicator(
              color: _brandPink,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExplanationCard(),
                    const SizedBox(height: 16),
                    _buildCheckInButton(),
                    const SizedBox(height: 20),
                    _buildSafetyFriendsSection(),
                    const SizedBox(height: 20),
                    _buildRecentArrivalsSection(),
                    const SizedBox(height: 20),
                    _buildEmergencySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(AppStrings.safeArrivalStaySafe), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  context.tr(AppStrings.safeArrivalLetFriendsKnow),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _checkingIn ? null : _checkInSafe,
        icon: _checkingIn
            ? const AppButtonLoader()
            : const Text('🏠', style: TextStyle(fontSize: 20)),
        label: Text(
          _checkingIn ? context.tr(AppStrings.safeArrivalRecordingState) : context.tr(AppStrings.safeArrivalIAmHome),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
      ),
    );
  }

  Widget _buildSafetyFriendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr(AppStrings.safeArrivalFriendsSection), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.add, size: 16, color: _brandPink),
              label: Text(context.tr(AppStrings.safeArrivalAddBtn), style: const TextStyle(color: _brandPink)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_safetyFriends.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.person_add_outlined),
                const SizedBox(width: 12),
                Text(context.tr(AppStrings.safeArrivalAddFriendPrompt)),
              ],
            ),
          )
        else
          ...(_safetyFriends.map((f) {
            final friend = f['friend'] as Map<String, dynamic>?;
            final name = friend?['name'] as String? ?? 'Friend';
            final avatarUrl = friend?['avatar_url'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  backgroundColor: _brandPink.withValues(alpha: 0.1),
                  child: avatarUrl == null
                      ? Text(name[0].toUpperCase(), style: const TextStyle(color: _brandPink))
                      : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(context.tr(AppStrings.safeArrivalWillNotify), style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.shield_outlined, color: Colors.green, size: 18),
              ),
            );
          })),
      ],
    );
  }

  Widget _buildRecentArrivalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr(AppStrings.safeArrivalRecentSection), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_safeArrivals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 12),
                Text(context.tr(AppStrings.safeArrivalNoRecent)),
              ],
            ),
          )
        else
          ...(_safeArrivals.map((a) {
            final createdAt = DateTime.parse(a['created_at'] as String);
            final formatted = DateFormat('MMM d, h:mm a').format(createdAt);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, color: Colors.green, size: 20),
                ),
                title: Text(context.tr(AppStrings.safeArrivalArrivedSafe), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(a['location_note'] as String? ?? 'Home', style: const TextStyle(fontSize: 12)),
                trailing: Text(formatted, style: const TextStyle(fontSize: 11)),
              ),
            );
          })),
      ],
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emergency_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Text(context.tr(AppStrings.safeArrivalEmergencySection), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callEmergency('911'),
                  icon: const Icon(Icons.phone, color: Colors.red, size: 16),
                  label: Text(context.tr(AppStrings.safeArrivalCall911), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callEmergency('112'),
                  icon: const Icon(Icons.phone, color: Colors.red, size: 16),
                  label: Text(context.tr(AppStrings.safeArrivalCall112), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
