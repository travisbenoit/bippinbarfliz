import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns a short, user-friendly message for [error] and logs the full
/// details (including optional [stackTrace]) to the debug console.
String friendlyError(
  dynamic error, {
  StackTrace? stackTrace,
  String tag = 'App',
}) {
  debugPrint('[$tag] $error${stackTrace != null ? '\n$stackTrace' : ''}');
  return _toFriendlyMessage(error);
}

/// Shows a red error snackbar with a friendly message and logs the full error.
void showErrorSnackBar(
  BuildContext context,
  dynamic error, {
  StackTrace? stackTrace,
  String tag = 'App',
}) {
  final msg = friendlyError(error, stackTrace: stackTrace, tag: tag);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

String _toFriendlyMessage(dynamic error) {
  if (error is AuthException) {
    return _authMessage(error.message, code: error.code, statusCode: error.statusCode);
  }
  if (error is PostgrestException) {
    return _postgrestMessage(error);
  }
  if (error is StorageException) {
    return 'File upload failed. Please try again.';
  }
  final msg = error.toString().toLowerCase();
  if (msg.contains('socketexception') ||
      msg.contains('network') ||
      msg.contains('connection')) {
    return 'No internet connection. Please check your network.';
  }
  if (msg.contains('timeout')) {
    return 'Request timed out. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}

String _authMessage(String raw, {String? code, String? statusCode}) {
  // Match by Supabase error code first — more stable than text matching.
  switch (code) {
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
      return 'Too many attempts. Please try again later.';
    case 'email_not_confirmed':
      return 'Please verify your email before signing in.';
    case 'invalid_credentials':
      return 'Incorrect email or password.';
    case 'user_already_exists':
    case 'email_exists':
      return 'An account with this email already exists.';
    case 'weak_password':
      return 'Password is too weak. Please choose a stronger one.';
    case 'user_not_found':
      return 'No account found with that email.';
    case 'invalid_email':
      return 'Please enter a valid email address.';
  }
  // 429 by status code covers any unlisted rate-limit variants.
  if (statusCode == '429') return 'Too many attempts. Please try again later.';

  // Fallback: text-match for older Supabase versions or unknown codes.
  final lower = raw.toLowerCase();
  if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
    return 'Incorrect email or password.';
  }
  if (lower.contains('email not confirmed') || lower.contains('email_not_confirmed')) {
    return 'Please verify your email before signing in.';
  }
  if (lower.contains('already registered') || lower.contains('already exists')) {
    return 'An account with this email already exists.';
  }
  if (lower.contains('password') && lower.contains('6')) {
    return 'Password must be at least 6 characters.';
  }
  if (lower.contains('rate limit') || lower.contains('too many')) {
    return 'Too many attempts. Please try again later.';
  }
  if (lower.contains('user not found')) {
    return 'No account found with that email.';
  }
  if (lower.contains('weak password')) {
    return 'Password is too weak. Please choose a stronger one.';
  }
  if (lower.contains('invalid email') ||
      (lower.contains('email') && lower.contains('is invalid'))) {
    return 'Please enter a valid email address.';
  }
  return 'Authentication failed. Please try again.';
}

String _postgrestMessage(PostgrestException e) {
  // Unique constraint violations (e.g. duplicate entry)
  if (e.code == '23505') return 'This entry already exists.';
  // Foreign key violation
  if (e.code == '23503') return 'Related record not found.';
  // Row-level security / permission denied
  if (e.code == '42501' || (e.message.toLowerCase().contains('permission'))) {
    return 'You don\'t have permission to do that.';
  }
  return 'Something went wrong. Please try again.';
}
