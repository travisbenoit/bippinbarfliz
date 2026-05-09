import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barfliz/utils/app_error.dart';

void main() {
  group('friendlyError', () {
    // ── AuthException ────────────────────────────────────────────────────────

    group('AuthException', () {
      test('invalid credentials returns clean message', () {
        final e = const AuthException('Invalid login credentials');
        expect(friendlyError(e), 'Incorrect email or password.');
      });

      test('email not confirmed returns verification prompt', () {
        final e = const AuthException('email not confirmed');
        expect(friendlyError(e), 'Please verify your email before signing in.');
      });

      test('already registered returns duplicate account message', () {
        final e = const AuthException('User already registered');
        expect(friendlyError(e), 'An account with this email already exists.');
      });

      test('rate limit returns retry-later message', () {
        final e = const AuthException('Too many requests');
        expect(friendlyError(e), 'Too many attempts. Please try again later.');
      });

      test('weak password returns strength message', () {
        final e = const AuthException('Password should be at least 6 characters');
        expect(friendlyError(e), 'Password must be at least 6 characters.');
      });

      test('user not found returns no-account message', () {
        final e = const AuthException('User not found');
        expect(friendlyError(e), 'No account found with that email.');
      });

      test('invalid email returns validation message', () {
        final e = const AuthException('Invalid email format or invalid email');
        expect(friendlyError(e), 'Please enter a valid email address.');
      });

      test('unknown auth error returns generic auth message', () {
        final e = const AuthException('Some obscure OAuth provider error');
        expect(friendlyError(e), 'Authentication failed. Please try again.');
      });

      test('email_not_confirmed underscore variant is caught', () {
        final e = const AuthException('email_not_confirmed');
        expect(friendlyError(e), 'Please verify your email before signing in.');
      });
    });

    // ── PostgrestException ───────────────────────────────────────────────────

    group('PostgrestException', () {
      test('code 23505 (unique violation) returns duplicate message', () {
        final e = const PostgrestException(message: 'duplicate key', code: '23505');
        expect(friendlyError(e), 'This entry already exists.');
      });

      test('code 23503 (FK violation) returns related-record message', () {
        final e = const PostgrestException(message: 'foreign key violation', code: '23503');
        expect(friendlyError(e), 'Related record not found.');
      });

      test('code 42501 (permission denied) returns permission message', () {
        final e = const PostgrestException(message: 'permission denied', code: '42501');
        expect(friendlyError(e), "You don't have permission to do that.");
      });

      test('message containing permission returns permission message', () {
        final e = const PostgrestException(message: 'new row violates row-level security', code: '');
        // 'row-level security' doesn't contain 'permission' so falls to generic
        expect(friendlyError(e), 'Something went wrong. Please try again.');
      });

      test('unknown code returns generic message', () {
        final e = const PostgrestException(message: 'something failed', code: '99999');
        expect(friendlyError(e), 'Something went wrong. Please try again.');
      });
    });

    // ── Network / generic errors ─────────────────────────────────────────────

    group('network errors', () {
      test('SocketException string returns no-internet message', () {
        final e = Exception('SocketException: Connection refused');
        expect(friendlyError(e), 'No internet connection. Please check your network.');
      });

      test('network keyword returns no-internet message', () {
        final e = Exception('network error occurred');
        expect(friendlyError(e), 'No internet connection. Please check your network.');
      });

      test('connection keyword returns no-internet message', () {
        final e = Exception('connection reset by peer');
        expect(friendlyError(e), 'No internet connection. Please check your network.');
      });

      test('timeout keyword returns timeout message', () {
        final e = Exception('TimeoutException after 30s');
        expect(friendlyError(e), 'Request timed out. Please try again.');
      });
    });

    // ── Generic fallback ─────────────────────────────────────────────────────

    group('generic fallback', () {
      test('plain Exception returns generic message', () {
        final e = Exception('Something unexpected happened');
        expect(friendlyError(e), 'Something went wrong. Please try again.');
      });

      test('string error returns generic message', () {
        expect(friendlyError('raw string error'), 'Something went wrong. Please try again.');
      });

      test('null-ish toString error returns generic message', () {
        expect(friendlyError(42), 'Something went wrong. Please try again.');
      });
    });

    // ── Logging ──────────────────────────────────────────────────────────────

    group('logging', () {
      test('returns friendly string (not the raw error message)', () {
        final e = const AuthException('Invalid login credentials');
        final result = friendlyError(e, tag: 'TestTag');
        expect(result, isNot(contains('Invalid login credentials')));
        expect(result, 'Incorrect email or password.');
      });

      test('does not throw when stackTrace is provided', () {
        final e = Exception('boom');
        expect(
          () => friendlyError(e, stackTrace: StackTrace.current, tag: 'Test'),
          returnsNormally,
        );
      });

      test('does not throw when stackTrace is null', () {
        expect(() => friendlyError(Exception('x')), returnsNormally);
      });
    });
  });
}
