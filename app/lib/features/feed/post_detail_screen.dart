import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/poll_view.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/verified_badge.dart';
import '../../domain/entities/post.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';
import '../social/social_providers.dart';
import 'feed_providers.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final author = ref.read(currentAuthorRefProvider);
    final text = _comment.text.trim();
    if (author == null || text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(postRepositoryProvider).addComment(widget.postId, author, text);
      _comment.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final post = ref.watch(postProvider(widget.postId)).value;
    final blocked = ref.watch(blockedIdsProvider).value ?? const <String>{};
    final allComments =
        ref.watch(commentsProvider(widget.postId)).value ?? const [];
    final comments = blocked.isEmpty
        ? allComments
        : allComments.where((c) => !blocked.contains(c.authorId)).toList();
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final repo = ref.read(postRepositoryProvider);
    final liked = uid == null
        ? false
        : ref.watch(likedProvider((postId: widget.postId, uid: uid))).value ?? false;
    final saved = uid == null
        ? false
        : ref.watch(savedProvider((postId: widget.postId, uid: uid))).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: post == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/u/${post.authorId}'),
                            child: UserAvatar(
                                photoUrl: post.author.photoUrl,
                                name: post.author.displayName),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Flexible(
                                      child: Text(post.author.displayName,
                                          style: t.textTheme.titleSmall)),
                                  if (post.author.verified)
                                    const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: VerifiedBadge(size: 14)),
                                ]),
                                Text(
                                    '@${post.author.handle} · ${timeAgo(post.createdAt)}',
                                    style: t.textTheme.bodySmall?.copyWith(
                                        color: t.colorScheme.outline)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (post.type == PostType.article &&
                          post.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(post.title,
                              style: t.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      if (post.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(post.text, style: t.textTheme.bodyLarge),
                        ),
                      if (post.type == PostType.poll && post.poll != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PollView(post: post),
                        ),
                      if (post.media.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                                imageUrl: post.media.first.url,
                                fit: BoxFit.cover),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.redAccent : null),
                            onPressed: uid == null
                                ? null
                                : () => repo.setLiked(post.id, uid, !liked),
                          ),
                          Text('${post.likeCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.mode_comment_outlined, size: 20),
                          const SizedBox(width: 4),
                          Text('${post.commentCount}'),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                                saved ? Icons.bookmark : Icons.bookmark_border),
                            onPressed: uid == null
                                ? null
                                : () => repo.setSaved(post.id, uid, !saved),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Comments', style: t.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: Text('Be the first to comment',
                                  style: t.textTheme.bodyMedium)),
                        ),
                      for (final c in comments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(
                              photoUrl: c.author.photoUrl,
                              name: c.author.displayName,
                              radius: 16),
                          title: Text(c.author.displayName,
                              style: t.textTheme.titleSmall),
                          subtitle: Text(c.text),
                          trailing: Text(timeAgo(c.createdAt),
                              style: t.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _comment,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText: 'Add a comment…'),
                          ),
                        ),
                        IconButton(
                          icon: _sending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send),
                          onPressed: _sending ? null : _send,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
