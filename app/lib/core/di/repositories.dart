import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ad_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/ai_video_repository.dart';
import '../../data/repositories/billing_repository.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/discovery_repository.dart';
import '../../data/repositories/live_repository.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/media_service.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/presence_service.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../data/repositories/verification_repository.dart';
import '../firebase/firebase_providers.dart';

final postRepositoryProvider =
    Provider<PostRepository>((ref) => PostRepository(ref.watch(firestoreProvider)));

final socialRepositoryProvider =
    Provider<SocialRepository>((ref) => SocialRepository(ref.watch(firestoreProvider)));

final storyRepositoryProvider =
    Provider<StoryRepository>((ref) => StoryRepository(ref.watch(firestoreProvider)));

final journeyRepositoryProvider =
    Provider<JourneyRepository>((ref) => JourneyRepository(ref.watch(firestoreProvider)));

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
    (ref) => DiscoveryRepository(ref.watch(firestoreProvider)));

final notificationRepositoryProvider = Provider<NotificationRepository>(
    (ref) => NotificationRepository(ref.watch(firestoreProvider)));

final mediaServiceProvider =
    Provider<MediaService>((ref) => MediaService(ref.watch(storageProvider)));

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
    ref.watch(functionsProvider),
  ),
);

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(ref.watch(firestoreProvider)),
);

final presenceServiceProvider =
    Provider<PresenceService>((ref) => PresenceService(ref.watch(databaseProvider)));

final liveRepositoryProvider = Provider<LiveRepository>(
  (ref) => LiveRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final adRepositoryProvider = Provider<AdRepository>(
  (ref) => AdRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(firestoreProvider)),
);

final aiVideoRepositoryProvider = Provider<AiVideoRepository>(
  (ref) => AiVideoRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);
