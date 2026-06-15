import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/post.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';

/// Long-form article composer: a headline, a rich body, and an optional cover.
class ArticleEditorScreen extends ConsumerStatefulWidget {
  const ArticleEditorScreen({super.key});

  @override
  ConsumerState<ArticleEditorScreen> createState() =>
      _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends ConsumerState<ArticleEditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  MediaItem? _cover;
  String _visibility = 'public';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _addCover() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final item = await ref
          .read(mediaServiceProvider)
          .pickAndUploadImage(uid: uid, category: 'article');
      if (item != null) setState(() => _cover = item);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    final author = ref.read(currentAuthorRefProvider);
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (author == null) return;
    if (title.isEmpty || body.isEmpty) {
      _toast('Add a title and some body text.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(postRepositoryProvider).createPost(
            author: author,
            type: PostType.article,
            title: title,
            text: body,
            media: _cover != null ? [_cover!] : const [],
            hashtags: parseEntities(body).hashtags,
            visibility: _visibility,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write an article'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _busy ? null : _publish,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publish'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_cover != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: _cover!.url),
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 18)),
                    onPressed: () => setState(() => _cover = null),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'Article title',
              border: InputBorder.none,
              counterText: '',
            ),
          ),
          TextField(
            controller: _body,
            minLines: 10,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Write your article… use #hashtags to add topics.',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _addCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(_cover == null ? 'Add cover image' : 'Replace cover'),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'public', label: Text('Public'), icon: Icon(Icons.public)),
              ButtonSegment(
                  value: 'followers',
                  label: Text('Followers'),
                  icon: Icon(Icons.group_outlined)),
            ],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
          ),
        ],
      ),
    );
  }
}
