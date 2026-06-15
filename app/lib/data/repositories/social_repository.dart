import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';

/// Follow graph + reading arbitrary user profiles.
class SocialRepository {
  SocialRepository(this._db);
  final FirebaseFirestore _db;

  String _edgeId(String follower, String following) => '${follower}_$following';

  Stream<AppUser?> watchUser(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);

  Stream<bool> watchFollowing(String me, String target) => _db
      .collection('follows')
      .doc(_edgeId(me, target))
      .snapshots()
      .map((d) => d.exists);

  Future<void> setFollowing(String me, String target, bool follow) {
    final ref = _db.collection('follows').doc(_edgeId(me, target));
    return follow
        ? ref.set({
            'followerId': me,
            'followingId': target,
            'createdAt': FieldValue.serverTimestamp(),
          })
        : ref.delete();
  }

  // ---- blocking (private list at users/{uid}/blocks/{blockedUid}) ----
  Stream<Set<String>> watchBlocked(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('blocks')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => d.id).toSet());

  Future<void> blockUser(String me, String target) => _db
      .doc('users/$me/blocks/$target')
      .set({'createdAt': FieldValue.serverTimestamp()});

  Future<void> unblockUser(String me, String target) =>
      _db.doc('users/$me/blocks/$target').delete();

  Future<void> reportUser(String reporterId, String targetUid, String reason) =>
      _db.collection('reports').add({
        'reporterId': reporterId,
        'targetType': 'user',
        'targetId': targetUid,
        'reason': reason,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
}
