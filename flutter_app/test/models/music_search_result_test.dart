import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/music_search_result.dart';

void main() {
  group('MusicSearchResult.fromItunes', () {
    final itunesJson = {
      'trackId': 1234567890,
      'trackName': 'Blinding Lights',
      'artistName': 'The Weeknd',
      'artworkUrl100': 'https://example.com/art100.jpg',
      'artworkUrl60': 'https://example.com/art60.jpg',
      'previewUrl': 'https://example.com/preview.m4a',
      'collectionName': 'After Hours',
      'releaseDate': '2020-01-01T00:00:00Z',
    };

    test('parses all fields from iTunes response', () {
      final result = MusicSearchResult.fromItunes(itunesJson);

      expect(result.itunesTrackId, '1234567890');
      expect(result.trackName, 'Blinding Lights');
      expect(result.artistName, 'The Weeknd');
      expect(result.artworkUrl, 'https://example.com/art100.jpg');
      expect(result.previewUrl, 'https://example.com/preview.m4a');
      expect(result.collectionName, 'After Hours');
      expect(result.releaseDate, '2020-01-01T00:00:00Z');
      expect(result.platform, 'iTunes');
    });

    test('falls back to artworkUrl60 when artworkUrl100 is absent', () {
      final json = Map<String, dynamic>.from(itunesJson)
        ..remove('artworkUrl100');

      final result = MusicSearchResult.fromItunes(json);

      expect(result.artworkUrl, 'https://example.com/art60.jpg');
    });

    test('trackId is converted to string', () {
      final result = MusicSearchResult.fromItunes(itunesJson);
      expect(result.itunesTrackId, isA<String>());
      expect(result.itunesTrackId, '1234567890');
    });

    test('handles missing optional fields gracefully', () {
      final minimal = {
        'trackId': 999,
        'trackName': 'Some Song',
        'artistName': 'Some Artist',
      };

      final result = MusicSearchResult.fromItunes(minimal);

      expect(result.itunesTrackId, '999');
      expect(result.trackName, 'Some Song');
      expect(result.artistName, 'Some Artist');
      expect(result.artworkUrl, isNull);
      expect(result.previewUrl, isNull);
      expect(result.collectionName, isNull);
    });

    test('null track/artist name falls back to Unknown', () {
      final json = {
        'trackId': 1,
        'trackName': null,
        'artistName': null,
      };

      final result = MusicSearchResult.fromItunes(json);

      expect(result.trackName, 'Unknown');
      expect(result.artistName, 'Unknown');
    });
  });
}
