import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/widgets/follow_button.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/verified_badge.dart';
import '../auth/auth_providers.dart';
import '../feed/feed_providers.dart';
import 'social_providers.dart';

/// Public profile for any user (by uid), with their posts and a follow button.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.uid});
  final String uid;

  Future<void> _block(BuildContext context, WidgetRef ref, String me) async {
    await ref.read(socialRepositoryProvider).blockUser(me, uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account blocked.')));
    }
  }

  Future<void> _report(BuildContext context, WidgetRef ref, String me) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in const [
              'Spam',
              'Harassment',
              'Scam or fraud',
              'Impersonation',
              'Other'
            ])
              ListTile(title: Text(r), onTap: () => Navigator.pop(context, r)),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await ref.read(socialRepositoryProvider).reportUser(me, uid, reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reported. Thank you.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final user = ref.watch(userByIdProvider(uid)).value;
    final posts = ref.watch(userPostsProvider(uid)).value ?? const [];
    final me = ref.watch(authStateChangesProvider).value?.uid;
    final isBlocked = ref.watch(blockedIdsProvider).value?.contains(uid) ?? false;
    final isSelf = me == uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.displayName ?? 'Profile'),
        actions: [
          if (!isSelf && me != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'report') _report(context, ref, me);
                if (v == 'block') _block(context, ref, me);
                if (v == 'unblock') {
                  ref.read(socialRepositoryProvider).unblockUser(me, uid);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'report', child: Text('Report')),
                PopupMenuItem(
                    value: isBlocked ? 'unblock' : 'block',
                    child: Text(isBlocked ? 'Unblock' : 'Block')),
              ],
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      UserAvatar(
                          photoUrl: user.photoUrl,
                          name: user.displayName,
                          radius: 40),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                              child: Text(user.displayName,
                                  style: t.textTheme.headlineSmall,
                                  textAlign: TextAlign.center)),
                          if (user.verified)
                            const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: VerifiedBadge()),
                        ],
                      ),
                      Text('@${user.handle}',
                          style: t.textTheme.bodyMedium
                              ?.copyWith(color: t.colorScheme.outline)),
                      const SizedBox(height: 6),
                      Text(user.accountType.label,
                          style: t.textTheme.labelLarge
                              ?.copyWith(color: t.colorScheme.primary)),
                      if (user.bio.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(user.bio, textAlign: TextAlign.center)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat(t, user.postCount, 'Posts'),
                          _stat(t, user.followerCount, 'Followers'),
                          _stat(t, user.followingCount, 'Following'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                          width: 200, child: FollowButton(targetUid: user.uid)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (isBlocked)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                          "You've blocked this account. Unblock from the menu "
                          'to see their posts.',
                          textAlign: TextAlign.center,
                          style: t.textTheme.bodyMedium
                              ?.copyWith(color: t.colorScheme.outline)),
                    ),
                  )
                else if (posts.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No posts yet')))
                else
                  for (final p in posts) PostCard(post: p),
              ],
            ),
    );
  }

  Widget _stat(ThemeData t, int n, String label) => Column(children: [
        Text('$n', style: t.textTheme.titleLarge),
        Text(label, style: t.textTheme.bodySmall),
      ]);
}
