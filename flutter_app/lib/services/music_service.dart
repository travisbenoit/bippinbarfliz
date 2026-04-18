import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/music_track.dart';
import '../models/music_search_result.dart';
import 'supabase_service.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  // iTunes Search API
  Future<List<MusicSearchResult>> searchItunes(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=$encodedQuery&media=music&limit=10',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .map((json) => MusicSearchResult.fromItunes(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching iTunes: $e');
      return [];
    }
  }

  // Share music with another user
  Future<String?> shareMusic({
    required MusicSearchResult track,
  }) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabaseService.client.functions.invoke(
        'music-share',
        body: {
          'itunesTrackId': track.itunesTrackId,
          'trackName': track.trackName,
          'artistName': track.artistName,
          'artworkUrl': track.artworkUrl,
          'previewUrl': track.previewUrl,
          'collectionName': track.collectionName,
        },
      );

      return response.data['id'] as String?;
    } catch (e) {
      print('Error sharing music: $e');
      return null;
    }
  }

  // Get shared music details
  Future<MusicTrack?> getSharedMusic(String shareId) async {
    try {
      final response = await _supabaseService.client.functions.invoke(
        'music-share/$shareId',
        method: HttpMethod.get,
      );

      return MusicTrack.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error getting shared music: $e');
      return null;
    }
  }

  // Get user's music shares
  Future<List<MusicTrack>> getUserMusicShares() async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final data = await _supabaseService.client
          .from('public_music_shares')
          .select(
            'id, itunes_track_id, track_name, artist_name, artwork_url, preview_url, collection_name, created_at, shared_by_user_id',
          )
          .eq('shared_by_user_id', userId)
          .order('created_at', ascending: false);

      return data.map((json) => MusicTrack.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user music shares: $e');
      return [];
    }
  }

  // Stream recent music shares
  Stream<List<MusicTrack>> streamRecentMusicShares() {
    return _supabaseService.client
        .from('public_music_shares')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(20)
        .map((data) => data.map((json) => MusicTrack.fromJson(json)).toList())
        .handleError((e) {
          print('Error streaming music shares: $e');
          return <MusicTrack>[];
        });
  }
}
