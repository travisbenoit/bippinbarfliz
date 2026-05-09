import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/swarm.dart';

void main() {
  group('Swarm', () {
    final baseJson = {
      'id': 'swarm-1',
      'host_user_id': 'user-abc',
      'title': 'Bar Crawl Saturday',
      'description': 'Hitting the best spots downtown',
      'venue_id': 'venue-1',
      'venue_name': 'The Rusty Nail',
      'start_time': '2024-06-15T21:00:00.000Z',
      'max_size': 20,
      'current_size': 5,
      'status': 'active',
      'vibe_tags': ['Bar Crawl', 'Live Music'],
      'created_at': '2024-06-14T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final swarm = Swarm.fromJson(baseJson);

      expect(swarm.id, 'swarm-1');
      expect(swarm.creatorId, 'user-abc');
      expect(swarm.title, 'Bar Crawl Saturday');
      expect(swarm.description, 'Hitting the best spots downtown');
      expect(swarm.venueId, 'venue-1');
      expect(swarm.venueName, 'The Rusty Nail');
      expect(swarm.startTime, DateTime.parse('2024-06-15T21:00:00.000Z'));
      expect(swarm.maxSize, 20);
      expect(swarm.currentSize, 5);
      expect(swarm.status, 'active');
      expect(swarm.vibeTags, ['Bar Crawl', 'Live Music']);
      expect(swarm.createdAt, DateTime.parse('2024-06-14T10:00:00.000Z'));
    });

    test('fromJson handles optional null fields', () {
      final minimal = {
        'id': 'swarm-2',
        'host_user_id': 'user-xyz',
        'title': 'Quick Drinks',
        'start_time': '2024-06-20T18:00:00.000Z',
        'created_at': '2024-06-20T12:00:00.000Z',
      };

      final swarm = Swarm.fromJson(minimal);

      expect(swarm.description, isNull);
      expect(swarm.venueId, isNull);
      expect(swarm.venueName, isNull);
      expect(swarm.vibeTags, isEmpty);
    });

    test('fromJson applies defaults when optional int fields are absent', () {
      final minimal = {
        'id': 'swarm-3',
        'host_user_id': 'user-xyz',
        'title': 'Quick Drinks',
        'start_time': '2024-06-20T18:00:00.000Z',
        'created_at': '2024-06-20T12:00:00.000Z',
      };

      final swarm = Swarm.fromJson(minimal);

      expect(swarm.maxSize, 50);
      expect(swarm.currentSize, 1);
      expect(swarm.status, 'active');
    });

    test('toJson round-trips through fromJson', () {
      final swarm = Swarm.fromJson(baseJson);
      final json = swarm.toJson();
      final restored = Swarm.fromJson(json);

      expect(restored.id, swarm.id);
      expect(restored.creatorId, swarm.creatorId);
      expect(restored.title, swarm.title);
      expect(restored.description, swarm.description);
      expect(restored.venueId, swarm.venueId);
      expect(restored.venueName, swarm.venueName);
      expect(restored.maxSize, swarm.maxSize);
      expect(restored.currentSize, swarm.currentSize);
      expect(restored.status, swarm.status);
      expect(restored.vibeTags, swarm.vibeTags);
      expect(restored.startTime, swarm.startTime);
    });

    test('toJson contains all expected keys', () {
      final json = Swarm.fromJson(baseJson).toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('host_user_id'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('description'), isTrue);
      expect(json.containsKey('venue_id'), isTrue);
      expect(json.containsKey('venue_name'), isTrue);
      expect(json.containsKey('start_time'), isTrue);
      expect(json.containsKey('max_size'), isTrue);
      expect(json.containsKey('current_size'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('vibe_tags'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });

    test('start_time is serialised as ISO 8601 string', () {
      final json = Swarm.fromJson(baseJson).toJson();
      final startTime = json['start_time'] as String;
      expect(() => DateTime.parse(startTime), returnsNormally);
    });
  });
}
