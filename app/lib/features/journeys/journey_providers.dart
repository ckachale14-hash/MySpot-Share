import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/founder_journey.dart';

final journeyByIdProvider =
    StreamProvider.autoDispose.family<FounderJourney?, String>(
  (ref, id) => ref.watch(journeyRepositoryProvider).watchById(id),
);
