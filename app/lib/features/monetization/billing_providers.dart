import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/verification_request.dart';

final myVerificationProvider =
    StreamProvider.autoDispose.family<VerificationRequest?, String>(
  (ref, uid) => ref.watch(verificationRepositoryProvider).watchMyLatest(uid),
);

final subscriptionProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, uid) => ref.watch(billingRepositoryProvider).watchSubscription(uid),
);

final reviewQueueProvider =
    StreamProvider.autoDispose<List<VerificationRequest>>(
  (ref) => ref.watch(adminRepositoryProvider).watchReviewQueue(),
);
