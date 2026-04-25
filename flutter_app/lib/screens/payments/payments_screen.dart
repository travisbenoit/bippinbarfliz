import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return null;
  final res = await supabase
      .from('users')
      .select('id, name, lush_coin_balance, payment_provider, payment_provider_username, payment_provider_linked')
      .eq('id', uid)
      .maybeSingle();
  return res;
});

final _paymentHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];
  final res = await supabase
      .from('payment_transactions')
      .select('id, from_user_id, to_user_id, amount, currency, transaction_type, status, description, created_at')
      .or('from_user_id.eq.$uid,to_user_id.eq.$uid')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(res as List);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _pink = Color(0xFFE91E63);
  static const _bg = Color(0xFFFFF5F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        title: const Text(
          'Payments',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.account_balance_wallet_outlined, color: _pink),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _pink,
          labelColor: _pink,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Send'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(onGoToSend: () => _tabController.animateTo(1)),
          const _SendTab(),
          const _HistoryTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 – Overview
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  final VoidCallback onGoToSend;

  const _OverviewTab({required this.onGoToSend});

  static const _pink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _pink),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profile) {
        final lushBalance = (profile?['lush_coin_balance'] as num?)?.toInt() ?? 0;
        final providerLinked = profile?['payment_provider_linked'] == true;
        final providerName = profile?['payment_provider_username'] as String?;
        final provider = profile?['payment_provider'] as String? ?? 'Payment';

        return RefreshIndicator(
          color: _pink,
          onRefresh: () async => ref.invalidate(_currentUserProfileProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // LushCoin balance card
              _LushCoinCard(balance: lushBalance),
              const SizedBox(height: 16),

              // Payment method card
              _PaymentMethodCard(
                linked: providerLinked,
                providerName: providerName,
                provider: provider,
                onLink: () => _showLinkPaymentDialog(context),
              ),
              const SizedBox(height: 24),

              // Send Payment button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onGoToSend,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Request Payment button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request payment – coming soon')),
                  ),
                  icon: const Icon(Icons.request_page_outlined),
                  label: const Text('Request Payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _pink,
                    side: const BorderSide(color: _pink),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLinkPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Payment Method'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PaymentOptionTile(
              icon: Icons.attach_money,
              label: 'Venmo',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Venmo setup coming soon')),
                );
              },
            ),
            _PaymentOptionTile(
              icon: Icons.paypal,
              label: 'PayPal',
              color: const Color(0xFF003087),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PayPal setup coming soon')),
                );
              },
            ),
            _PaymentOptionTile(
              icon: Icons.payments_outlined,
              label: 'CashApp',
              color: Colors.green,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CashApp setup coming soon')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _LushCoinCard extends StatelessWidget {
  final int balance;

  const _LushCoinCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🪙', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Text(
                'LushCoin',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'coins available',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon - LushCoin purchases'),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Add Coins',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final bool linked;
  final String? providerName;
  final String provider;
  final VoidCallback onLink;

  const _PaymentMethodCard({
    required this.linked,
    required this.providerName,
    required this.provider,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: linked
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              linked ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
              color: linked ? Colors.green : Colors.grey,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (linked && providerName != null) ...[
                  Text(
                    providerName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$provider linked',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'No method linked',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  TextButton(
                    onPressed: onLink,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Link Payment Method →',
                      style: TextStyle(
                        color: Color(0xFFE91E63),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 – Send
// ---------------------------------------------------------------------------

class _SendTab extends ConsumerStatefulWidget {
  const _SendTab();

  @override
  ConsumerState<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<_SendTab> {
  static const _pink = Color(0xFFE91E63);

  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedUser;
  bool _isSearching = false;
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUid = supabase.auth.currentUser?.id;
      final res = await supabase
          .from('users')
          .select('id, name, avatar_url')
          .ilike('name', '%$query%')
          .neq('id', currentUid ?? '')
          .limit(10);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(res as List);
      });
    } catch (e) {
      // ignore search errors silently
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendPayment() async {
    final recipient = _selectedUser;
    if (recipient == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      await supabase.from('payment_transactions').insert({
        'from_user_id': uid,
        'to_user_id': recipient['id'],
        'amount': amount,
        'currency': 'USD',
        'transaction_type': 'send',
        'status': 'completed',
        'description': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      });
      ref.invalidate(_paymentHistoryProvider);
      setState(() {
        _selectedUser = null;
        _searchController.clear();
        _amountController.clear();
        _noteController.clear();
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment sent to ${recipient['name']}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search people by name...',
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _pink),
                      ),
                    )
                  : const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        // Search results
        if (_searchResults.isNotEmpty && _selectedUser == null) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _pink.withValues(alpha: 0.1),
                    backgroundImage: user['avatar_url'] != null
                        ? NetworkImage(user['avatar_url'] as String)
                        : null,
                    child: user['avatar_url'] == null
                        ? const Icon(Icons.person, color: _pink)
                        : null,
                  ),
                  title: Text(
                    user['name'] as String? ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedUser = user;
                      _searchController.text = user['name'] as String? ?? '';
                      _searchResults = [];
                    });
                  },
                );
              },
            ),
          ),
        ],

        // Selected user + payment form
        if (_selectedUser != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _pink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _pink.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _pink.withValues(alpha: 0.15),
                  backgroundImage: _selectedUser!['avatar_url'] != null
                      ? NetworkImage(_selectedUser!['avatar_url'] as String)
                      : null,
                  child: _selectedUser!['avatar_url'] == null
                      ? const Icon(Icons.person, color: _pink)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sending to',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        _selectedUser!['name'] as String? ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() {
                    _selectedUser = null;
                    _searchController.clear();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount field
          _buildInputField(
            controller: _amountController,
            label: 'Amount (USD)',
            hint: '0.00',
            prefixText: '\$ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 12),

          // Note field
          _buildInputField(
            controller: _noteController,
            label: 'Note (optional)',
            hint: 'What\'s it for?',
          ),
          const SizedBox(height: 24),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Payment'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3 – History
// ---------------------------------------------------------------------------

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  static const _pink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_paymentHistoryProvider);
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _pink)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _pink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_outlined, size: 40, color: _pink),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No transactions yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment history will appear here',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        double totalSent = 0;
        double totalReceived = 0;
        for (final tx in transactions) {
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
          if (tx['from_user_id'] == uid) totalSent += amount;
          if (tx['to_user_id'] == uid) totalReceived += amount;
        }

        return RefreshIndicator(
          color: _pink,
          onRefresh: () async => ref.invalidate(_paymentHistoryProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Total Sent',
                        amount: totalSent,
                        color: Colors.red,
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                    Container(width: 1, height: 50, color: Colors.grey[200]),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Total Received',
                        amount: totalReceived,
                        color: Colors.green,
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...transactions.map((tx) => _TransactionTile(tx: tx, currentUid: uid)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String? currentUid;

  const _TransactionTile({required this.tx, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final isSender = tx['from_user_id'] == currentUid;
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final currency = tx['currency'] as String? ?? 'USD';
    final note = tx['description'] as String?;
    final status = tx['status'] as String? ?? 'pending';
    final createdAt = tx['created_at'] != null
        ? DateTime.tryParse(tx['created_at'] as String)
        : null;

    final amountStr = isSender
        ? '-\$${amount.toStringAsFixed(2)}'
        : '+\$${amount.toStringAsFixed(2)}';
    final amountColor = isSender ? Colors.red : Colors.green;

    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSender ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: amountColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSender ? 'Payment Sent' : 'Payment Received',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a').format(createdAt.toLocal()),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountStr $currency',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
