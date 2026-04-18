import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.authStateChanges.map((event) => event.session?.user);
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final supabase = ref.watch(supabaseServiceProvider);
  final userId = supabase.currentUserId;

  if (userId == null) {
    yield null;
    return;
  }

  await for (final snapshot in supabase.client
      .from('users')
      .stream(primaryKey: ['id']).eq('id', userId)) {
    if (snapshot.isNotEmpty) {
      yield UserProfile.fromJson(snapshot.first);
    } else {
      yield null;
    }
  }
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref ref;

  AuthController(this.ref);

  SupabaseService get _supabase => ref.read(supabaseServiceProvider);

  Future<void> signIn(String email, String password) async {
    await _supabase.signIn(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.signUp(email: email, password: password);
      print(
          '[AuthController] signUp response: user=${response.user?.id}, session=${response.session?.accessToken}');

      if (response.user != null) {
        try {
          await _supabase.client.from('users').insert({
            'id': response.user!.id,
            'name': '',
            'tonight_status': 'staying_in',
            'vibe_tags': [],
            'favorite_drinks': [],
            'is_premium': false,
            'created_at': DateTime.now().toIso8601String(),
          }).select();
        } catch (e, stackTrace) {
          print(
              '[AuthController] User profile creation failed: ${e.runtimeType} - $e');
          print(stackTrace);
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      print('[AuthController] signUp exception: ${e.runtimeType} - $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.resetPassword(email);
  }

  Future<void> createUserProfile({
    required String name,
    required DateTime dob,
    String? homeCity,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    // Calculate age from DOB
    final now = DateTime.now();
    final age = now.year -
        dob.year -
        ((now.month > dob.month ||
                (now.month == dob.month && now.day >= dob.day))
            ? 0
            : 1);

    await _supabase.client.from('users').upsert({
      'id': userId,
      'name': name,
      'dob': dob.toIso8601String().split('T')[0],
      'home_city': homeCity,
      'age': age,
      'is_21_plus_confirmed': age >= 21,
    });
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    await _supabase.client
        .from('users')
        .update(profile.toJson())
        .eq('id', userId);
  }
}
