import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/verified_badge.dart';
import '../auth/auth_providers.dart';
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
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
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
                    onPressed: null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Get verified (P2)')),
              if (!user.premium)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonalIcon(
                      onPressed: null,
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Go Premium (P2)')),
                ),
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
