import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';

class NightRecapScreen extends ConsumerStatefulWidget {
  const NightRecapScreen({super.key});

  @override
  ConsumerState<NightRecapScreen> createState() => _NightRecapScreenState();
}

class _NightRecapScreenState extends ConsumerState<NightRecapScreen> {
  static const _brandPink = Color(0xFFE91E63);

  List<Map<String, dynamic>> _activities = [];
  bool _loading = true;
  Map<String, dynamic>? _nightRoute;

  @override
  void initState() {
    super.initState();
    _loadRecap();
  }

  Future<void> _loadRecap() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final yesterday = DateTime.now().subtract(const Duration(hours: 24));

      final activities = await supabase
          .from('user_activity_history')
          .select()
          .eq('user_id', currentUser.id)
          .inFilter('action_type', ['venue_checkin', 'message_sent', 'swarm_joined', 'gift_sent'])
          .gte('created_at', yesterday.toIso8601String())
          .order('created_at');

      final routeRes = await supabase
          .from('night_routes')
          .select()
          .eq('creator_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _activities = List<Map<String, dynamic>>.from(activities as List);
        _nightRoute = routeRes;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  int _countByType(String type) => _activities.where((a) => a['action_type'] == type).length;

  IconData _iconForType(String type) {
    return switch (type) {
      'venue_checkin' => Icons.local_bar,
      'message_sent' => Icons.chat_bubble_outline,
      'swarm_joined' => Icons.groups_outlined,
      'gift_sent' => Icons.card_giftcard_outlined,
      _ => Icons.star_outline,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'venue_checkin' => Colors.orange,
      'message_sent' => Colors.blue,
      'swarm_joined' => _brandPink,
      'gift_sent' => Colors.green,
      _ => Colors.grey,
    };
  }

  String _labelForType(String type) {
    return switch (type) {
      'venue_checkin' => 'Venue Check-in',
      'message_sent' => 'Message Sent',
      'swarm_joined' => 'Joined Swarm',
      'gift_sent' => 'Gift Sent',
      _ => 'Activity',
    };
  }

  String _descForActivity(Map<String, dynamic> activity) {
    final meta = activity['metadata'] as Map<String, dynamic>?;
    return switch (activity['action_type'] as String) {
      'venue_checkin' => meta?['venue_name'] as String? ?? 'A venue',
      'message_sent' => 'Sent a message',
      'swarm_joined' => meta?['swarm_title'] as String? ?? 'A swarm',
      'gift_sent' => meta?['gift_name'] as String? ?? 'A gift',
      _ => 'Activity',
    };
  }

  void _shareRecap() {
    final venuesVisited = _countByType('venue_checkin');
    final messages = _countByType('message_sent');
    final swarms = _countByType('swarm_joined');
    SharePlus.instance.share(
      ShareParams(
        text: 'My Night Recap on Barfliz!\n\n'
            '$venuesVisited venues visited\n'
            '$messages messages sent\n'
            '$swarms swarms joined\n\n'
            'Join me on Barfliz!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastNight = now.subtract(const Duration(days: 1));
    final dateStr = DateFormat('EEEE, MMM d').format(lastNight);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Night Recap 🌙', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_activities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: _brandPink),
              onPressed: _shareRecap,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandPink))
          : RefreshIndicator(
              color: _brandPink,
              onRefresh: _loadRecap,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _activities.isEmpty
                    ? _buildEmpty()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(dateStr),
                          const SizedBox(height: 16),
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                          if (_nightRoute != null) ...[
                            _buildNightRouteCard(),
                            const SizedBox(height: 20),
                          ],
                          const Text(
                            'Timeline',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          _buildTimeline(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _shareRecap,
                              icon: const Icon(Icons.share),
                              label: const Text('Share Night Recap'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandPink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _brandPink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.nightlife, size: 40, color: _brandPink),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nothing to recap yet!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by going out 🍻',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/map'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Find Venues'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Last Night's Recap", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 16),
          Text(
            '${_activities.length} activities recorded',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatChip(
          icon: Icons.local_bar,
          color: Colors.orange,
          value: '${_countByType('venue_checkin')}',
          label: 'Venues',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.chat_bubble_outline,
          color: Colors.blue,
          value: '${_countByType('message_sent')}',
          label: 'Messages',
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.groups_outlined,
          color: _brandPink,
          value: '${_countByType('swarm_joined')}',
          label: 'Swarms',
        ),
      ],
    );
  }

  Widget _buildNightRouteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _brandPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.route_outlined, color: _brandPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Night Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  _nightRoute!['title'] as String? ?? 'Your planned route',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: _activities.asMap().entries.map((entry) {
        final i = entry.key;
        final activity = entry.value;
        final isLast = i == _activities.length - 1;
        final type = activity['action_type'] as String? ?? 'activity';
        final createdAt = DateTime.parse(activity['created_at'] as String);
        final timeStr = DateFormat('h:mm a').format(createdAt);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _colorForType(type).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconForType(type), color: _colorForType(type), size: 18),
                ),
                if (!isLast)
                  Container(width: 2, height: 32, color: Colors.grey[200]),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_labelForType(type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(_descForActivity(activity), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 2),
                    Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatChip({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
