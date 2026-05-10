import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_strings.dart';
import '../../models/swarm.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../services/notification_sender.dart';
import '../../widgets/app_loader.dart';

const _brandPink = Color(0xFFE91E63);

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _supabase = Supabase.instance.client;

final activeSwarmsProvider = FutureProvider.autoDispose<List<Swarm>>((ref) async {
  ref.watch(authStateProvider); // re-run on auth change
  final rows = await _supabase
      .from('swarms')
      .select()
      .eq('status', 'active')
      .order('start_time');
  return (rows as List).map((r) => Swarm.fromJson(r as Map<String, dynamic>)).toList();
});

final myJoinedSwarmIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return {};
  final rows = await _supabase
      .from('swarm_members')
      .select('swarm_id')
      .eq('user_id', user.id);
  return {for (final r in rows as List) r['swarm_id'] as String};
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SwarmsScreen extends ConsumerStatefulWidget {
  const SwarmsScreen({super.key});

  @override
  ConsumerState<SwarmsScreen> createState() => _SwarmsScreenState();
}

class _SwarmsScreenState extends ConsumerState<SwarmsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(activeSwarmsProvider);
    ref.invalidate(myJoinedSwarmIdsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final swarmsAsync = ref.watch(activeSwarmsProvider);
    final joinedAsync = ref.watch(myJoinedSwarmIdsProvider);
    final me = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(t(AppStrings.swarmsTitle),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _brandPink,
          labelColor: _brandPink,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Swarms'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brandPink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(t(AppStrings.swarmsCreate)),
        onPressed: () async {
          await context.push('/create-swarm');
          _refresh();
        },
      ),
      body: swarmsAsync.when(
        loading: () => const AppFullLoader(color: _brandPink),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Failed to load swarms'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (swarms) {
          final joinedIds = joinedAsync.value ?? {};
          final mySwarms = swarms.where((s) =>
              s.creatorId == me?.id || joinedIds.contains(s.id)).toList();
          final discover = swarms.where((s) => s.creatorId != me?.id).toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _SwarmList(
                swarms: discover,
                joinedIds: joinedIds,
                meId: me?.id,
                emptyMessage: 'No active swarms nearby.\nBe the first to create one!',
                onRefresh: _refresh,
                onJoined: _refresh,
              ),
              _SwarmList(
                swarms: mySwarms,
                joinedIds: joinedIds,
                meId: me?.id,
                emptyMessage: 'You haven\'t joined or hosted any swarms yet.',
                onRefresh: _refresh,
                onJoined: _refresh,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swarm list
// ---------------------------------------------------------------------------

class _SwarmList extends StatelessWidget {
  final List<Swarm> swarms;
  final Set<String> joinedIds;
  final String? meId;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final VoidCallback onJoined;

  const _SwarmList({
    required this.swarms,
    required this.joinedIds,
    required this.meId,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onJoined,
  });

  @override
  Widget build(BuildContext context) {
    if (swarms.isEmpty) {
      return RefreshIndicator(
        color: _brandPink,
        onRefresh: () async => onRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Icon(Icons.group_outlined, size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _brandPink,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: swarms.length,
        itemBuilder: (context, i) => _SwarmCard(
          swarm: swarms[i],
          isHost: swarms[i].creatorId == meId,
          isJoined: joinedIds.contains(swarms[i].id),
          onJoined: onJoined,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swarm card
// ---------------------------------------------------------------------------

class _SwarmCard extends ConsumerStatefulWidget {
  final Swarm swarm;
  final bool isHost;
  final bool isJoined;
  final VoidCallback onJoined;

  const _SwarmCard({
    required this.swarm,
    required this.isHost,
    required this.isJoined,
    required this.onJoined,
  });

  @override
  ConsumerState<_SwarmCard> createState() => _SwarmCardState();
}

class _SwarmCardState extends ConsumerState<_SwarmCard> {
  bool _joining = false;

  Future<void> _join() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _joining = true);
    try {
      await _supabase.from('swarm_members').insert({
        'swarm_id': widget.swarm.id,
        'user_id': user.id,
        'role': 'member',
        'rsvp': 'going',
      });

      // Count actual members so the number is always accurate
      final memberRows = await _supabase
          .from('swarm_members')
          .select('user_id')
          .eq('swarm_id', widget.swarm.id);
      final newSize = (memberRows as List).length;
      await _supabase.from('swarms').update({
        'current_size': newSize,
      }).eq('id', widget.swarm.id);

      final profile = await _supabase.from('users').select('name').eq('id', user.id).single();
      final joinerName = (profile['name'] as String?)?.trim();
      NotificationSender.swarmJoined(
        swarmId: widget.swarm.id,
        swarmTitle: widget.swarm.title,
        hostUserId: widget.swarm.creatorId,
        joinerName: (joinerName == null || joinerName.isEmpty) ? 'Someone' : joinerName,
      );

      widget.onJoined();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'Swarms.join');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SwarmDetailSheet(
        swarm: widget.swarm,
        isHost: widget.isHost,
        isJoined: widget.isJoined,
        joining: _joining,
        onJoin: _join,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final swarm = widget.swarm;
    final isFull = swarm.currentSize >= swarm.maxSize;
    final timeStr = DateFormat('EEE, MMM d • h:mm a').format(swarm.startTime.toLocal());

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover image ──────────────────────────────────
            if (swarm.imageUrl != null && swarm.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: swarm.imageUrl!,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 130,
                  color: _brandPink.withValues(alpha: 0.08),
                  child: const Center(child: AppButtonLoader(size: 24, color: _brandPink)),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────
                  Row(
                    children: [
                      if (swarm.imageUrl == null || swarm.imageUrl!.isEmpty)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_brandPink, Color(0xFFFF6B6B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups, color: Colors.white, size: 22),
                        ),
                      if (swarm.imageUrl == null || swarm.imageUrl!.isEmpty)
                        const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              swarm.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time_outlined,
                                    size: 13,
                                    color: cs.onSurface.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    timeStr,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(alpha: 0.6)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Member count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFull
                              ? Colors.red.withValues(alpha: 0.1)
                              : _brandPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 13,
                                color: isFull ? Colors.red : _brandPink),
                            const SizedBox(width: 4),
                            Text(
                              '${swarm.currentSize}/${swarm.maxSize}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isFull ? Colors.red : _brandPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Description ──────────────────────────────
                  if (swarm.description != null && swarm.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      swarm.description!,
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // ── Venue ────────────────────────────────────
                  if (swarm.venueName != null && swarm.venueName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          swarm.venueName!,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ],

                  // ── Vibe tags ────────────────────────────────
                  if (swarm.vibeTags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: swarm.vibeTags
                          .map((tag) => _Tag(label: tag))
                          .toList(),
                    ),
                  ],

                  // ── Action ───────────────────────────────────
                  const SizedBox(height: 12),
                  if (widget.isHost)
                    const _StatusChip(label: 'Hosting', color: Colors.purple)
                  else if (widget.isJoined)
                    const _StatusChip(label: 'Joined', color: Colors.green)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isFull || _joining) ? null : _join,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandPink,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _joining
                            ? const AppButtonLoader(size: 18)
                            : Text(
                                isFull ? 'Full' : 'Join Swarm',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
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
// Swarm detail bottom sheet
// ---------------------------------------------------------------------------

class _SwarmDetailSheet extends StatefulWidget {
  final Swarm swarm;
  final bool isHost;
  final bool isJoined;
  final bool joining;
  final Future<void> Function() onJoin;

  const _SwarmDetailSheet({
    required this.swarm,
    required this.isHost,
    required this.isJoined,
    required this.joining,
    required this.onJoin,
  });

  @override
  State<_SwarmDetailSheet> createState() => _SwarmDetailSheetState();
}

class _SwarmDetailSheetState extends State<_SwarmDetailSheet> {
  bool _joining = false;

  Future<void> _handleJoin() async {
    setState(() => _joining = true);
    await widget.onJoin();
    if (mounted) {
      setState(() => _joining = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final swarm = widget.swarm;
    final cs = Theme.of(context).colorScheme;
    final isFull = swarm.currentSize >= swarm.maxSize;
    final timeStr = DateFormat('EEEE, MMMM d • h:mm a').format(swarm.startTime.toLocal());

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.zero,
                children: [
                  // Cover image
                  if (swarm.imageUrl != null && swarm.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: swarm.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: _brandPink.withValues(alpha: 0.08),
                        child: const Center(child: AppButtonLoader(size: 28, color: _brandPink)),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    )
                  else
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_brandPink, Color(0xFFFF6B6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.groups, size: 48, color: Colors.white),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + member count
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                swarm.title,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isFull
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : _brandPink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people,
                                      size: 15,
                                      color: isFull ? Colors.red : _brandPink),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${swarm.currentSize}/${swarm.maxSize}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isFull ? Colors.red : _brandPink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Time
                        _DetailRow(
                          icon: Icons.access_time,
                          color: Colors.indigo,
                          text: timeStr,
                        ),

                        // Venue
                        if (swarm.venueName != null && swarm.venueName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _DetailRow(
                            icon: Icons.location_on,
                            color: Colors.teal,
                            text: swarm.venueName!,
                          ),
                        ],

                        // Description
                        if (swarm.description != null && swarm.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            swarm.description!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],

                        // Vibe tags
                        if (swarm.vibeTags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: swarm.vibeTags.map((t) => _Tag(label: t)).toList(),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action button
                        if (widget.isHost)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_outline, color: Colors.purple, size: 18),
                                SizedBox(width: 8),
                                Text('You\'re hosting this swarm',
                                    style: TextStyle(
                                        color: Colors.purple, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        else if (widget.isJoined)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('You\'ve joined this swarm',
                                    style: TextStyle(
                                        color: Colors.green, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (isFull || _joining) ? null : _handleJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandPink,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _joining
                                  ? const AppButtonLoader(size: 20)
                                  : Text(
                                      isFull ? 'Swarm is Full' : 'Join Swarm',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _DetailRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _brandPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandPink.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _brandPink),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
