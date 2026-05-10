import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../extensions/localization_extension.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../widgets/app_loader.dart';

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  static const _pink = Color(0xFFE91E63);

  List<_BlockedUser> _items = [];
  bool _loading = true;
  String? _removing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final me = supabase.auth.currentUser;
      if (me == null) {
        setState(() => _loading = false);
        return;
      }

      final blocks = await supabase
          .from('user_blocks')
          .select('id, blocked_id, created_at')
          .eq('blocker_id', me.id)
          .order('created_at', ascending: false);

      if ((blocks as List).isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      final ids = blocks.map((b) => b['blocked_id'] as String).toList();

      final profiles = await supabase
          .from('users')
          .select('id, name, avatar_url')
          .inFilter('id', ids);

      final profileMap = <String, Map<String, dynamic>>{
        for (final p in (profiles as List))
          (p['id'] as String): p as Map<String, dynamic>
      };

      setState(() {
        _items = blocks.map((b) {
          final profile = profileMap[b['blocked_id'] as String];
          return _BlockedUser(
            blockId:   b['id'] as String,
            userId:    b['blocked_id'] as String,
            name:      profile?['name'] as String? ?? context.tr(AppStrings.unknownUser),
            avatarUrl: profile?['avatar_url'] as String?,
            blockedAt: DateTime.parse(b['created_at'] as String),
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr(AppStrings.blockedLoadError))),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _unblock(String blockId) async {
    setState(() => _removing = blockId);
    try {
      await Supabase.instance.client
          .from('user_blocks')
          .delete()
          .eq('id', blockId);
      if (mounted) {
        setState(() => _items.removeWhere((i) => i.blockId == blockId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(AppStrings.blockedUnblockOk)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(AppStrings.blockedUnblockError)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _removing = null);
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
        title: Text(
          t(AppStrings.blockedTitle),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const AppFullLoader(color: _pink)
          : _items.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _pink,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return _BlockedUserTile(
                        item: item,
                        removing: _removing == item.blockId,
                        onUnblock: () => _unblock(item.blockId),
                      );
                    },
                  ),
                ),
    );
  }
}

class _BlockedUser {
  final String blockId;
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime blockedAt;

  _BlockedUser({
    required this.blockId,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.blockedAt,
  });
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_off_outlined, size: 36, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(AppStrings.blockedEmpty),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(AppStrings.blockedEmptySub),
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final _BlockedUser item;
  final bool removing;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.item,
    required this.removing,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage:
                  item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
              child: item.avatarUrl == null
                  ? Text(
                      item.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.tr(AppStrings.blockedOn)} ${_formatDate(item.blockedAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            removing
                ? const AppButtonLoader(size: 20)
                : OutlinedButton(
                    onPressed: onUnblock,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE91E63),
                      side: const BorderSide(color: Color(0xFFE91E63), width: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(context.tr(AppStrings.blockedUnblock)),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
