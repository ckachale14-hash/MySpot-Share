/// Minimal authenticated-identity value object (decouples the app from the
/// Firebase `User` type at the domain boundary).
class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}
