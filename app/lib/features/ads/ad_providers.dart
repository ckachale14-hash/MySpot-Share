import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../domain/entities/ad_campaign.dart';

final myCampaignsProvider =
    StreamProvider.autoDispose.family<List<AdCampaign>, String>(
  (ref, uid) => ref.watch(adRepositoryProvider).watchMyCampaigns(uid),
);

final adReviewQueueProvider = StreamProvider.autoDispose<List<AdCampaign>>(
  (ref) => ref.watch(adRepositoryProvider).watchReviewQueue(),
);
