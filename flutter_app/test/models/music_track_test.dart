import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/music_track.dart';

void main() {
  group('MusicTrack', () {
    final baseJson = {
      'id': 'track-1',
      'itunes_track_id': '1234567890',
      'track_name': 'Blinding Lights',
      'artist_name': 'The Weeknd',
      'artwork_url': 'https://example.com/art.jpg',
      'preview_url': 'https://example.com/preview.m4a',
      'collection_name': 'After Hours',
      'created_at': '2024-05-01T12:00:00.000Z',
      'shared_by_user_id': 'user-abc',
    };

    test('fromJson parses all fields correctly', () {
      final track = MusicTrack.fromJson(baseJson);

      expect(track.id, 'track-1');
      expect(track.itunesTrackId, '1234567890');
      expect(track.trackName, 'Blinding Lights');
      expect(track.artistName, 'The Weeknd');
      expect(track.artworkUrl, 'https://example.com/art.jpg');
      expect(track.previewUrl, 'https://example.com/preview.m4a');
      expect(track.collectionName, 'After Hours');
      expect(track.createdAt, DateTime.parse('2024-05-01T12:00:00.000Z'));
      expect(track.sharedByUserId, 'user-abc');
    });

    test('fromJson handles optional null fields', () {
      final minimal = {
        'itunes_track_id': '999',
        'track_name': 'Test Song',
        'artist_name': 'Test Artist',
      };

      final track = MusicTrack.fromJson(minimal);

      expect(track.id, isNull);
      expect(track.artworkUrl, isNull);
      expect(track.previewUrl, isNull);
      expect(track.collectionName, isNull);
      expect(track.createdAt, isNull);
      expect(track.sharedByUserId, isNull);
    });

    test('toJson round-trips through fromJson', () {
      final track = MusicTrack.fromJson(baseJson);
      final json = track.toJson();
      final restored = MusicTrack.fromJson(json);

      expect(restored.id, track.id);
      expect(restored.itunesTrackId, track.itunesTrackId);
      expect(restored.trackName, track.trackName);
      expect(restored.artistName, track.artistName);
      expect(restored.artworkUrl, track.artworkUrl);
      expect(restored.previewUrl, track.previewUrl);
      expect(restored.collectionName, track.collectionName);
      expect(restored.sharedByUserId, track.sharedByUserId);
    });

    test('toJson contains all expected keys', () {
      final json = MusicTrack.fromJson(baseJson).toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('itunes_track_id'), isTrue);
      expect(json.containsKey('track_name'), isTrue);
      expect(json.containsKey('artist_name'), isTrue);
      expect(json.containsKey('artwork_url'), isTrue);
      expect(json.containsKey('preview_url'), isTrue);
      expect(json.containsKey('collection_name'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
      expect(json.containsKey('shared_by_user_id'), isTrue);
    });

    test('copyWith overrides only specified fields', () {
      final original = MusicTrack.fromJson(baseJson);
      final updated = original.copyWith(
        trackName: 'Save Your Tears',
        artistName: 'The Weeknd & Ariana Grande',
      );

      expect(updated.trackName, 'Save Your Tears');
      expect(updated.artistName, 'The Weeknd & Ariana Grande');
      // Unchanged
      expect(updated.id, original.id);
      expect(updated.itunesTrackId, original.itunesTrackId);
      expect(updated.artworkUrl, original.artworkUrl);
    });

    test('copyWith with no arguments returns identical track', () {
      final original = MusicTrack.fromJson(baseJson);
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.trackName, original.trackName);
      expect(copy.artistName, original.artistName);
      expect(copy.itunesTrackId, original.itunesTrackId);
    });
  });
}
