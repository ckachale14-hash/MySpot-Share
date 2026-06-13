import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';

const _bgColors = <int>[
  0xFF3D5AFE, 0xFFFF6D00, 0xFF00BFA5, 0xFFD500F9, 0xFFC51162, 0xFF2E7D32,
];

class StoryComposerScreen extends ConsumerStatefulWidget {
  const StoryComposerScreen({super.key});

  @override
  ConsumerState<StoryComposerScreen> createState() => _StoryComposerScreenState();
}

class _StoryComposerScreenState extends ConsumerState<StoryComposerScreen> {
  final _text = TextEditingController();
  int _bg = _bgColors.first;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _postText() async {
    final author = ref.read(currentAuthorRefProvider);
    if (author == null || _text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(storyRepositoryProvider).createTextStory(
            author: author,
            text: _text.text.trim(),
            bgColor: _bg,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _postImage() async {
    final author = ref.read(currentAuthorRefProvider);
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (author == null || uid == null) return;
    setState(() => _busy = true);
    try {
      final item = await ref
          .read(mediaServiceProvider)
          .pickAndUploadImage(uid: uid, category: 'stories');
      if (item != null) {
        await ref
            .read(storyRepositoryProvider)
            .createImageStory(author: author, mediaUrl: item.url);
        if (mounted) Navigator.of(context).pop();
      }
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
        title: const Text('New story'),
        actions: [
          IconButton(
            tooltip: 'Image story',
            onPressed: _busy ? null : _postImage,
            icon: const Icon(Icons.image_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _busy ? null : _postText,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Share'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Color(_bg),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: TextField(
                controller: _text,
                textAlign: TextAlign.center,
                maxLines: null,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type a status…',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in _bgColors)
                  GestureDetector(
                    onTap: () => setState(() => _bg = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _bg == c ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
