import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../data/repositories/live_repository.dart';
import '../../domain/entities/live_stream.dart';

final liveStreamsProvider = StreamProvider.autoDispose<List<LiveStream>>(
  (ref) => ref.watch(liveRepositoryProvider).watchLive(),
);

final liveStreamProvider =
    StreamProvider.autoDispose.family<LiveStream?, String>(
  (ref, id) => ref.watch(liveRepositoryProvider).watchStream(id),
);

final liveChatProvider =
    StreamProvider.autoDispose.family<List<LiveChat>, String>(
  (ref, id) => ref.watch(liveRepositoryProvider).watchChat(id),
);
