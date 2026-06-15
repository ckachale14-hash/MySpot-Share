import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/app_user.dart';
import '../auth/auth_providers.dart';

typedef FollowPair = ({String me, String target});

final userByIdProvider = StreamProvider.autoDispose.family<AppUser?, String>(
  (ref, uid) => ref.watch(socialRepositoryProvider).watchUser(uid),
);

final followingProvider = StreamProvider.autoDispose.family<bool, FollowPair>(
  (ref, p) => ref.watch(socialRepositoryProvider).watchFollowing(p.me, p.target),
);

/// The current user's set of blocked uids (empty when signed out). Used to hide
/// blocked authors' posts/comments and to drive block/unblock toggles.
final blockedIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(socialRepositoryProvider).watchBlocked(uid);
});
