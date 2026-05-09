class Gift {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? itemId;
  final String? message;
  final String status;
  final String contextType;
  final DateTime? redeemedAt;
  final DateTime createdAt;

  // Joined from virtual_items
  final String? itemName;
  final String? itemEmoji;
  final int? itemPrice;

  // Joined from users
  final String? fromUserName;

  Gift({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.itemId,
    this.message,
    required this.status,
    required this.contextType,
    this.redeemedAt,
    required this.createdAt,
    this.itemName,
    this.itemEmoji,
    this.itemPrice,
    this.fromUserName,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    final item = json['virtual_items'] as Map<String, dynamic>?;
    final sender = json['users'] as Map<String, dynamic>?;

    // Support both new (item_id) and legacy (drink_type) rows
    final itemName = item?['name'] as String? ?? json['drink_type'] as String?;
    final itemPrice = item?['price'] as int? ??
        (json['amount'] != null ? (json['amount'] as num).round() : null);

    return Gift(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      itemId: json['item_id'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      contextType: json['context_type'] as String? ?? 'profile',
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemName: itemName,
      itemEmoji: item?['emoji'] as String?,
      itemPrice: itemPrice,
      fromUserName: sender?['name'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isRedeemed => status == 'redeemed';
  bool get isExpired => status == 'expired';
}
