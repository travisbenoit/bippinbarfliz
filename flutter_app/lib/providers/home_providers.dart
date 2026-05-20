import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/venue.dart';
import '../models/swarm.dart';
import 'auth_provider.dart';

final nearbyUsersProvider = FutureProvider<List<UserProfile>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return [];

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('users')
      .select()
      .neq('id', user.id)
      .neq('ghost_mode', true)
      .inFilter('tonight_status', ['out_now', 'going_out_soon'])
      .order('last_active_at', ascending: false)
      .limit(50);

  return (response as List).map((json) => UserProfile.fromJson(json)).toList();
});

final nearbyVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('venues')
      .select()
      .eq('is_active', true)
      .order('name')
      .limit(50);

  return (response as List).map((json) => Venue.fromJson(json)).toList();
});

final venueCountProvider = FutureProvider<int>((ref) async {
  final supabase = Supabase.instance.client;

  return await supabase
      .from('venues')
      .count(CountOption.exact)
      .eq('is_active', true);
});

// StreamProvider so the home screen auto-updates whenever current_size
// changes in the DB (e.g. when someone joins). Supabase Realtime must be
// enabled on the swarms table, which it now is.
final activeSwarmsProvider = StreamProvider<List<Swarm>>((ref) {
  final supabase = Supabase.instance.client;

  return supabase
      .from('swarms')
      .stream(primaryKey: ['id'])
      .eq('status', 'active')
      .order('start_time')
      .limit(20)
      .map((rows) => rows.map((json) => Swarm.fromJson(json)).toList());
});

final homeCurrentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('users')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return response;
});

final userStatsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('user_stats')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  return response;
});
