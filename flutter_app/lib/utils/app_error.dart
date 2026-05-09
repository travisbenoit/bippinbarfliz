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
    return _authMessage(error.message);
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

String _authMessage(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('invalid login') ||
      lower.contains('invalid credentials')) {
    return 'Incorrect email or password.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Please verify your email before signing in.';
  }
  if (lower.contains('already registered') ||
      lower.contains('already exists')) {
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
  if (lower.contains('invalid email')) {
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
