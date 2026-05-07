import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/i18n/app_strings.dart';

void main() {
  group('AppStrings constants', () {
    // Gather all string constants via reflection-free introspection.
    // Each constant is tested individually.

    test('common keys have correct dot-notation format', () {
      expect(AppStrings.ok, 'common.ok');
      expect(AppStrings.cancel, 'common.cancel');
      expect(AppStrings.save, 'common.save');
      expect(AppStrings.close, 'common.close');
      expect(AppStrings.done, 'common.done');
      expect(AppStrings.next, 'common.next');
      expect(AppStrings.skip, 'common.skip');
      expect(AppStrings.back, 'common.back');
      expect(AppStrings.confirm, 'common.confirm');
      expect(AppStrings.error, 'common.error');
      expect(AppStrings.loading, 'common.loading');
      expect(AppStrings.retry, 'common.retry');
      expect(AppStrings.send, 'common.send');
      expect(AppStrings.search, 'common.search');
      expect(AppStrings.appName, 'common.app_name');
    });

    test('auth keys have correct dot-notation format', () {
      expect(AppStrings.signInTitle, 'auth.sign_in_title');
      expect(AppStrings.signInButton, 'auth.sign_in_button');
      expect(AppStrings.signUpTitle, 'auth.sign_up_title');
      expect(AppStrings.signUpButton, 'auth.sign_up_button');
      expect(AppStrings.fieldEmail, 'auth.field_email');
      expect(AppStrings.fieldPassword, 'auth.field_password');
      expect(AppStrings.fieldName, 'auth.field_name');
      expect(AppStrings.signOut, 'auth.sign_out');
    });

    test('nav keys have correct dot-notation format', () {
      expect(AppStrings.navHome, 'nav.home');
      expect(AppStrings.navMap, 'nav.map');
      expect(AppStrings.navMessages, 'nav.messages');
      expect(AppStrings.navProfile, 'nav.profile');
      expect(AppStrings.navMore, 'nav.more');
      expect(AppStrings.moreFriends, 'nav.more_friends');
      expect(AppStrings.moreHistory, 'nav.more_history');
      expect(AppStrings.morePayments, 'nav.more_payments');
      expect(AppStrings.moreLeaderboard, 'nav.more_leaderboard');
    });

    test('swarm keys are present and correctly prefixed', () {
      expect(AppStrings.swarmsCreate.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsPublish.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsNameLabel.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsNameHint.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsNameRequired.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsDescLabel.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsDescHint.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsStartTimeLabel.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsPickTime.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsMaxAttendeesLabel.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsVibeTagsLabel.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsCreateSuccess.startsWith('swarms.'), isTrue);
      expect(AppStrings.swarmsCreateFailed.startsWith('swarms.'), isTrue);
    });

    test('all keys use only lowercase letters, digits, dots and underscores', () {
      final keys = [
        AppStrings.ok, AppStrings.cancel, AppStrings.save,
        AppStrings.signInTitle, AppStrings.signUpTitle,
        AppStrings.navHome, AppStrings.navMessages,
        AppStrings.swarmsCreate, AppStrings.swarmsPublish,
        AppStrings.moreFriends, AppStrings.moreHistory,
      ];

      final validPattern = RegExp(r'^[a-z0-9_.]+$');
      for (final key in keys) {
        expect(validPattern.hasMatch(key), isTrue,
            reason: '$key contains invalid characters');
      }
    });
  });

  group('AppStrings.englishFallback', () {
    test('map is not empty', () {
      expect(AppStrings.englishFallback, isNotEmpty);
    });

    test('common keys have non-empty English translations', () {
      expect(AppStrings.englishFallback[AppStrings.ok], 'OK');
      expect(AppStrings.englishFallback[AppStrings.cancel], 'Cancel');
      expect(AppStrings.englishFallback[AppStrings.save], 'Save');
      expect(AppStrings.englishFallback[AppStrings.appName], 'Barfliz');
    });

    test('auth keys have non-empty English translations', () {
      expect(AppStrings.englishFallback[AppStrings.signInTitle], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.signInButton], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.signUpTitle], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.fieldEmail], 'Email');
      expect(AppStrings.englishFallback[AppStrings.fieldPassword], 'Password');
    });

    test('nav keys have non-empty English translations', () {
      expect(AppStrings.englishFallback[AppStrings.navHome], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.navMessages], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.navProfile], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.navMore], isNotEmpty);
    });

    test('swarm keys have non-empty English translations', () {
      expect(AppStrings.englishFallback[AppStrings.swarmsCreate], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.swarmsPublish], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.swarmsNameLabel], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.swarmsNameRequired], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.swarmsCreateSuccess], isNotEmpty);
      expect(AppStrings.englishFallback[AppStrings.swarmsCreateFailed], isNotEmpty);
    });

    test('no value in the fallback map is null or empty', () {
      for (final entry in AppStrings.englishFallback.entries) {
        expect(entry.value, isNotEmpty,
            reason: 'englishFallback["${entry.key}"] must not be empty');
      }
    });

    test('all fallback keys follow dot-notation convention', () {
      final validPattern = RegExp(r'^[a-z0-9_.]+$');
      for (final key in AppStrings.englishFallback.keys) {
        expect(key.contains('.'), isTrue,
            reason: '"$key" should contain a dot separator');
        expect(validPattern.hasMatch(key), isTrue,
            reason: '"$key" contains invalid characters');
      }
    });
  });
}
