import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_sender.dart';
import '../../utils/app_error.dart';
import '../../widgets/app_loader.dart';

const _brandPink = Color(0xFFE91E63);

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _drinkItemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await Supabase.instance.client
      .from('virtual_items')
      .select('id, name, emoji, description, price, rarity')
      .eq('category', 'drink')
      .eq('is_active', true)
      .order('price');
  return (rows as List).cast<Map<String, dynamic>>();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SendGiftScreen extends ConsumerStatefulWidget {
  final String userId;
  const SendGiftScreen({super.key, required this.userId});

  @override
  ConsumerState<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends ConsumerState<SendGiftScreen> {
  final _messageController = TextEditingController();
  String? _selectedItemId;
  bool _isSending = false;
  String? _recipientName;
  String? _myName;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final me = Supabase.instance.client.auth.currentUser;
    final (other, self) = await (
      Supabase.instance.client.from('users').select('name').eq('id', widget.userId).maybeSingle(),
      me != null
          ? Supabase.instance.client.from('users').select('name').eq('id', me.id).maybeSingle()
          : Future<Map<String, dynamic>?>.value(null),
    ).wait;
    if (!mounted) return;
    setState(() {
      _recipientName = (other?['name'] as String?)?.trim();
      _myName = ((self?['name'] as String?) ?? '').trim();
    });
  }

  Future<void> _sendGift(List<Map<String, dynamic>> items) async {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a drink to send')),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final supabase = Supabase.instance.client;
      final me = supabase.auth.currentUser;
      if (me == null) throw Exception('Not logged in');

      await supabase.from('gifts').insert({
        'from_user_id': me.id,
        'to_user_id': widget.userId,
        'item_id': _selectedItemId,
        'message': _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        'status': 'pending',
        'context_type': 'profile',
      });

      final item = items.firstWhere((i) => i['id'] == _selectedItemId);
      final itemName = item['name'] as String;
      final itemEmoji = item['emoji'] as String? ?? '🎁';

      await AnalyticsService.instance.giftSent(
        giftType: itemName,
        amount: (item['price'] as int).toDouble(),
      );

      NotificationSender.giftReceived(
        toUserId: widget.userId,
        senderName: _myName?.isEmpty ?? true ? 'Someone' : _myName!,
        itemEmoji: itemEmoji,
        itemName: itemName,
      );

      if (mounted) {
        final recipient = _recipientName?.isNotEmpty == true
            ? _recipientName!
            : ref.read(tProvider)(AppStrings.unknownUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemEmoji Gift sent to $recipient!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'SendGift');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final itemsAsync = ref.watch(_drinkItemsProvider);
    final titleText = _recipientName?.isNotEmpty == true
        ? '${t(AppStrings.giftTitleTo)} $_recipientName'
        : t(AppStrings.giftTitle);

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const AppFullLoader(color: _brandPink),
        error: (e, _) => Center(child: Text(friendlyError(e, tag: 'SendGift.items'))),
        data: (items) => _buildBody(context, t, items),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String Function(String) t, List<Map<String, dynamic>> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero ───────────────────────────────────────────
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_brandPink, Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.card_giftcard, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 28),

          // ── Pick a drink ────────────────────────────────────
          const Text(
            'Choose a drink to send',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final id = item['id'] as String;
              final selected = _selectedItemId == id;
              final rarity = item['rarity'] as String? ?? 'common';
              final rarityColor = _rarityColor(rarity);

              return GestureDetector(
                onTap: () => setState(() => _selectedItemId = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected
                        ? _brandPink.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? _brandPink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['emoji'] as String? ?? '🎁',
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rarityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item['price']} coins',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: rarityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Message ─────────────────────────────────────────
          const Text(
            'Add a message (optional)',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: t(AppStrings.giftMessageHint),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _brandPink),
              ),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 28),

          // ── Send button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isSending || _selectedItemId == null)
                  ? null
                  : () => _sendGift(items),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _brandPink.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: _isSending
                  ? const AppButtonLoader()
                  : Text(
                      t(AppStrings.giftSendButton),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'epic':
        return Colors.purple;
      case 'rare':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}
