import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/swarm.dart';

void main() {
  group('Swarm', () {
    final baseJson = {
      'id': 'swarm-1',
      'creator_id': 'user-abc',
      'title': 'Bar Crawl Saturday',
      'description': 'Hitting the best spots downtown',
      'venue_id': 'venue-1',
      'start_time': '2024-06-15T21:00:00.000Z',
      'max_attendees': 20,
      'status': 'active',
      'vibe_tags': ['Bar Crawl', 'Live Music'],
      'lat': -12.4634,
      'lng': 130.8456,
      'created_at': '2024-06-14T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final swarm = Swarm.fromJson(baseJson);

      expect(swarm.id, 'swarm-1');
      expect(swarm.creatorId, 'user-abc');
      expect(swarm.title, 'Bar Crawl Saturday');
      expect(swarm.description, 'Hitting the best spots downtown');
      expect(swarm.venueId, 'venue-1');
      expect(swarm.startTime, DateTime.parse('2024-06-15T21:00:00.000Z'));
      expect(swarm.maxAttendees, 20);
      expect(swarm.status, 'active');
      expect(swarm.vibeTags, ['Bar Crawl', 'Live Music']);
      expect(swarm.lat, -12.4634);
      expect(swarm.lng, 130.8456);
      expect(swarm.createdAt, DateTime.parse('2024-06-14T10:00:00.000Z'));
    });

    test('fromJson handles optional null fields', () {
      final minimal = {
        'id': 'swarm-2',
        'creator_id': 'user-xyz',
        'title': 'Quick Drinks',
        'start_time': '2024-06-20T18:00:00.000Z',
        'max_attendees': 5,
        'status': 'active',
        'created_at': '2024-06-20T12:00:00.000Z',
      };

      final swarm = Swarm.fromJson(minimal);

      expect(swarm.description, isNull);
      expect(swarm.venueId, isNull);
      expect(swarm.vibeTags, isEmpty);
      expect(swarm.lat, isNull);
      expect(swarm.lng, isNull);
    });

    test('fromJson parses lat/lng as double from int', () {
      final json = {
        ...baseJson,
        'lat': -12,
        'lng': 130,
      };
      final swarm = Swarm.fromJson(json);
      expect(swarm.lat, -12.0);
      expect(swarm.lng, 130.0);
    });

    test('toJson round-trips through fromJson', () {
      final swarm = Swarm.fromJson(baseJson);
      final json = swarm.toJson();
      final restored = Swarm.fromJson(json);

      expect(restored.id, swarm.id);
      expect(restored.creatorId, swarm.creatorId);
      expect(restored.title, swarm.title);
      expect(restored.description, swarm.description);
      expect(restored.maxAttendees, swarm.maxAttendees);
      expect(restored.status, swarm.status);
      expect(restored.vibeTags, swarm.vibeTags);
      expect(restored.startTime, swarm.startTime);
    });

    test('toJson contains all expected keys', () {
      final json = Swarm.fromJson(baseJson).toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('creator_id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('venue_id'), isTrue);
      expect(json.containsKey('start_time'), isTrue);
      expect(json.containsKey('max_attendees'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('vibe_tags'), isTrue);
      expect(json.containsKey('lat'), isTrue);
      expect(json.containsKey('lng'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });

    test('start_time is serialised as ISO 8601 string', () {
      final json = Swarm.fromJson(baseJson).toJson();
      final startTime = json['start_time'] as String;
      // Must parse without throwing
      expect(() => DateTime.parse(startTime), returnsNormally);
    });
  });
}
