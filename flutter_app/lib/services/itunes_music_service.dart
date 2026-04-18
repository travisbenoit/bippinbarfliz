import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ITunesTrack {
  final String id;
  final String name;
  final String artist;
  final String? artworkUrl;
  final String? previewUrl;
  final String? collectionName;

  ITunesTrack({
    required this.id,
    required this.name,
    required this.artist,
    this.artworkUrl,
    this.previewUrl,
    this.collectionName,
  });

  factory ITunesTrack.fromJson(Map<String, dynamic> json) {
    return ITunesTrack(
      id: json['trackId']?.toString() ?? '',
      name: json['trackName'] ?? '',
      artist: json['artistName'] ?? '',
      artworkUrl: json['artworkUrl600'] ?? json['artworkUrl100'],
      previewUrl: json['previewUrl'],
      collectionName: json['collectionName'],
    );
  }
}

class PublicMusicShare {
  final String id;
  final String trackId;
  final String trackName;
  final String artistName;
  final String? artworkUrl;
  final String? previewUrl;
  final String? collectionName;
  final String sharedByUserId;
  final String createdAt;

  PublicMusicShare({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    this.artworkUrl,
    this.previewUrl,
    this.collectionName,
    required this.sharedByUserId,
    required this.createdAt,
  });

  factory PublicMusicShare.fromJson(Map<String, dynamic> json) {
    return PublicMusicShare(
      id: json['id'] ?? '',
      trackId: json['itunes_track_id'] ?? '',
      trackName: json['track_name'] ?? '',
      artistName: json['artist_name'] ?? '',
      artworkUrl: json['artwork_url'],
      previewUrl: json['preview_url'],
      collectionName: json['collection_name'],
      sharedByUserId: json['shared_by_user_id'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ITunesMusicService {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<List<ITunesTrack>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final Uri uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&entity=song&limit=20',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List? ?? [];
        return results.map((track) => ITunesTrack.fromJson(track)).toList();
      } else {
        throw Exception('Failed to search iTunes');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<PublicMusicShare?> createPublicShare({
    required String itunesTrackId,
    required String trackName,
    required String artistName,
    String? artworkUrl,
    String? previewUrl,
    String? collectionName,
  }) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return null;

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/music-share'),
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'itunesTrackId': itunesTrackId,
          'trackName': trackName,
          'artistName': artistName,
          'artworkUrl': artworkUrl,
          'previewUrl': previewUrl,
          'collectionName': collectionName,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return PublicMusicShare(
          id: json['id'],
          trackId: itunesTrackId,
          trackName: trackName,
          artistName: artistName,
          artworkUrl: artworkUrl,
          previewUrl: previewUrl,
          collectionName: collectionName,
          sharedByUserId: session.user.id,
          createdAt: DateTime.now().toIso8601String(),
        );
      } else {
        throw Exception('Failed to create share');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> playPreview(String? previewUrl) async {
    if (previewUrl == null || previewUrl.isEmpty) {
      throw Exception('No preview available');
    }

    try {
      await _audioPlayer.play(UrlSource(previewUrl));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
  }

  void shareTrack({
    required String trackName,
    required String artistName,
    required String shareId,
    String? artworkUrl,
  }) {
    final shareUrl = '$supabaseUrl/play/$shareId';
    final text = '$artistName - $trackName';

    Share.share(
      '$text\n\n$shareUrl',
      subject: 'Check out this song on Barfliz!',
    );
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
