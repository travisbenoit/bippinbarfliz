import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/venue.dart';

void main() {
  group('Venue', () {
    final baseJson = {
      'id': 'venue-1',
      'name': 'The Darwin Bar',
      'address': '123 Smith St, Darwin NT 0800',
      'lat': -12.4634,
      'lng': 130.8456,
      'category': 'Bar',
      'verified': true,
      'photo_url': 'https://example.com/photo.jpg',
      'place_id': 'ChIJ_place123',
      'rating': 4.5,
      'user_ratings_total': 128,
      'created_at': '2024-01-15T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final venue = Venue.fromJson(baseJson);

      expect(venue.id, 'venue-1');
      expect(venue.name, 'The Darwin Bar');
      expect(venue.address, '123 Smith St, Darwin NT 0800');
      expect(venue.lat, -12.4634);
      expect(venue.lng, 130.8456);
      expect(venue.category, 'Bar');
      expect(venue.verified, true);
      expect(venue.photoUrl, 'https://example.com/photo.jpg');
      expect(venue.placeId, 'ChIJ_place123');
      expect(venue.rating, 4.5);
      expect(venue.userRatingsTotal, 128);
      expect(venue.createdAt, DateTime.parse('2024-01-15T10:00:00.000Z'));
    });

    test('fromJson handles optional null fields', () {
      final minimalJson = {
        'id': 'venue-2',
        'name': 'Simple Bar',
        'address': '1 Main St',
        'lat': -12.0,
        'lng': 130.0,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final venue = Venue.fromJson(minimalJson);

      expect(venue.category, isNull);
      expect(venue.verified, false);
      expect(venue.photoUrl, isNull);
      expect(venue.placeId, isNull);
      expect(venue.rating, isNull);
      expect(venue.userRatingsTotal, isNull);
    });

    test('fromJson accepts integer lat/lng (num coercion)', () {
      final json = {
        ...baseJson,
        'lat': -12,
        'lng': 130,
        'rating': 4,
      };
      final venue = Venue.fromJson(json);
      expect(venue.lat, -12.0);
      expect(venue.lng, 130.0);
      expect(venue.rating, 4.0);
    });

    test('toJson round-trips through fromJson', () {
      final venue = Venue.fromJson(baseJson);
      final json = venue.toJson();
      final restored = Venue.fromJson(json);

      expect(restored.id, venue.id);
      expect(restored.name, venue.name);
      expect(restored.address, venue.address);
      expect(restored.lat, venue.lat);
      expect(restored.lng, venue.lng);
      expect(restored.category, venue.category);
      expect(restored.verified, venue.verified);
      expect(restored.rating, venue.rating);
    });

    test('toJson includes all keys', () {
      final venue = Venue.fromJson(baseJson);
      final json = venue.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('address'), isTrue);
      expect(json.containsKey('lat'), isTrue);
      expect(json.containsKey('lng'), isTrue);
      expect(json.containsKey('category'), isTrue);
      expect(json.containsKey('verified'), isTrue);
      expect(json.containsKey('photo_url'), isTrue);
      expect(json.containsKey('place_id'), isTrue);
      expect(json.containsKey('rating'), isTrue);
      expect(json.containsKey('user_ratings_total'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });
  });
}
