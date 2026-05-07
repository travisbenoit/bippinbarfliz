import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/models/user_profile.dart';

void main() {
  // ── TonightStatus ────────────────────────────────────────────────────────────

  group('TonightStatus', () {
    test('fromString maps known values', () {
      expect(TonightStatus.fromString('out_now'), TonightStatus.outNow);
      expect(TonightStatus.fromString('going_out_soon'), TonightStatus.goingOutSoon);
      expect(TonightStatus.fromString('staying_in'), TonightStatus.stayingIn);
    });

    test('fromString returns stayingIn for null or unknown values', () {
      expect(TonightStatus.fromString(null), TonightStatus.stayingIn);
      expect(TonightStatus.fromString(''), TonightStatus.stayingIn);
      expect(TonightStatus.fromString('random'), TonightStatus.stayingIn);
    });

    test('toDbString produces correct keys', () {
      expect(TonightStatus.outNow.toDbString(), 'out_now');
      expect(TonightStatus.goingOutSoon.toDbString(), 'going_out_soon');
      expect(TonightStatus.stayingIn.toDbString(), 'staying_in');
    });

    test('toDbString round-trips through fromString', () {
      for (final status in TonightStatus.values) {
        expect(TonightStatus.fromString(status.toDbString()), status);
      }
    });

    test('displayName is non-empty for all values', () {
      for (final status in TonightStatus.values) {
        expect(status.displayName.isNotEmpty, isTrue);
      }
    });

    test('emoji is non-empty for all values', () {
      for (final status in TonightStatus.values) {
        expect(status.emoji.isNotEmpty, isTrue);
      }
    });
  });

  // ── UserProfile ──────────────────────────────────────────────────────────────

  group('UserProfile', () {
    final baseJson = {
      'id': 'user-abc',
      'name': 'Alice',
      'username': 'alice_bar',
      'bio': 'Love craft beer',
      'home_city': 'Darwin',
      'tonight_status': 'out_now',
      'vibe_tags': ['Bar Crawl', 'Live Music'],
      'favorite_drinks': ['IPA', 'Margarita'],
      'interests': ['Music', 'Sports'],
      'last_known_lat': -12.4634,
      'last_known_lng': 130.8456,
      'last_active_at': '2024-06-01T20:00:00.000Z',
      'avatar_url': 'https://example.com/avatar.jpg',
      'created_at': '2024-01-01T00:00:00.000Z',
      'is_premium': true,
      'age': 28,
      'lush_coin_balance': 150,
      'venmo_linked': true,
      'venmo_username': 'alice-v',
      'ghost_mode': false,
      'privacy_mode': 'friends_only',
      'is_dd_tonight': false,
      'verified_profile': true,
      'occupation': 'Engineer',
      'education': 'BSc Computer Science',
      'looking_for': 'Friends',
      'fun_fact': 'Can juggle',
      'instagram_username': 'alice_insta',
      'spotify_username': 'alice_spot',
      'payment_provider_linked': true,
      'payment_provider': 'stripe',
      'payment_provider_username': 'alice_pay',
      'first_drink_on_me': true,
      'weather_location': 'Darwin, NT',
    };

    test('fromJson parses all fields correctly', () {
      final profile = UserProfile.fromJson(baseJson);

      expect(profile.id, 'user-abc');
      expect(profile.name, 'Alice');
      expect(profile.username, 'alice_bar');
      expect(profile.bio, 'Love craft beer');
      expect(profile.homeCity, 'Darwin');
      expect(profile.tonightStatus, TonightStatus.outNow);
      expect(profile.vibeTags, ['Bar Crawl', 'Live Music']);
      expect(profile.favoriteDrinks, ['IPA', 'Margarita']);
      expect(profile.interests, ['Music', 'Sports']);
      expect(profile.lastKnownLat, -12.4634);
      expect(profile.lastKnownLng, 130.8456);
      expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(profile.isPremium, true);
      expect(profile.age, 28);
      expect(profile.lushCoinBalance, 150);
      expect(profile.venmoLinked, true);
      expect(profile.venmoUsername, 'alice-v');
      expect(profile.ghostMode, false);
      expect(profile.privacyMode, 'friends_only');
      expect(profile.isDdTonight, false);
      expect(profile.verifiedProfile, true);
      expect(profile.occupation, 'Engineer');
      expect(profile.funFact, 'Can juggle');
      expect(profile.instagramUsername, 'alice_insta');
      expect(profile.spotifyUsername, 'alice_spot');
      expect(profile.paymentProviderLinked, true);
      expect(profile.paymentProvider, 'stripe');
      expect(profile.firstDrinkOnMe, true);
      expect(profile.weatherLocation, 'Darwin, NT');
    });

    test('fromJson uses defaults for null optional fields', () {
      final minimal = {
        'id': 'user-min',
        'name': null,
        'tonight_status': null,
      };

      final profile = UserProfile.fromJson(minimal);

      expect(profile.name, 'Unknown');
      expect(profile.tonightStatus, TonightStatus.stayingIn);
      expect(profile.vibeTags, isEmpty);
      expect(profile.favoriteDrinks, isEmpty);
      expect(profile.interests, isEmpty);
      expect(profile.isPremium, false);
      expect(profile.lushCoinBalance, 0);
      expect(profile.ghostMode, false);
      expect(profile.privacyMode, 'public');
      expect(profile.isDdTonight, false);
      expect(profile.verifiedProfile, false);
      expect(profile.paymentProviderLinked, false);
      expect(profile.firstDrinkOnMe, false);
    });

    test('toJson round-trips all fields', () {
      final profile = UserProfile.fromJson(baseJson);
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.tonightStatus, profile.tonightStatus);
      expect(restored.vibeTags, profile.vibeTags);
      expect(restored.isPremium, profile.isPremium);
      expect(restored.lushCoinBalance, profile.lushCoinBalance);
      expect(restored.ghostMode, profile.ghostMode);
      expect(restored.privacyMode, profile.privacyMode);
    });

    test('copyWith overrides only specified fields', () {
      final original = UserProfile.fromJson(baseJson);
      final updated = original.copyWith(
        name: 'Bob',
        tonightStatus: TonightStatus.goingOutSoon,
        lushCoinBalance: 200,
      );

      expect(updated.name, 'Bob');
      expect(updated.tonightStatus, TonightStatus.goingOutSoon);
      expect(updated.lushCoinBalance, 200);
      // Unchanged fields preserved
      expect(updated.id, original.id);
      expect(updated.bio, original.bio);
      expect(updated.vibeTags, original.vibeTags);
      expect(updated.isPremium, original.isPremium);
    });

    test('copyWith with no arguments returns identical profile', () {
      final original = UserProfile.fromJson(baseJson);
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.username, original.username);
      expect(copy.tonightStatus, original.tonightStatus);
      expect(copy.ghostMode, original.ghostMode);
    });
  });
}
