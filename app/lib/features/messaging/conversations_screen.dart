import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/time_ago.dart';
import '../../core/widgets/user_avatar.dart';
import '../../domain/entities/author_ref.dart';
import '../auth/auth_providers.dart';
import 'messaging_providers.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final convos =
        uid == null ? const [] : ref.watch(conversationsProvider(uid)).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            tooltip: 'New message',
            onPressed: () => context.push('/messages/new'),
          ),
        ],
      ),
      body: uid == null
          ? const SizedBox.shrink()
          : convos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 56, color: t.colorScheme.primary),
                        const SizedBox(height: 12),
                        const Text('No conversations yet',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('Tap the compose icon to message an entrepreneur.',
                            textAlign: TextAlign.center,
                            style: t.textTheme.bodySmall),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: convos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final c = convos[i];
                    final AuthorRef other =
                        c.other(uid) ?? const AuthorRef(uid: '', displayName: 'Unknown');
                    final unread = c.unreadFor(uid);
                    final preview = c.lastMessage?.text ?? '';
                    return ListTile(
                      onTap: () => context.push('/chat/${c.id}'),
                      leading: UserAvatar(
                          photoUrl: other.photoUrl, name: other.displayName),
                      title: Text(
                        other.displayName.isEmpty ? '@${other.handle}' : other.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight:
                                unread > 0 ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text(preview,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(timeAgo(c.updatedAt), style: t.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          if (unread > 0)
                            Badge(label: Text('$unread'))
                          else
                            const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
