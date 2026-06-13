import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/discovery_repository.dart';
import '../../data/repositories/journey_repository.dart';
import '../../data/repositories/media_service.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/story_repository.dart';
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
