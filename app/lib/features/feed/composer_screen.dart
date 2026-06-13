import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/firebase/firebase_providers.dart';
import '../../data/repositories/post_repository.dart';
import '../../domain/entities/media_item.dart';
import '../../domain/entities/post.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';

class ComposerScreen extends ConsumerStatefulWidget {
  const ComposerScreen({super.key});

  @override
  ConsumerState<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends ConsumerState<ComposerScreen> {
  final _text = TextEditingController();
  MediaItem? _image;
  String _visibility = 'public';
  bool _busy = false;
  bool _aiBusy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final item = await ref.read(mediaServiceProvider).pickAndUploadImage(uid: uid);
      if (item != null) setState(() => _image = item);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _improveWithAi() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _aiBusy = true);
    try {
      final res = await ref
          .read(functionsProvider)
          .httpsCallable('aiAssist')
          .call({'task': 'improve', 'text': _text.text.trim()});
      final improved = (res.data as Map)['text'] as String?;
      if (improved != null && improved.isNotEmpty) _text.text = improved;
    } catch (e) {
      _toast('AI assist unavailable: $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  Future<void> _post() async {
    final author = ref.read(currentAuthorRefProvider);
    if (author == null) return;
    final text = _text.text.trim();
    if (text.isEmpty && _image == null) return;

    setState(() => _busy = true);
    try {
      final entities = parseEntities(text);
      await ref.read(postRepositoryProvider).createPost(
            author: author,
            type: _image != null ? PostType.image : PostType.text,
            text: text,
            media: _image != null ? [_image!] : const [],
            hashtags: entities.hashtags,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _busy ? null : _post,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Share an update, a lesson, a win… use #hashtags',
              border: InputBorder.none,
            ),
          ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: _image!.url),
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 18)),
                    onPressed: () => setState(() => _image = null),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _busy ? null : _addImage,
                icon: const Icon(Icons.image_outlined),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _aiBusy ? null : _improveWithAi,
                icon: _aiBusy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Improve with AI'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'public', label: Text('Public'), icon: Icon(Icons.public)),
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
