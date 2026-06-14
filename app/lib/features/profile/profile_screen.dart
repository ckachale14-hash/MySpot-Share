import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/verified_badge.dart';
import '../feed/feed_providers.dart';
import 'user_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: AsyncValueWidget<dynamic>(
        value: userAsync,
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: t.colorScheme.primaryContainer,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: t.textTheme.headlineMedium)
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(user.displayName,
                        style: t.textTheme.headlineSmall,
                        textAlign: TextAlign.center),
                  ),
                  if (user.verified)
                    const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: VerifiedBadge()),
                ],
              ),
              Text('@${user.handle}',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(color: t.colorScheme.outline)),
              const SizedBox(height: 8),
              Text(user.accountType.label,
                  textAlign: TextAlign.center,
                  style: t.textTheme.labelLarge
                      ?.copyWith(color: t.colorScheme.primary)),
              if (user.industry.isNotEmpty)
                Text(user.industry,
                    textAlign: TextAlign.center, style: t.textTheme.bodySmall),
              if (user.bio.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child:
                        Text(user.bio, textAlign: TextAlign.center)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat(t, user.postCount, 'Posts'),
                  _stat(t, user.followerCount, 'Followers'),
                  _stat(t, user.followingCount, 'Following'),
                ],
              ),
              const SizedBox(height: 24),
              if (!user.verified)
                OutlinedButton.icon(
                    onPressed: () => context.push('/verify'),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Get verified')),
              if (!user.premium)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonalIcon(
                      onPressed: () => context.push('/premium'),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Go Premium')),
                ),
              if (user.role == 'admin' || user.role == 'moderator') ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                      onPressed: () => context.push('/admin/verifications'),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin · Verification queue')),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                      onPressed: () => context.push('/admin/ads'),
                      icon: const Icon(Icons.campaign_outlined),
                      label: const Text('Admin · Ad review')),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                      onPressed: () => context.push('/admin/reports'),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Admin · Reports')),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                    onPressed: () => context.push('/saved'),
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Saved posts')),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                    onPressed: () => context.push('/invite'),
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('Invite friends')),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('My posts', style: t.textTheme.titleMedium),
              ),
              _MyPosts(uid: user.uid as String),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(ThemeData t, int n, String label) => Column(
        children: [
          Text('$n', style: t.textTheme.titleLarge),
          Text(label, style: t.textTheme.bodySmall),
        ],
      );
}

class _MyPosts extends ConsumerWidget {
  const _MyPosts({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider(uid)).value ?? const [];
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text("You haven't posted yet."),
      );
    }
    return Column(children: [for (final p in posts) PostCard(post: p)]);
  }
}
