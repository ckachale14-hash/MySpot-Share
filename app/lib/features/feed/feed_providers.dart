import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/post.dart';

typedef PostUser = ({String postId, String uid});

final forYouFeedProvider = StreamProvider.autoDispose<List<Post>>(
  (ref) => ref.watch(postRepositoryProvider).watchForYou(),
);

final postProvider = StreamProvider.autoDispose.family<Post?, String>(
  (ref, id) => ref.watch(postRepositoryProvider).watchPost(id),
);

final commentsProvider =
    StreamProvider.autoDispose.family<List<Comment>, String>(
  (ref, postId) => ref.watch(postRepositoryProvider).watchComments(postId),
);

final likedProvider = StreamProvider.autoDispose.family<bool, PostUser>(
  (ref, a) => ref.watch(postRepositoryProvider).watchLiked(a.postId, a.uid),
);

final savedProvider = StreamProvider.autoDispose.family<bool, PostUser>(
  (ref, a) => ref.watch(postRepositoryProvider).watchSaved(a.postId, a.uid),
);

final userPostsProvider =
    StreamProvider.autoDispose.family<List<Post>, String>(
  (ref, uid) => ref.watch(postRepositoryProvider).watchUserPosts(uid),
);

final savedPostsProvider =
    StreamProvider.autoDispose.family<List<Post>, String>(
  (ref, uid) => ref.watch(postRepositoryProvider).watchSavedPosts(uid),
);
