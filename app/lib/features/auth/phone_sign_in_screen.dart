import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Phone-number sign-in: enter a number, then the SMS code.
class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _sendCode() async {
    final number = _phone.text.trim();
    if (number.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).startPhoneSignIn(
            phoneNumber: number,
            codeSent: (verificationId) {
              if (!mounted) return;
              setState(() {
                _verificationId = verificationId;
                _busy = false;
              });
              _snack('Code sent to $number');
            },
            onAutoVerified: () {
              // Sign-in completed automatically; router redirects to /home.
            },
            onError: (message) {
              if (!mounted) return;
              setState(() => _busy = false);
              _snack(message);
            },
          );
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _snack('$e');
    }
  }

  Future<void> _confirm() async {
    final id = _verificationId;
    if (id == null || _code.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmPhoneCode(id, _code.text.trim());
      // Auth state change triggers the router redirect to /home.
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _snack('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeStep = _verificationId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Phone sign-in')),
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
                  Text(
                    codeStep ? 'Enter the code' : 'What\'s your number?',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    codeStep
                        ? 'We sent a 6-digit code via SMS.'
                        : 'Use the international format, e.g. +254712345678.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!codeStep)
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    )
                  else
                    TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'SMS code',
                        prefixIcon: Icon(Icons.sms_outlined),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : (codeStep ? _confirm : _sendCode),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(codeStep ? 'Verify & continue' : 'Send code'),
                  ),
                  if (codeStep) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _verificationId = null;
                                _code.clear();
                              }),
                      child: const Text('Change number'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
