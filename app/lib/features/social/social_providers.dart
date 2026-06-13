import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/app_user.dart';

typedef FollowPair = ({String me, String target});

final userByIdProvider = StreamProvider.autoDispose.family<AppUser?, String>(
  (ref, uid) => ref.watch(socialRepositoryProvider).watchUser(uid),
);

final followingProvider = StreamProvider.autoDispose.family<bool, FollowPair>(
  (ref, p) => ref.watch(socialRepositoryProvider).watchFollowing(p.me, p.target),
);
