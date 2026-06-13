import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/follow_button.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/verified_badge.dart';
import '../feed/feed_providers.dart';
import 'social_providers.dart';

/// Public profile for any user (by uid), with their posts and a follow button.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final user = ref.watch(userByIdProvider(uid)).value;
    final posts = ref.watch(userPostsProvider(uid)).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(user?.displayName ?? 'Profile')),
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
                if (posts.isEmpty)
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
