class Gift {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String drinkType;
  final double amount;
  final String? message;
  final String status;
  final String? venueId;
  final DateTime? redeemedAt;
  final DateTime createdAt;

  Gift({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.drinkType,
    required this.amount,
    this.message,
    required this.status,
    this.venueId,
    this.redeemedAt,
    required this.createdAt,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      drinkType: json['drink_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      message: json['message'] as String?,
      status: json['status'] as String,
      venueId: json['venue_id'] as String?,
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'drink_type': drinkType,
      'amount': amount,
      'message': message,
      'status': status,
      'venue_id': venueId,
      'redeemed_at': redeemedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isRedeemed => status == 'redeemed';
  bool get isExpired => status == 'expired';
}
