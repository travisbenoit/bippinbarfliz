import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../i18n/app_strings.dart';
import '../../models/gift.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';

const _brandPink = Color(0xFFE91E63);

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

Future<List<Gift>> _fetchGifts({
  required String filterColumn,
  required String userId,
  required String otherUserColumn,
}) async {
  final db = Supabase.instance.client;

  final rows = (await db
      .from('gifts')
      .select('id, from_user_id, to_user_id, item_id, drink_type, amount, message, status, context_type, redeemed_at, created_at')
      .eq(filterColumn, userId)
      .order('created_at', ascending: false)) as List;

  if (rows.isEmpty) return [];

  // Only fetch virtual_items for rows that have an item_id
  final itemIds = rows
      .map((r) => r['item_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();
  final userIds = rows
      .map((r) => r[otherUserColumn] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final itemMap = <String, Map<String, dynamic>>{};
  final userMap = <String, Map<String, dynamic>>{};

  if (itemIds.isNotEmpty || userIds.isNotEmpty) {
    final futures = [
      if (itemIds.isNotEmpty)
        db.from('virtual_items').select('id, name, emoji, price').inFilter('id', itemIds),
      if (userIds.isNotEmpty)
        db.from('users').select('id, name').inFilter('id', userIds),
    ];
    final results = await Future.wait(futures);
    int idx = 0;
    if (itemIds.isNotEmpty) {
      for (final i in results[idx++] as List) {
        final row = i as Map<String, dynamic>;
        itemMap[row['id'] as String] = row;
      }
    }
    if (userIds.isNotEmpty) {
      for (final u in results[idx] as List) {
        final row = u as Map<String, dynamic>;
        userMap[row['id'] as String] = row;
      }
    }
  }

  return rows.map((r) {
    final raw = r as Map<String, dynamic>;
    final itemId = raw['item_id'] as String?;
    final otherId = raw[otherUserColumn] as String?;
    return Gift.fromJson({
      ...raw,
      if (itemId != null) 'virtual_items': itemMap[itemId],
      if (otherId != null) 'users': userMap[otherId],
    });
  }).toList();
}

final _receivedGiftsProvider = FutureProvider<List<Gift>>((ref) async {
  ref.watch(authStateProvider);
  final me = Supabase.instance.client.auth.currentUser;
  if (me == null) return [];
  return _fetchGifts(filterColumn: 'to_user_id', userId: me.id, otherUserColumn: 'from_user_id');
});

final _sentGiftsProvider = FutureProvider<List<Gift>>((ref) async {
  ref.watch(authStateProvider);
  final me = Supabase.instance.client.auth.currentUser;
  if (me == null) return [];
  return _fetchGifts(filterColumn: 'from_user_id', userId: me.id, otherUserColumn: 'to_user_id');
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GiftsScreen extends ConsumerStatefulWidget {
  const GiftsScreen({super.key});

  @override
  ConsumerState<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends ConsumerState<GiftsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _redeemGift(Gift gift) async {
    try {
      await Supabase.instance.client
          .from('gifts')
          .update({'status': 'redeemed', 'redeemed_at': DateTime.now().toIso8601String()})
          .eq('id', gift.id);
      ref.invalidate(_receivedGiftsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${gift.itemEmoji ?? '🎁'} Gift redeemed! Enjoy your ${gift.itemName ?? 'drink'}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'GiftsScreen.redeem');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(AppStrings.giftsTitle)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _brandPink,
          labelColor: _brandPink,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GiftList(
            provider: _receivedGiftsProvider,
            isReceived: true,
            onRedeem: _redeemGift,
          ),
          _GiftList(
            provider: _sentGiftsProvider,
            isReceived: false,
            onRedeem: null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gift list
// ---------------------------------------------------------------------------

class _GiftList extends ConsumerWidget {
  final FutureProvider<List<Gift>> provider;
  final bool isReceived;
  final void Function(Gift)? onRedeem;

  const _GiftList({
    required this.provider,
    required this.isReceived,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(provider);
    final t = ref.watch(tProvider);

    return giftsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _brandPink)),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(friendlyError(e, tag: 'Gifts'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
              ),
              child: Text(t(AppStrings.retry)),
            ),
          ],
        ),
      ),
      data: (gifts) {
        if (gifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _brandPink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard, size: 40, color: _brandPink),
                ),
                const SizedBox(height: 16),
                Text(
                  t(AppStrings.giftsEmpty),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(t(AppStrings.giftsEmptySub)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          color: _brandPink,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: gifts.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _GiftCard(
              gift: gifts[i],
              isReceived: isReceived,
              onRedeem: onRedeem,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gift card
// ---------------------------------------------------------------------------

class _GiftCard extends StatelessWidget {
  final Gift gift;
  final bool isReceived;
  final void Function(Gift)? onRedeem;

  const _GiftCard({
    required this.gift,
    required this.isReceived,
    required this.onRedeem,
  });

  Color get _statusColor {
    if (gift.isPending) return _brandPink;
    if (gift.isRedeemed) return Colors.green;
    return Colors.grey;
  }

  String get _statusLabel {
    if (gift.isPending) return 'Pending';
    if (gift.isRedeemed) return 'Redeemed';
    return 'Expired';
  }

  @override
  Widget build(BuildContext context) {
    final emoji = gift.itemEmoji ?? '🎁';
    final name = gift.itemName ?? 'Gift';
    final price = gift.itemPrice;
    final otherName = isReceived
        ? (gift.fromUserName ?? 'Someone')
        : (gift.fromUserName ?? 'Someone');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _brandPink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isReceived ? 'From $otherName' : 'To $otherName',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (gift.message != null && gift.message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${gift.message}"',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (price != null) ...[
                      Text(
                        '$price coins',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('·', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      timeago.format(gift.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    if (isReceived && gift.isPending && onRedeem != null) ...[
                      const Spacer(),
                      TextButton(
                        onPressed: () => onRedeem!(gift),
                        style: TextButton.styleFrom(
                          foregroundColor: _brandPink,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Redeem',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
