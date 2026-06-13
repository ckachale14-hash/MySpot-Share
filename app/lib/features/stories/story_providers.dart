import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/story.dart';

final activeStoriesProvider = StreamProvider.autoDispose<List<Story>>(
  (ref) => ref.watch(storyRepositoryProvider).watchActive(),
);

final storiesByAuthorProvider =
    StreamProvider.autoDispose.family<List<Story>, String>(
  (ref, uid) => ref.watch(storyRepositoryProvider).watchByAuthor(uid),
);
