import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/post.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/feed/feed_providers.dart';
import '../di/repositories.dart';

/// Renders a poll: tappable options that fill to show results once the viewer
/// has voted or the poll has closed. Used by the feed card and post detail.
class PollView extends ConsumerWidget {
  const PollView({super.key, required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final poll = post.poll!;
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final myVote = uid == null
        ? null
        : ref.watch(myVoteProvider((postId: post.id, uid: uid))).value;
    final showResults = myVote != null || poll.isClosed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < poll.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PollOption(
              label: poll.options[i],
              fraction: poll.fractionFor(i),
              selected: myVote == i,
              showResults: showResults,
              onTap: (uid == null || poll.isClosed)
                  ? null
                  : () =>
                      ref.read(postRepositoryProvider).setVote(post.id, uid, i),
            ),
          ),
        Text(
          '${poll.totalVotes} vote${poll.totalVotes == 1 ? '' : 's'}'
          '${poll.isClosed ? ' · final results' : ''}',
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.outline),
        ),
      ],
    );
  }
}

class _PollOption extends StatelessWidget {
  const _PollOption({
    required this.label,
    required this.fraction,
    required this.selected,
    required this.showResults,
    this.onTap,
  });

  final String label;
  final double fraction;
  final bool selected;
  final bool showResults;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pct = (fraction * 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: selected
                  ? t.colorScheme.primary
                  : t.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (showResults)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: ColoredBox(
                      color: (selected
                              ? t.colorScheme.primary
                              : t.colorScheme.primaryContainer)
                          .withValues(alpha: 0.25)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (selected) ...[
                    Icon(Icons.check_circle,
                        size: 18, color: t.colorScheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                      child: Text(label,
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (showResults) Text('$pct%', style: t.textTheme.labelLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
