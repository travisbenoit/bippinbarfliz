import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../i18n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localization_provider.dart';
import '../../utils/app_error.dart';
import '../../widgets/app_loader.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    try {
      await ref.read(authControllerProvider).signIn(email, _passwordController.text);

      if (!mounted) return;

      // Check if the user has completed profile setup
      final userId = Supabase.instance.client.auth.currentUser?.id;
      String? name;
      if (userId != null) {
        final row = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', userId)
            .maybeSingle();
        name = row?['name'] as String?;
      }

      if (!mounted) return;
      if (name == null || name.trim().isEmpty) {
        context.go('/profile-setup');
      } else {
        context.go('/home');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
        context.go('/verify-email?email=${Uri.encodeComponent(email)}');
      } else {
        showErrorSnackBar(context, e, tag: 'SignIn');
        if (e.statusCode == '429' || _isRateLimit(e)) _startCooldown();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'SignIn');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isRateLimit(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    return code == 'over_request_rate_limit' ||
        code == 'over_email_send_rate_limit' ||
        msg.contains('rate limit') ||
        msg.contains('too many');
  }

  void _startCooldown({int seconds = 60}) {
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _showForgotPasswordDialog() {
    final t = ref.read(tProvider);
    // Pre-fill with whatever the user already typed on the sign-in screen.
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(
        controller: resetEmailController,
        onSend: (email) =>
            ref.read(authControllerProvider).resetPassword(email),
        t: t,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(AppStrings.signInTitle),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t(AppStrings.signInSubtitle),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: t(AppStrings.fieldEmail),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: t(AppStrings.fieldPassword),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      t(AppStrings.signInForgot),
                      style: const TextStyle(color: Color(0xFFE91E63)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _cooldownSeconds > 0) ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const AppButtonLoader()
                        : Text(
                            _cooldownSeconds > 0
                                ? 'Try again in ${_cooldownSeconds}s'
                                : t(AppStrings.signInButton),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t(AppStrings.signInNoAccount),
                    ),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text(
                        t(AppStrings.signInGoSignUp),
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Forgot-password dialog — self-contained StatefulWidget so it can manage
// its own loading state without rebuilding the parent screen.
// ---------------------------------------------------------------------------

class _ForgotPasswordDialog extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String email) onSend;
  final String Function(String) t;

  const _ForgotPasswordDialog({
    required this.controller,
    required this.onSend,
    required this.t,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  bool _loading = false;

  Future<void> _submit() async {
    final email = widget.controller.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.t(AppStrings.signInEnterEmail))),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSend(email);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.t(AppStrings.signInResetEmailSent)}\nIf you don\'t see it, check your spam folder.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e, tag: 'SignIn.resetPassword');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.t(AppStrings.signInForgot)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.t(AppStrings.signInForgotDesc)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: widget.controller.text.isEmpty,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: widget.t(AppStrings.fieldEmail),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(widget.t(AppStrings.cancel)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.t(AppStrings.signInSendResetLink)),
        ),
      ],
    );
  }
}
