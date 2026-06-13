import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

final conversationsProvider =
    StreamProvider.autoDispose.family<List<Conversation>, String>(
  (ref, uid) => ref.watch(conversationRepositoryProvider).watchConversations(uid),
);

final conversationProvider =
    StreamProvider.autoDispose.family<Conversation?, String>(
  (ref, cid) => ref.watch(conversationRepositoryProvider).watchConversation(cid),
);

final messagesProvider =
    StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, cid) => ref.watch(conversationRepositoryProvider).watchMessages(cid),
);

final onlineProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, uid) => ref.watch(presenceServiceProvider).watchOnline(uid),
);
