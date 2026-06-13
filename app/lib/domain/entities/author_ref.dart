/// Denormalized author snapshot stored on posts/comments/stories so feeds render
/// without extra reads.
class AuthorRef {
  const AuthorRef({
    required this.uid,
    this.handle = '',
    this.displayName = '',
    this.photoUrl = '',
    this.verified = false,
  });

  final String uid;
  final String handle;
  final String displayName;
  final String photoUrl;
  final bool verified;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'handle': handle,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'verified': verified,
      };

  factory AuthorRef.fromMap(Map<String, dynamic>? m) {
    final map = m ?? const {};
    return AuthorRef(
      uid: (map['uid'] ?? '') as String,
      handle: (map['handle'] ?? '') as String,
      displayName: (map['displayName'] ?? '') as String,
      photoUrl: (map['photoUrl'] ?? '') as String,
      verified: (map['verified'] ?? false) as bool,
    );
  }
}
