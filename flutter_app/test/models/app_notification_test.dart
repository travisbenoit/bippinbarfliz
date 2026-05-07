import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/screens/notifications/notifications_screen.dart';

void main() {
  final baseJson = {
    'id': 'notif-1',
    'notification_type': 'message',
    'title': 'New message',
    'body': 'Hey, are you going out tonight?',
    'metadata': {'chat_id': 'chat-99'},
    'is_read': false,
    'created_at': '2024-06-01T20:00:00.000Z',
  };

  group('AppNotification.fromJson', () {
    test('parses all fields correctly', () {
      final n = AppNotification.fromJson(baseJson);

      expect(n.id, 'notif-1');
      expect(n.type, 'message');
      expect(n.title, 'New message');
      expect(n.body, 'Hey, are you going out tonight?');
      expect(n.read, isFalse);
      expect(n.createdAt, DateTime.parse('2024-06-01T20:00:00.000Z'));
    });

    test('defaults type to "default" when notification_type is absent', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..remove('notification_type');
      final n = AppNotification.fromJson(json);
      expect(n.type, 'default');
    });

    test('defaults title and body to empty string when absent', () {
      final json = {
        ...baseJson,
        'title': null,
        'body': null,
      };
      final n = AppNotification.fromJson(json);
      expect(n.title, '');
      expect(n.body, '');
    });

    test('defaults read to false when is_read is absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('is_read');
      final n = AppNotification.fromJson(json);
      expect(n.read, isFalse);
    });

    test('parses is_read true correctly', () {
      final json = {...baseJson, 'is_read': true};
      final n = AppNotification.fromJson(json);
      expect(n.read, isTrue);
    });

    test('uses DateTime.now() when created_at is null', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final json = {...baseJson, 'created_at': null};
      final n = AppNotification.fromJson(json);
      expect(n.createdAt.isAfter(before), isTrue);
    });

    test('data defaults to empty map when metadata is absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('metadata');
      final n = AppNotification.fromJson(json);
      expect(n.data, isEmpty);
    });

    test('data is populated from metadata when present', () {
      final n = AppNotification.fromJson(baseJson);
      expect(n.data['chat_id'], 'chat-99');
    });
  });

  group('AppNotification.copyWith', () {
    test('overrides read field only', () {
      final original = AppNotification.fromJson(baseJson);
      final updated = original.copyWith(read: true);

      expect(updated.read, isTrue);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.body, original.body);
      expect(updated.type, original.type);
    });

    test('copyWith with no args returns equivalent object', () {
      final original = AppNotification.fromJson(baseJson);
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.read, original.read);
    });
  });

  group('AppNotification types', () {
    final types = ['message', 'swarm', 'gift', 'friend', 'friend_request', 'checkin', 'unknown_type'];

    test('all known type strings are parsed without error', () {
      for (final type in types) {
        final json = {...baseJson, 'notification_type': type};
        expect(() => AppNotification.fromJson(json), returnsNormally,
            reason: 'type "$type" should parse without throwing');
      }
    });
  });
}
