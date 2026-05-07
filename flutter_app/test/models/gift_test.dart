import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/gift.dart';

void main() {
  group('Gift', () {
    final baseJson = {
      'id': 'gift-1',
      'from_user_id': 'user-a',
      'to_user_id': 'user-b',
      'drink_type': 'Beer',
      'amount': 12.50,
      'message': 'Cheers!',
      'status': 'pending',
      'venue_id': 'venue-1',
      'redeemed_at': null,
      'created_at': '2024-06-01T19:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final gift = Gift.fromJson(baseJson);

      expect(gift.id, 'gift-1');
      expect(gift.fromUserId, 'user-a');
      expect(gift.toUserId, 'user-b');
      expect(gift.drinkType, 'Beer');
      expect(gift.amount, 12.50);
      expect(gift.message, 'Cheers!');
      expect(gift.status, 'pending');
      expect(gift.venueId, 'venue-1');
      expect(gift.redeemedAt, isNull);
      expect(gift.createdAt, DateTime.parse('2024-06-01T19:00:00.000Z'));
    });

    test('fromJson coerces int amount to double', () {
      final json = {...baseJson, 'amount': 10};
      final gift = Gift.fromJson(json);
      expect(gift.amount, 10.0);
      expect(gift.amount, isA<double>());
    });

    test('fromJson parses redeemed_at when present', () {
      final json = {
        ...baseJson,
        'redeemed_at': '2024-06-02T21:00:00.000Z',
      };
      final gift = Gift.fromJson(json);
      expect(gift.redeemedAt, DateTime.parse('2024-06-02T21:00:00.000Z'));
    });

    test('fromJson handles optional null fields', () {
      final json = {
        ...baseJson,
        'message': null,
        'venue_id': null,
        'redeemed_at': null,
      };
      final gift = Gift.fromJson(json);

      expect(gift.message, isNull);
      expect(gift.venueId, isNull);
      expect(gift.redeemedAt, isNull);
    });

    test('toJson round-trips through fromJson', () {
      final gift = Gift.fromJson(baseJson);
      final json = gift.toJson();
      final restored = Gift.fromJson(json);

      expect(restored.id, gift.id);
      expect(restored.fromUserId, gift.fromUserId);
      expect(restored.toUserId, gift.toUserId);
      expect(restored.drinkType, gift.drinkType);
      expect(restored.amount, gift.amount);
      expect(restored.status, gift.status);
    });

    test('toJson contains all expected keys', () {
      final json = Gift.fromJson(baseJson).toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('from_user_id'), isTrue);
      expect(json.containsKey('to_user_id'), isTrue);
      expect(json.containsKey('drink_type'), isTrue);
      expect(json.containsKey('amount'), isTrue);
      expect(json.containsKey('message'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('venue_id'), isTrue);
      expect(json.containsKey('redeemed_at'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
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
