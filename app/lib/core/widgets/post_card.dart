import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/post.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/feed/feed_providers.dart';
import '../utils/time_ago.dart';
import 'poll_view.dart';
import 'user_avatar.dart';
import 'verified_badge.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final liked = uid == null
        ? false
        : ref.watch(likedProvider((postId: post.id, uid: uid))).value ?? false;
    final saved = uid == null
        ? false
        : ref.watch(savedProvider((postId: post.id, uid: uid))).value ?? false;
    final repo = ref.read(postRepositoryProvider);

    return InkWell(
      onTap: () => context.push('/post/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/u/${post.authorId}'),
                  child: UserAvatar(
                      photoUrl: post.author.photoUrl, name: post.author.displayName),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(post.author.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.titleSmall),
                        ),
                        if (post.author.verified)
                          const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: VerifiedBadge(size: 14)),
                      ]),
                      Text('@${post.author.handle} · ${timeAgo(post.createdAt)}',
                          style: t.textTheme.bodySmall
                              ?.copyWith(color: t.colorScheme.outline)),
                    ],
                  ),
                ),
                if (post.isSponsored)
                  Chip(
                    label: const Text('Sponsored'),
                    visualDensity: VisualDensity.compact,
                    labelStyle: t.textTheme.labelSmall,
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) async {
                    if (v == 'report' && uid != null) {
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
                                'Inappropriate',
                                'Other'
                              ])
                                ListTile(
                                    title: Text(r),
                                    onTap: () => Navigator.pop(context, r)),
                            ],
                          ),
                        ),
                      );
                      if (reason != null) {
                        await repo.reportPost(post.id, uid, reason);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reported. Thank you.')),
                          );
                        }
                      }
                    } else if (v == 'block' && uid != null) {
                      await ref
                          .read(socialRepositoryProvider)
                          .blockUser(uid, post.authorId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Author blocked.')),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                    if (uid != null && uid != post.authorId)
                      const PopupMenuItem(
                          value: 'block', child: Text('Block author')),
                  ],
                ),
              ],
            ),
            if (post.type == PostType.article)
              _ArticlePreview(post: post)
            else ...[
              if (post.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(post.text, style: t.textTheme.bodyMedium),
                ),
              if (post.type == PostType.poll && post.poll != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: PollView(post: post),
                ),
              if (post.media.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.media.first.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => const AspectRatio(
                          aspectRatio: 1.6,
                          child: ColoredBox(color: Color(0x11000000))),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
            ],
            Row(
              children: [
                _Action(
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.redAccent : null,
                  label: '${post.likeCount}',
                  onTap: uid == null
                      ? null
                      : () => repo.setLiked(post.id, uid, !liked),
                ),
                _Action(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentCount}',
                  onTap: () => context.push('/post/${post.id}'),
                ),
                _Action(
                  icon: Icons.share_outlined,
                  label: '${post.shareCount}',
                  onTap: () => Share.share(
                      '${post.author.displayName} on MySpot: ${post.text}'),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: uid == null
                      ? null
                      : () => repo.setSaved(post.id, uid, !saved),
                ),
              ],
            ),
            Divider(height: 1, color: t.colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

/// Feed preview for an article: cover, headline, snippet, and a read-time label.
class _ArticlePreview extends StatelessWidget {
  const _ArticlePreview({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final words = post.text.trim().isEmpty
        ? 0
        : post.text.trim().split(RegExp(r'\s+')).length;
    final mins = (words / 200).ceil().clamp(1, 99);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.media.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.media.first.url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => const AspectRatio(
                    aspectRatio: 1.8,
                    child: ColoredBox(color: Color(0x11000000))),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(post.title.isEmpty ? 'Untitled article' : post.title,
              style:
                  t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (post.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(post.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.article_outlined,
                  size: 15, color: t.colorScheme.primary),
              const SizedBox(width: 4),
              Text('Article · $mins min read',
                  style: t.textTheme.labelSmall
                      ?.copyWith(color: t.colorScheme.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
