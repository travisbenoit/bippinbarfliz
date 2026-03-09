import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

      final session = await _supabase.client.auth.getSession();
      final token = session.session?.accessToken;

      final response = await http.post(
        Uri.parse('${_supabase.client.supabaseUrl}/functions/v1/create-subscription'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'plan_type': planType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create subscription');
      }

      final data = json.decode(response.body);
      final clientSecret = data['client_secret'];

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

      final session = await _supabase.client.auth.getSession();
      final token = session.session?.accessToken;

      final response = await http.post(
        Uri.parse('${_supabase.client.supabaseUrl}/functions/v1/send-gift'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'to_user_id': toUserId,
          'drink_type': drinkType,
          'amount': amount,
          'message': message,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send gift');
      }
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
