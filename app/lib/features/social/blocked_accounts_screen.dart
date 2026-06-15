import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_providers.dart';
import 'social_providers.dart';

/// View and manage the accounts the current user has blocked.
class BlockedAccountsScreen extends ConsumerWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateChangesProvider).value?.uid;
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: blocked.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text("You haven't blocked anyone."),
              ),
            )
          : ListView(
              children: [for (final id in blocked) _BlockedTile(uid: id, me: me)],
            ),
    );
  }
}

class _BlockedTile extends ConsumerWidget {
  const _BlockedTile({required this.uid, required this.me});
  final String uid;
  final String? me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userByIdProvider(uid)).value;
    return ListTile(
      leading: UserAvatar(
          photoUrl: user?.photoUrl ?? '', name: user?.displayName ?? '?'),
      title: Text(user?.displayName ?? '…'),
      subtitle: user == null ? null : Text('@${user.handle}'),
      trailing: TextButton(
        onPressed: me == null
            ? null
            : () => ref.read(socialRepositoryProvider).unblockUser(me!, uid),
        child: const Text('Unblock'),
      ),
    );
  }
}
