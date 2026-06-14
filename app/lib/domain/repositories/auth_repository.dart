import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(String email, String password);
  Future<void> signInWithGoogle();

  /// Sign in with Apple (native sheet on iOS, popup on web/Android web flow).
  Future<void> signInWithApple();

  /// Begin phone verification for [phoneNumber] (E.164, e.g. +254712345678).
  /// On Android the SMS may auto-resolve — [onAutoVerified] then fires and
  /// sign-in completes without a code. Otherwise [codeSent] yields a
  /// verificationId to pass to [confirmPhoneCode]; [onError] reports failures.
  Future<void> startPhoneSignIn({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(String message) onError,
    void Function()? onAutoVerified,
  });

  /// Complete phone sign-in with the SMS [smsCode] for [verificationId].
  Future<void> confirmPhoneCode(String verificationId, String smsCode);

  /// Permanently delete the signed-in account. May throw
  /// `requires-recent-login` if the session is too old to delete.
  Future<void> deleteAccount();

  Future<void> signOut();
}
