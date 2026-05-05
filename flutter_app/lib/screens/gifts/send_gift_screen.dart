import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_strings.dart';
import '../../providers/localization_provider.dart';
import '../../services/analytics_service.dart';

class SendGiftScreen extends ConsumerStatefulWidget {
  final String userId;

  const SendGiftScreen({super.key, required this.userId});

  @override
  ConsumerState<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends ConsumerState<SendGiftScreen> {
  final _messageController = TextEditingController();
  String _selectedDrink = 'Beer';
  double _amount = 5.0;
  bool _isSending = false;
  String? _recipientName;

  @override
  void initState() {
    super.initState();
    _loadRecipient();
  }

  Future<void> _loadRecipient() async {
    final response = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', widget.userId)
        .maybeSingle();

    if (mounted && response != null) {
      setState(() {
        _recipientName = response['name'];
      });
    }
  }

  Future<void> _sendGift() async {
    setState(() => _isSending = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) throw Exception('Not logged in');

      await supabase.from('gifts').insert({
        'from_user_id': currentUser.id,
        'to_user_id': widget.userId,
        'drink_type': _selectedDrink.toLowerCase(),
        'amount': _amount,
        'message': _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        'status': 'pending',
      });

      await AnalyticsService.instance.giftSent(
        giftType: _selectedDrink,
        amount: _amount,
      );

      if (mounted) {
        final t = ref.read(tProvider);
        final recipient = _recipientName ?? t(AppStrings.unknownUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(AppStrings.giftSentSuccess)} $recipient!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final t = ref.read(tProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t(AppStrings.giftSendError)}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    final drinkOptions = [
      (t(AppStrings.giftDrinkBeer),     'Beer'),
      (t(AppStrings.giftDrinkWine),     'Wine'),
      (t(AppStrings.giftDrinkCocktail), 'Cocktail'),
      (t(AppStrings.giftDrinkShot),     'Shot'),
      (t(AppStrings.giftDrinkCustom),   'Custom'),
    ];

    final titleText = _recipientName != null
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              t(AppStrings.giftChooseDrink),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drinkOptions.map((pair) {
                final label    = pair.$1;
                final value    = pair.$2;
                final selected = _selectedDrink == value;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  selectedColor: const Color(0xFFE91E63),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                  ),
                  onSelected: (_) => setState(() => _selectedDrink = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Text(
              t(AppStrings.giftAmount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _amount,
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: const Color(0xFFE91E63),
              label: '\$${_amount.toStringAsFixed(0)}',
              onChanged: (value) => setState(() => _amount = value),
            ),
            Center(
              child: Text(
                '\$${_amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: t(AppStrings.giftMessageHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE91E63)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendGift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        t(AppStrings.giftSendButton),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
