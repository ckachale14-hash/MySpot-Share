import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../data/repositories/discovery_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/founder_journey.dart';

final newUsersProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(discoveryRepositoryProvider).newUsers(),
);

final peopleYouMayKnowProvider =
    StreamProvider.autoDispose.family<List<AppUser>, String>(
  (ref, industry) =>
      ref.watch(discoveryRepositoryProvider).peopleYouMayKnow(industry),
);

final trendingProvider = StreamProvider.autoDispose<List<TrendingTag>>(
  (ref) => ref.watch(discoveryRepositoryProvider).trending(),
);

final recentJourneysProvider = StreamProvider.autoDispose<List<FounderJourney>>(
  (ref) => ref.watch(journeyRepositoryProvider).watchRecent(),
);

final searchPeopleProvider =
    FutureProvider.autoDispose.family<List<AppUser>, String>(
  (ref, query) => ref.watch(discoveryRepositoryProvider).searchPeople(query),
);
