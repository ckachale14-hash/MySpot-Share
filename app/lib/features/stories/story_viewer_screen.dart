import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/story.dart';
import '../auth/auth_providers.dart';
import '../../core/di/repositories.dart';
import 'story_providers.dart';

/// Tap-through viewer for one author's active stories.
class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.authorId});
  final String authorId;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  final _recorded = <String>{};
  int _index = 0;

  void _recordView(Story s) {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid != null && uid != s.authorId) {
      ref.read(storyRepositoryProvider).recordView(s.id, uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesByAuthorProvider(widget.authorId)).value ?? const [];

    if (stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Text('No active stories',
                style: TextStyle(color: Colors.white))),
      );
    }

    final story = stories[_index.clamp(0, stories.length - 1)];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _recorded.add(story.id)) _recordView(story);
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.globalPosition.dx < w / 3) {
            if (_index > 0) setState(() => _index--);
          } else {
            if (_index < stories.length - 1) {
              setState(() => _index++);
            } else {
              Navigator.of(context).maybePop();
            }
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _StoryBody(story: story)),
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    for (var i = 0; i < stories.length; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _index ? Colors.white : Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 12,
                child: Text(story.author.displayName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Positioned(
                top: 8,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    if (story.type == 'image' && story.mediaUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: story.mediaUrl, fit: BoxFit.contain);
    }
    return Container(
      color: Color(story.bgColor),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Text(
        story.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
      ),
    );
  }
}
