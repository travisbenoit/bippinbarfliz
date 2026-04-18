import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'supabase_service.dart';

class PaymentService {
  final SupabaseService _supabase;

  PaymentService(this._supabase);

  Future<void> createSubscription({
    required String planType,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('No authenticated user');

      final response = await _supabase.client.functions.invoke(
        'create-subscription',
        body: {'plan_type': planType},
      );

      final clientSecret = response.data['client_secret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Barfliz',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendGift({
    required String toUserId,
    required String drinkType,
    required double amount,
    String? message,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('No authenticated user');

      await _supabase.client.functions.invoke(
        'send-gift',
        body: {
          'to_user_id': toUserId,
          'drink_type': drinkType,
          'amount': amount,
          'message': message,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> redeemGift(String giftId) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('No authenticated user');

      await _supabase.client
          .from('gifts')
          .update({
            'status': 'redeemed',
            'redeemed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', giftId)
          .eq('to_user_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
