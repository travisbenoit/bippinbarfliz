import 'package:flutter/foundation.dart';
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

// Set to true immediately when createUserProfile succeeds so the router
// doesn't send the user back to /profile-setup while the realtime stream
// is still propagating the updated row. Cleared on sign-out.
final profileSetupDoneProvider =
    NotifierProvider<_ProfileSetupDoneNotifier, bool>(
        _ProfileSetupDoneNotifier.new);

class _ProfileSetupDoneNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void complete() => state = true;
  void reset() => state = false;
}

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.authStateChanges.map((event) => event.session?.user);
});

// Exposes the raw auth event type so password-recovery deep links can be handled.
final authChangeEventProvider = StreamProvider<AuthChangeEvent?>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.authStateChanges.map((s) => s.event);
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
  try {
    await for (final snapshot in supabase.client
        .from('users')
        .stream(primaryKey: ['id']).eq('id', authUser.id)) {
      if (snapshot.isNotEmpty) {
        yield UserProfile.fromJson(snapshot.first);
      } else {
        yield null;
      }
    }
  } catch (e) {
    // Realtime WebSocket can time out on poor connections — fall back to a
    // one-shot REST fetch so the app stays usable.
    debugPrint(
        '[currentUserProfileProvider] stream error: $e — falling back to REST');
    try {
      final data = await supabase.client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      yield data != null ? UserProfile.fromJson(data) : null;
    } catch (e2) {
      debugPrint('[currentUserProfileProvider] REST fallback failed: $e2');
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
