import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../profile/user_providers.dart';
import 'live_providers.dart';

/// Live chat overlay used by both host and viewer screens.
class LiveChatPanel extends ConsumerStatefulWidget {
  const LiveChatPanel({super.key, required this.streamId});
  final String streamId;

  @override
  ConsumerState<LiveChatPanel> createState() => _LiveChatPanelState();
}

class _LiveChatPanelState extends ConsumerState<LiveChatPanel> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sender = ref.read(currentAuthorRefProvider);
    final text = _text.text.trim();
    if (sender == null || text.isEmpty) return;
    _text.clear();
    await ref.read(liveRepositoryProvider).sendChat(widget.streamId, sender, text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(liveChatProvider(widget.streamId)).value ?? const [];
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: chat.length,
            itemBuilder: (_, i) {
              final m = chat[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    children: [
                      TextSpan(
                          text: '${m.senderName}  ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: m.text),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Say something…',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white24,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
