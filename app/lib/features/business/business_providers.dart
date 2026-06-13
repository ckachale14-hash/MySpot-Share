import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/business.dart';

final directoryProvider =
    StreamProvider.autoDispose.family<List<Business>, String>(
  (ref, category) =>
      ref.watch(businessRepositoryProvider).watchByCategory(category),
);

final businessProvider =
    StreamProvider.autoDispose.family<Business?, String>(
  (ref, id) => ref.watch(businessRepositoryProvider).watchBusiness(id),
);

final businessReviewsProvider =
    StreamProvider.autoDispose.family<List<BusinessReview>, String>(
  (ref, id) => ref.watch(businessRepositoryProvider).watchReviews(id),
);
