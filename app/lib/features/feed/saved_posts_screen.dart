import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/post_card.dart';
import '../../domain/entities/post.dart';
import '../auth/auth_providers.dart';
import 'feed_providers.dart';

/// The current user's bookmarked posts (private to them).
class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: uid == null
          ? const Center(child: Text('Sign in to see saved posts.'))
          : AsyncValueWidget<List<Post>>(
              value: ref.watch(savedPostsProvider(uid)),
              data: (posts) {
                if (posts.isEmpty) {
                  return const _Empty();
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [for (final p in posts) PostCard(post: p)],
                );
              },
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border,
                size: 48, color: t.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No saved posts yet',
                style: t.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Tap the bookmark on any post to keep it here.',
                style: t.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
