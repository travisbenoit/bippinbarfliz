import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendGiftScreen extends StatefulWidget {
  final String userId;

  const SendGiftScreen({super.key, required this.userId});

  @override
  State<SendGiftScreen> createState() => _SendGiftScreenState();
}

class _SendGiftScreenState extends State<SendGiftScreen> {
  final _messageController = TextEditingController();
  String _selectedDrink = 'Beer';
  double _amount = 5.0;
  bool _isSending = false;
  String? _recipientName;

  final List<String> _drinkTypes = ['Beer', 'Wine', 'Cocktail', 'Shot', 'Custom'];

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

      if (currentUser == null) {
        throw Exception('Not logged in');
      }

      await supabase.from('user_gifts').insert({
        'sender_user_id': currentUser.id,
        'recipient_user_id': widget.userId,
        'gift_type': _selectedDrink.toLowerCase(),
        'amount': _amount,
        'message': _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        'status': 'pending',
        'delivery_method': 'direct_message',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gift sent to ${_recipientName ?? 'user'}!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send gift: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      appBar: AppBar(
        title: Text(_recipientName != null
            ? 'Send Gift to $_recipientName'
            : 'Send a Gift'),
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
            const Text(
              'Choose a drink',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _drinkTypes.map((drink) {
                final isSelected = _selectedDrink == drink;
                return ChoiceChip(
                  label: Text(drink),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE91E63),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedDrink = drink;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Amount',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _amount,
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: const Color(0xFFE91E63),
              label: '\$${_amount.toStringAsFixed(0)}',
              onChanged: (value) {
                setState(() {
                  _amount = value;
                });
              },
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
                labelText: 'Add a message (optional)',
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
                    : const Text(
                        'Send Gift',
                        style: TextStyle(
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
