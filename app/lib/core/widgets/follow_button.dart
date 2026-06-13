import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/repositories.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/social/social_providers.dart';

/// Follow / Following toggle for a target user. Hidden for self & signed-out.
class FollowButton extends ConsumerWidget {
  const FollowButton({super.key, required this.targetUid, this.compact = false});

  final String targetUid;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateChangesProvider).value?.uid;
    if (me == null || me == targetUid) return const SizedBox.shrink();

    final following =
        ref.watch(followingProvider((me: me, target: targetUid))).value ?? false;
    final repo = ref.read(socialRepositoryProvider);

    onPressed() => repo.setFollowing(me, targetUid, !following);

    if (following) {
      return OutlinedButton(
        onPressed: onPressed,
        style: compact
            ? OutlinedButton.styleFrom(minimumSize: const Size(0, 36))
            : null,
        child: const Text('Following'),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: compact ? FilledButton.styleFrom(minimumSize: const Size(0, 36)) : null,
      child: const Text('Follow'),
    );
  }
}
