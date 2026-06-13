import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/user_avatar.dart';
import '../../domain/entities/author_ref.dart';
import 'story_providers.dart';

/// Horizontal rail of authors with active (24h) stories, led by "Your story".
class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(activeStoriesProvider).value ?? const [];

    // Unique authors, preserving recency order.
    final seen = <String>{};
    final authors = <AuthorRef>[];
    for (final s in stories) {
      if (seen.add(s.authorId)) authors.add(s.author);
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Bubble(
            label: 'Your story',
            child: const _AddRing(),
            onTap: () => context.push('/story/compose'),
          ),
          for (final a in authors)
            _Bubble(
              label: a.displayName.isEmpty ? a.handle : a.displayName,
              onTap: () => context.push('/story/${a.uid}'),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF3D5AFE), Color(0xFFFF6D00)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: UserAvatar(
                      photoUrl: a.photoUrl, name: a.displayName, radius: 28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, required this.child, required this.onTap});
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            child,
            const SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AddRing extends StatelessWidget {
  const _AddRing();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 32,
      backgroundColor: scheme.primaryContainer,
      child: Icon(Icons.add, color: scheme.onPrimaryContainer),
    );
  }
}
