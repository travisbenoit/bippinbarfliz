import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/analytics_service.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import 'music_provider.dart';
import 'radar_provider.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.authStateChanges.map((event) => event.session?.user);
});

// Watches authStateProvider so it re-evaluates whenever the signed-in user
// changes — ensuring stale data from a previous account is never shown.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final authUser = ref.watch(authStateProvider).value;

  if (authUser == null) {
    yield null;
    return;
  }

  final supabase = ref.watch(supabaseServiceProvider);
  await for (final snapshot in supabase.client
      .from('users')
      .stream(primaryKey: ['id']).eq('id', authUser.id)) {
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
    final response = await _supabase.signIn(email: email, password: password);
    final userId = response.user?.id;
    if (userId != null) {
      await AnalyticsService.instance.userSignedIn(userId);
    }
  }

  Future<void> signUp(String email, String password, {String? name}) async {
    await _supabase.signUp(
      email: email,
      password: password,
      data: name != null && name.isNotEmpty ? {'name': name} : {},
    );
    // Users table row is created after email verification, during profile setup.
  }

  Future<void> resendVerificationEmail(String email) async {
    await _supabase.resendVerificationEmail(email);
  }

  Future<void> signOut() async {
    await AnalyticsService.instance.userSignedOut();

    // Stop location tracking so it doesn't continue under a stale user ID
    await ref.read(radarTrackingStateProvider.notifier).stopTracking();

    await _supabase.signOut();

    // Invalidate cached user-specific providers so the next sign-in starts fresh
    ref.invalidate(userMusicSharesProvider);
    ref.invalidate(currentUserProfileProvider);
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
