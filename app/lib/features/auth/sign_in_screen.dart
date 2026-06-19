import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/brand_wordmark.dart';
import 'auth_providers.dart';
import 'phone_sign_in_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Turns raw auth exceptions into messages a person can actually act on.
  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address doesn\'t look right.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support for help.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for that email. Try signing in.';
        case 'weak-password':
          return 'Please choose a stronger password (at least 6 characters).';
        case 'operation-not-allowed':
          return 'This sign-in method isn\'t enabled in Firebase. '
              'Enable it under Authentication → Sign-in method.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'user-cancelled':
        case 'web-context-cancelled':
          return 'Sign-in was cancelled.';
        case 'popup-blocked':
          return 'Your browser blocked the sign-in popup. '
              'Allow popups for this site and try again.';
        case 'unauthorized-domain':
          return 'This domain isn\'t authorized for sign-in. Add it under '
              'Firebase Authentication → Settings → Authorized domains.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method.';
        default:
          // Surface the code so unmapped failures are diagnosable instead of
          // showing an opaque "Error".
          final msg = error.message;
          return msg == null || msg.isEmpty || msg == 'Error'
              ? 'Sign-in failed (${error.code}).'
              : 'Sign-in failed (${error.code}): $msg';
      }
    }
    return 'Something went wrong: $error';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(authRepositoryProvider);
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrandWordmark(style: t.textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(AppConfig.tagline,
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => _register
                            ? repo.registerWithEmail(
                                _email.text.trim(), _password.text)
                            : repo.signInWithEmail(
                                _email.text.trim(), _password.text)),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(repo.signInWithGoogle),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(repo.signInWithApple),
                    icon: const Icon(Icons.apple, size: 22),
                    label: const Text('Continue with Apple'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PhoneSignInScreen(),
                              ),
                            ),
                    icon: const Icon(Icons.phone_outlined, size: 22),
                    label: const Text('Continue with phone'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        _busy ? null : () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'Have an account? Sign in'
                        : 'New here? Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
