import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/repositories.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/user_avatar.dart';
import '../../domain/entities/app_notification.dart';
import '../auth/auth_providers.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid != null) {
        ref.read(notificationRepositoryProvider).markAllRead(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final items =
        uid == null ? <AppNotification>[] : ref.watch(notificationsProvider(uid)).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = items[i];
                return ListTile(
                  leading: UserAvatar(
                      photoUrl: n.actor.photoUrl, name: n.actor.displayName),
                  title: Text(_describe(n)),
                  subtitle: n.text != null ? Text(n.text!) : null,
                  trailing: Text(timeAgo(n.createdAt),
                      style: Theme.of(context).textTheme.bodySmall),
                  onTap: () {
                    if (n.postId != null) {
                      context.push('/post/${n.postId}');
                    } else {
                      context.push('/u/${n.actor.uid}');
                    }
                  },
                );
              },
            ),
    );
  }

  String _describe(AppNotification n) {
    final name = n.actor.displayName.isNotEmpty
        ? n.actor.displayName
        : '@${n.actor.handle}';
    switch (n.type) {
      case 'like':
        return '$name liked your post';
      case 'comment':
        return '$name commented on your post';
      case 'follow':
        return '$name started following you';
      case 'mention':
        return '$name mentioned you';
      default:
        return name;
    }
  }
}
