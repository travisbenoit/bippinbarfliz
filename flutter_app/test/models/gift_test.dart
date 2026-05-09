import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/gift.dart';

void main() {
  group('Gift', () {
    final baseJson = {
      'id': 'gift-1',
      'from_user_id': 'user-a',
      'to_user_id': 'user-b',
      'item_id': 'item-beer-1',
      'message': 'Cheers!',
      'status': 'pending',
      'context_type': 'profile',
      'redeemed_at': null,
      'created_at': '2024-06-01T19:00:00.000Z',
    };

    test('fromJson parses all required fields correctly', () {
      final gift = Gift.fromJson(baseJson);

      expect(gift.id, 'gift-1');
      expect(gift.fromUserId, 'user-a');
      expect(gift.toUserId, 'user-b');
      expect(gift.itemId, 'item-beer-1');
      expect(gift.message, 'Cheers!');
      expect(gift.status, 'pending');
      expect(gift.contextType, 'profile');
      expect(gift.redeemedAt, isNull);
      expect(gift.createdAt, DateTime.parse('2024-06-01T19:00:00.000Z'));
    });

    test('fromJson parses joined virtual_items fields', () {
      final json = {
        ...baseJson,
        'virtual_items': {'name': 'Cold Beer', 'emoji': '🍺', 'price': 50},
      };
      final gift = Gift.fromJson(json);

      expect(gift.itemName, 'Cold Beer');
      expect(gift.itemEmoji, '🍺');
      expect(gift.itemPrice, 50);
    });

    test('fromJson parses joined users (sender) name', () {
      final json = {
        ...baseJson,
        'users': {'name': 'Alice'},
      };
      final gift = Gift.fromJson(json);

      expect(gift.fromUserName, 'Alice');
    });

    test('fromJson returns null joined fields when not present', () {
      final gift = Gift.fromJson(baseJson);

      expect(gift.itemName, isNull);
      expect(gift.itemEmoji, isNull);
      expect(gift.itemPrice, isNull);
      expect(gift.fromUserName, isNull);
    });

    test('fromJson parses redeemed_at when present', () {
      final json = {
        ...baseJson,
        'redeemed_at': '2024-06-02T21:00:00.000Z',
      };
      final gift = Gift.fromJson(json);
      expect(gift.redeemedAt, DateTime.parse('2024-06-02T21:00:00.000Z'));
    });

    test('fromJson handles optional null message', () {
      final json = {...baseJson, 'message': null};
      final gift = Gift.fromJson(json);
      expect(gift.message, isNull);
    });

    test('fromJson defaults status to pending when absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('status');
      final gift = Gift.fromJson(json);
      expect(gift.status, 'pending');
    });

    test('fromJson defaults context_type to profile when absent', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('context_type');
      final gift = Gift.fromJson(json);
      expect(gift.contextType, 'profile');
    });

    // ── Computed status properties ────────────────────────────────────────────

    group('isPending', () {
      test('returns true when status is pending', () {
        final gift = Gift.fromJson(baseJson);
        expect(gift.isPending, isTrue);
        expect(gift.isRedeemed, isFalse);
        expect(gift.isExpired, isFalse);
      });
    });

    group('isRedeemed', () {
      test('returns true when status is redeemed', () {
        final json = {...baseJson, 'status': 'redeemed'};
        final gift = Gift.fromJson(json);
        expect(gift.isRedeemed, isTrue);
        expect(gift.isPending, isFalse);
        expect(gift.isExpired, isFalse);
      });
    });

    group('isExpired', () {
      test('returns true when status is expired', () {
        final json = {...baseJson, 'status': 'expired'};
        final gift = Gift.fromJson(json);
        expect(gift.isExpired, isTrue);
        expect(gift.isPending, isFalse);
        expect(gift.isRedeemed, isFalse);
      });
    });

    test('unknown status returns false for all computed props', () {
      final json = {...baseJson, 'status': 'cancelled'};
      final gift = Gift.fromJson(json);
      expect(gift.isPending, isFalse);
      expect(gift.isRedeemed, isFalse);
      expect(gift.isExpired, isFalse);
    });
  });
}
