import '../entities/account_type.dart';
import '../entities/app_user.dart';

abstract interface class UserRepository {
  Stream<AppUser?> watchUser(String uid);

  /// Reserve a unique @handle via the `claimHandle` callable (server-enforced).
  Future<String> claimHandle(String handle);

  /// Persist profile fields and flip `onboardingComplete` to true.
  Future<void> completeOnboarding({
    required String uid,
    required String displayName,
    required AccountType accountType,
    required String industry,
    String bio,
  });

  /// Edit profile fields (server-only fields are rejected by rules).
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required AccountType accountType,
    required String industry,
    String bio,
    String photoUrl,
  });
}
