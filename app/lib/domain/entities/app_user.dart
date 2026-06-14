import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_type.dart';

/// The public user profile (mirror of `users/{uid}`). Server-only fields
/// (`verified`, `premium`, `role`, counters) are read here but never written
/// from the client — see firestore.rules.
class AppUser {
  const AppUser({
    required this.uid,
    required this.handle,
    required this.displayName,
    this.bio = '',
    this.photoUrl = '',
    this.coverUrl = '',
    this.accountType = AccountType.personal,
    this.industry = '',
    this.verified = false,
    this.premium = false,
    this.role = 'user',
    this.onboardingComplete = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.notifPrefs = const {},
  });

  final String uid;
  final String handle;
  final String displayName;
  final String bio;
  final String photoUrl;
  final String coverUrl;
  final AccountType accountType;
  final String industry;
  final bool verified;
  final bool premium;
  final String role;
  final bool onboardingComplete;
  final int followerCount;
  final int followingCount;
  final int postCount;

  /// Per-type push preferences (like/comment/follow/mention/message).
  /// A missing entry means enabled.
  final Map<String, bool> notifPrefs;

  /// Whether push for [type] is on (defaults to true when unset).
  bool notifEnabled(String type) => notifPrefs[type] != false;

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        handle: (m['handle'] ?? '') as String,
        displayName: (m['displayName'] ?? '') as String,
        bio: (m['bio'] ?? '') as String,
        photoUrl: (m['photoUrl'] ?? '') as String,
        coverUrl: (m['coverUrl'] ?? '') as String,
        accountType: AccountType.fromId(m['accountType'] as String?),
        industry: (m['industry'] ?? '') as String,
        verified: (m['verified'] ?? false) as bool,
        premium: (m['premium'] ?? false) as bool,
        role: (m['role'] ?? 'user') as String,
        onboardingComplete: (m['onboardingComplete'] ?? false) as bool,
        followerCount: (m['followerCount'] ?? 0) as int,
        followingCount: (m['followingCount'] ?? 0) as int,
        postCount: (m['postCount'] ?? 0) as int,
        notifPrefs: ((m['notifPrefs'] as Map<String, dynamic>?) ?? const {})
            .map((k, v) => MapEntry(k, v == true)),
      );

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AppUser.fromMap(doc.id, doc.data() ?? const {});
}
