import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../domain/entities/account_type.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _handle = TextEditingController();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  AccountType _type = AccountType.businessOwner;
  String _industry = AppConfig.industries.first;
  bool _busy = false;

  @override
  void dispose() {
    _handle.dispose();
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = ref.read(authStateChangesProvider).value;
    if (auth == null) return;
    setState(() => _busy = true);
    try {
      final users = ref.read(userRepositoryProvider);
      final handle = _handle.text.trim();
      if (handle.isNotEmpty) await users.claimHandle(handle);
      await users.completeOnboarding(
        uid: auth.uid,
        displayName:
            _name.text.trim().isEmpty ? 'New Member' : _name.text.trim(),
        accountType: _type,
        industry: _industry,
        bio: _bio.text.trim(),
      );
      // The router redirects to /home automatically when onboardingComplete flips.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
                'Tell the community who you are — this powers your feed and who you’re matched with.'),
            const SizedBox(height: 20),
            TextField(
              controller: _handle,
              decoration: const InputDecoration(
                  labelText: '@handle (3–20: a–z, 0–9, _)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: [
                for (final a in AccountType.values)
                  DropdownMenuItem(value: a, child: Text(a.label)),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _industry,
              decoration: const InputDecoration(labelText: 'Industry'),
              items: [
                for (final i in AppConfig.industries)
                  DropdownMenuItem(value: i, child: Text(i)),
              ],
              onChanged: (v) => setState(() => _industry = v ?? _industry),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bio,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Short bio'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Finish & enter MySpot'),
            ),
          ],
        ),
      ),
    );
  }
}
