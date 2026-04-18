import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => currentUser?.id;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic> data = const {},
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
  }
}
