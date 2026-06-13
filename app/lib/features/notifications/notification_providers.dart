import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/app_notification.dart';

final notificationsProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>(
  (ref, uid) => ref.watch(notificationRepositoryProvider).watch(uid),
);

final unreadCountProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, uid) => ref.watch(notificationRepositoryProvider).watchUnreadCount(uid),
);
