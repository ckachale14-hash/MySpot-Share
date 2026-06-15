import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';
import 'user_providers.dart';

/// Notification preferences and account management.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Push notification categories → backend notification `type`.
  static const _types = <({String key, String label, IconData icon})>[
    (key: 'message', label: 'Direct messages', icon: Icons.chat_bubble_outline),
    (key: 'like', label: 'Likes', icon: Icons.favorite_border),
    (key: 'comment', label: 'Comments', icon: Icons.mode_comment_outlined),
    (key: 'follow', label: 'New followers', icon: Icons.person_add_alt_outlined),
    (key: 'mention', label: 'Mentions', icon: Icons.alternate_email),
  ];

  final _prefs = <String, bool>{};
  bool _loaded = false;
  bool _deleting = false;

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _setPref(String key, bool value) async {
    setState(() => _prefs[key] = value);
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateNotifPrefs(uid, Map<String, bool>.from(_prefs));
    } catch (e) {
      _snack('Could not save: $e');
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your profile, posts, journeys, and '
            'businesses. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      // The auth state change routes back to /sign-in automatically.
    } catch (e) {
      if (mounted) setState(() => _deleting = false);
      if ('$e'.contains('requires-recent-login')) {
        _snack('Please sign out and sign in again, then retry deletion.');
      } else {
        _snack('$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    if (!_loaded && user != null) {
      _loaded = true;
      for (final t in _types) {
        _prefs[t.key] = user.notifEnabled(t.key);
      }
    }
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Push notifications',
                style: t.textTheme.titleSmall
                    ?.copyWith(color: t.colorScheme.primary)),
          ),
          for (final type in _types)
            SwitchListTile(
              secondary: Icon(type.icon),
              title: Text(type.label),
              value: _prefs[type.key] ?? true,
              onChanged:
                  _loaded ? (v) => _setPref(type.key, v) : null,
            ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text('Account',
                style: t.textTheme.titleSmall
                    ?.copyWith(color: t.colorScheme.primary)),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked accounts'),
            onTap: () => context.push('/settings/blocked'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => ref.read(authRepositoryProvider).signOut(),
          ),
          ListTile(
            leading: _deleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.delete_forever_outlined, color: t.colorScheme.error),
            title: Text('Delete account',
                style: TextStyle(color: t.colorScheme.error)),
            onTap: _deleting ? null : _confirmDelete,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
