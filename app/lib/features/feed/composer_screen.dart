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
  bool _aiImgBusy = false;

  bool _pollMode = false;
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _text.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length >= 4) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_options.length <= 2) return;
    setState(() => _options.removeAt(i).dispose());
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

  Future<void> _generateImage() async {
    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Generate an image'),
          content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'e.g. a vibrant market stall, warm lighting'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, c.text.trim()),
                child: const Text('Generate')),
          ],
        );
      },
    );
    if (prompt == null || prompt.isEmpty) return;
    setState(() => _aiImgBusy = true);
    try {
      final res = await ref
          .read(functionsProvider)
          .httpsCallable('generateImage')
          .call({'prompt': prompt});
      final url = (res.data as Map)['url'] as String?;
      if (url != null && url.isNotEmpty) {
        setState(() => _image = MediaItem(url: url, type: 'image'));
      }
    } catch (e) {
      _toast('Image generation unavailable: $e');
    } finally {
      if (mounted) setState(() => _aiImgBusy = false);
    }
  }

  Future<void> _post() async {
    final author = ref.read(currentAuthorRefProvider);
    if (author == null) return;
    final text = _text.text.trim();

    if (_pollMode) {
      final options = _options
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (text.isEmpty || options.length < 2) {
        _toast('Add a question and at least two options.');
        return;
      }
      setState(() => _busy = true);
      try {
        await ref.read(postRepositoryProvider).createPoll(
              author: author,
              question: text,
              options: options,
              visibility: _visibility,
            );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        _toast('$e');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

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
            minLines: _pollMode ? 1 : 4,
            maxLines: _pollMode ? 3 : 12,
            decoration: InputDecoration(
              hintText: _pollMode
                  ? 'Ask a question…'
                  : 'Share an update, a lesson, a win… use #hashtags',
              border: InputBorder.none,
            ),
          ),
          if (!_pollMode && _image != null)
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
          if (_pollMode) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: _options[i],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Option ${i + 1}',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _options.length > 2
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _removeOption(i),
                          )
                        : null,
                  ),
                ),
              ),
            if (_options.length < 4)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add option'),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!_pollMode)
                IconButton.filledTonal(
                  onPressed: _busy ? null : _addImage,
                  icon: const Icon(Icons.image_outlined),
                ),
              IconButton.filledTonal(
                isSelected: _pollMode,
                tooltip: _pollMode ? 'Remove poll' : 'Create poll',
                onPressed: _busy
                    ? null
                    : () => setState(() => _pollMode = !_pollMode),
                icon: const Icon(Icons.poll_outlined),
              ),
              if (!_pollMode) ...[
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
                OutlinedButton.icon(
                  onPressed: _aiImgBusy ? null : _generateImage,
                  icon: _aiImgBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_motion, size: 18),
                  label: const Text('AI image'),
                ),
              ],
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
