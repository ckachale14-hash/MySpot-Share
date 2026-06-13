import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/message.dart';
import '../auth/auth_providers.dart';
import '../profile/user_providers.dart';
import 'messaging_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.cid});
  final String cid;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _marked = <String>{};
  bool _zeroed = false;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _maybeMarkRead(String uid, List<Message> messages) {
    final ids = messages
        .where((m) =>
            m.senderId != uid &&
            !m.readBy.contains(uid) &&
            !_marked.contains(m.id))
        .map((m) => m.id)
        .toList();
    if (ids.isEmpty && _zeroed) return;
    _marked.addAll(ids);
    _zeroed = true;
    ref.read(conversationRepositoryProvider).markRead(widget.cid, uid, ids);
  }

  Future<void> _sendText() async {
    final sender = ref.read(currentAuthorRefProvider);
    final text = _text.text.trim();
    if (sender == null || text.isEmpty) return;
    _text.clear();
    await ref.read(conversationRepositoryProvider).sendText(widget.cid, sender, text);
  }

  Future<void> _sendImage() async {
    final sender = ref.read(currentAuthorRefProvider);
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (sender == null || uid == null) return;
    setState(() => _busy = true);
    try {
      final item = await ref
          .read(mediaServiceProvider)
          .pickAndUploadImage(uid: uid, category: 'chat');
      if (item != null) {
        await ref
            .read(conversationRepositoryProvider)
            .sendImage(widget.cid, sender, item.url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid ?? '';
    final conv = ref.watch(conversationProvider(widget.cid)).value;
    final messages = ref.watch(messagesProvider(widget.cid)).value ?? const [];
    final other = conv?.other(uid);
    final online =
        other == null ? false : ref.watch(onlineProvider(other.uid)).value ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && uid.isNotEmpty) _maybeMarkRead(uid, messages);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(other?.displayName ?? 'Chat', style: t.textTheme.titleMedium),
            Text(online ? 'Online' : 'Offline',
                style: t.textTheme.bodySmall?.copyWith(
                    color: online ? Colors.green : t.colorScheme.outline)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text('Say hello 👋', style: t.textTheme.bodyMedium))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) =>
                        _Bubble(message: messages[i], mine: messages[i].senderId == uid),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _busy ? null : _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      decoration: const InputDecoration(hintText: 'Message…'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : _sendText,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimary : scheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: message.type == 'image'
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: message.type == 'image' && message.mediaUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: message.mediaUrl),
              )
            : Text(message.text, style: TextStyle(color: fg)),
      ),
    );
  }
}
