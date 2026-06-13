import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_providers.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/author_ref.dart';
import '../../domain/repositories/user_repository.dart';
import '../auth/auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => FirestoreUserRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  ),
);

/// The current signed-in user's profile, or null when signed out.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateChangesProvider).value;
  if (auth == null) return Stream<AppUser?>.value(null);
  return ref.watch(userRepositoryProvider).watchUser(auth.uid);
});

/// Denormalized author snapshot for the current user (for authoring content).
final currentAuthorRefProvider = Provider<AuthorRef?>((ref) {
  final user = ref.watch(appUserProvider).value;
  if (user == null) return null;
  return AuthorRef(
    uid: user.uid,
    handle: user.handle,
    displayName: user.displayName,
    photoUrl: user.photoUrl,
    verified: user.verified,
  );
});
